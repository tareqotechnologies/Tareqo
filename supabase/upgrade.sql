-- ============================================================================
-- upgrade.sql — CONSOLIDADO: leva um banco EXISTENTE ao estado atual
-- ============================================================================
-- Este arquivo substitui as antigas migrações 002..011 por UM único script.
-- A regra é simples:
--
--   * INSTALAÇÃO NOVA  → aplique `supabase/schema.sql` (estado final direto).
--   * BANCO EXISTENTE  → aplique ESTE arquivo (upgrade.sql) no SQL Editor.
--
-- 100% idempotente e reexecutável: pode rodar quantas vezes quiser, em
-- QUALQUER estado (schema base, migrações parciais ou já totalmente
-- migrado) — colunas usam ADD COLUMN IF NOT EXISTS, índices usam CREATE
-- UNIQUE INDEX IF NOT EXISTS, funções usam CREATE OR REPLACE, triggers e
-- políticas usam DROP IF EXISTS + CREATE, e a migração de dinheiro para
-- centavos (W4) tem guarda que só age em colunas NUMERIC legadas.
--
-- ORDEM CRÍTICA (por isso um único arquivo e não vários):
--   1. DDL de colunas/índices/triggers (002/003/008) + helpers RLS (006)
--      + nível gerencial de compras (007) ANTES das RPCs que os usam;
--   2. migração W4 (010) das colunas NUMERIC → BIGINT (centavos inteiros);
--   3. DEPOIS dela, TODAS as RPCs de dinheiro/KPIs são recriadas com as
--      versões FINAIS em centavos (process_sale, register_debt,
--      settle_debt, process_purchase, get_dashboard_kpis, get_cash_flow,
--      get_sales_report). Uma base pré-W4 que mantivesse as versões antigas
--      (que multiplicavam por 100) quebraria com colunas já em centavos.
--
-- Onde rodar: Supabase Dashboard → SQL Editor (a sessão do editor é dona
-- do schema e ignora o RLS — necessário para ALTER TABLE / políticas).
-- ============================================================================


-- ============================================================================
-- PARTE 1 — Preferências do tenant (moeda e idioma)  [migração 002]
-- ============================================================================
ALTER TABLE public.tenants
  -- Moeda padrão dos novos tenants: MZN (metical — mercado-alvo
  -- Moçambique); o dono altera em Lojas → Ajustes. Linhas existentes
  -- preservam o valor que já tinham (ALTER ADD COLUMN com DEFAULT só
  -- vale para linhas novas).
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'MZN',
  ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'pt';

-- CHECKs idempotentes: só criam a constraint se ela ainda não existir.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'tenants_currency_code_check'
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_currency_code_check
      CHECK (currency_code IN ('BRL', 'USD', 'EUR', 'MZN'));
  END IF;

END $$;

-- Idioma (pt/en/fr): DROP + ADD idempotente — recria o CHECK em bancos
-- existentes com a lista oficial dos 3 idiomas (o IF NOT EXISTS acima só
-- criaria o constraint antigo de 2 idiomas numa base já migrada).
ALTER TABLE public.tenants DROP CONSTRAINT IF EXISTS tenants_language_check;
ALTER TABLE public.tenants
  ADD CONSTRAINT tenants_language_check
  CHECK (language IN ('pt', 'en', 'fr'));


-- ============================================================================
-- PARTE 2 — Anti-spam de tenants pendentes (S3) + ator das decisões (S4)
--           [migração 003]
-- ============================================================================
-- Guarda prévia (S3): se existirem duplicados pendentes na base, o CREATE
-- UNIQUE INDEX falharia com erro críptico. Detectamos antes e abortamos
-- com mensagem clara para resolução manual.
DO $$
DECLARE
  dup_owners INTEGER;
BEGIN
  SELECT count(*) INTO dup_owners
  FROM (
    SELECT owner_user_id
    FROM public.tenants
    WHERE status = 'pending'
    GROUP BY owner_user_id
    HAVING count(*) > 1
  ) duplicates;
  IF dup_owners > 0 THEN
    RAISE EXCEPTION
      'S3: % utilizador(es) têm MAIS DE UM tenant pendente. Resolva os duplicados (mantenha o mais antigo e rejeite os restantes) antes de aplicar este script.',
      dup_owners;
  END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_one_pending
  ON public.tenants (owner_user_id) WHERE status = 'pending';

-- S4 — a coluna `decided_by` é carimbada com o auth.uid() do super admin
-- no momento da decisão (pending → approved / rejected), via trigger.
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS decided_by UUID;
ALTER TABLE IF EXISTS public.plan_requests
  ADD COLUMN IF NOT EXISTS decided_by UUID;

CREATE OR REPLACE FUNCTION public.set_decided_by()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Só carimba quando a decisão acontece (pending → approved/rejected) e
  -- há sessão (JWT). Rejeições/aprovações repetidas não sobrescrevem o
  -- primeiro ator.
  IF auth.uid() IS NOT NULL
     AND NEW.status IN ('approved', 'rejected')
     AND OLD.status = 'pending' THEN
    NEW.decided_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tenants_decided_by ON public.tenants;
CREATE TRIGGER trg_tenants_decided_by
  BEFORE UPDATE OF status ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.set_decided_by();

DROP TRIGGER IF EXISTS trg_plan_requests_decided_by ON public.plan_requests;
CREATE TRIGGER trg_plan_requests_decided_by
  BEFORE UPDATE OF status ON public.plan_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_decided_by();


-- ============================================================================
-- PARTE 3 — Helpers RLS com SECURITY DEFINER (correção da regressão 54001)
--           [migração 006]
-- ============================================================================
-- ⚠️ ORDEM CRÍTICA: `is_my_store`/`is_manager_of_store` são LANGUAGE sql — o
-- PostgreSQL VALIDA as colunas no momento do CREATE (diferente do plpgsql,
-- que valida na primeira execução). As funções abaixo referenciam
-- `e.is_active`; sem a coluna, o CREATE falharia com `42703: column
-- e.is_active does not exist`. Por isso a coluna é adicionada AQUI, antes
-- das funções. (A Parte 19 repete o ADD COLUMN IF NOT EXISTS — idempotente
-- — para quem ler a seção de ativação/desativação isoladamente.)

-- 3.0 Coluna is_active no vínculo store_employees (DEFAULT TRUE —
-- funcionários existentes permanecem ativos).
ALTER TABLE public.store_employees
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 3.1 Papel de super admin baseado em BANCO (tabela super_admins) — o
-- upgrade.sql já referencia public.is_super_admin() no get_audit_log (Parte
-- 5) e nas políticas de plans (Parte 21b); bancos criados ANTES da auditoria
-- C3 podem não ter a tabela/função (versão antiga por e-mail hardcoded).
-- Bloco idempotente: cria a tabela, liga o RLS e recria a função
-- SECURITY DEFINER na versão FINAL (lendo a tabela, não o e-mail).
CREATE TABLE IF NOT EXISTS public.super_admins (
  user_id    UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.super_admins ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_roles WHERE rolname IN ('anon', 'authenticated')
  ) THEN
    EXECUTE 'REVOKE ALL ON public.super_admins FROM anon, authenticated';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.super_admins WHERE user_id = auth.uid()
  );
$$;

-- Migração de continuidade (idempotente): promove o dono do e-mail legado
-- ao papel em tabela. Depois, o papel é governado só pela tabela.
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE lower(email) = 'admin@dumbhanengue.com'
ON CONFLICT (user_id) DO NOTHING;

-- Versões FINAIS (schema.sql). SECURITY DEFINER + search_path fixo: as
-- políticas de stores/tenants/store_employees formam um ciclo entre tabelas
-- que pode estourar a pilha (54001) em varreduras completas; o definer
-- quebra o ciclo por construção e só devolve BOOLEAN sobre um id explícito.
CREATE OR REPLACE FUNCTION public.is_tenant_owner(target_tenant_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.id = target_tenant_id AND t.owner_user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_my_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = target_store_id
      AND (
        public.is_tenant_owner(s.tenant_id)
        OR EXISTS (
          SELECT 1 FROM public.store_employees e
          WHERE e.store_id = s.id AND e.user_id = auth.uid()
            AND e.is_active
        )
      )
  );
$$;


-- ============================================================================
-- PARTE 4 — Nível gerencial: compras exigem dono OU gerente (007)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_manager_of_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = target_store_id
      AND (
        public.is_tenant_owner(s.tenant_id)
        OR EXISTS (
          SELECT 1 FROM public.store_employees e
          WHERE e.store_id = s.id AND e.user_id = auth.uid()
            AND e.role = 'manager'
            AND e.is_active
        )
      )
  );
$$;

-- Políticas RLS de compras (nível manager+; o app grava via RPC
-- process_purchase — as políticas são defesa para acesso direto).
DROP POLICY IF EXISTS purchases_select ON public.purchases;
CREATE POLICY purchases_select ON public.purchases
  FOR SELECT USING (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_insert ON public.purchases;
CREATE POLICY purchases_insert ON public.purchases
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_update ON public.purchases;
CREATE POLICY purchases_update ON public.purchases
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_delete ON public.purchases;
CREATE POLICY purchases_delete ON public.purchases
  FOR DELETE USING (public.is_manager_of_store(store_id));

DROP POLICY IF EXISTS purchase_items_select ON public.purchase_items;
CREATE POLICY purchase_items_select ON public.purchase_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_insert ON public.purchase_items;
CREATE POLICY purchase_items_insert ON public.purchase_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_update ON public.purchase_items;
CREATE POLICY purchase_items_update ON public.purchase_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_delete ON public.purchase_items;
CREATE POLICY purchase_items_delete ON public.purchase_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );


-- ============================================================================
-- PARTE 5 — Audit log imutável das decisões de admin (W9)  [migração 008]
-- ============================================================================
-- Escrita via triggers SECURITY DEFINER; leitura apenas pela RPC
-- get_audit_log (exige is_super_admin). RLS sem políticas + REVOKE de
-- anon/authenticated — mesmo padrão de public.super_admins.
CREATE TABLE IF NOT EXISTS public.audit_log (
  id            BIGSERIAL PRIMARY KEY,
  actor_user_id UUID,
  action        TEXT NOT NULL CHECK (action <> ''),
  entity_type   TEXT NOT NULL CHECK (entity_type <> ''),
  entity_id     TEXT,
  detail        JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_roles WHERE rolname IN ('anon', 'authenticated')
  ) THEN
    EXECUTE 'REVOKE ALL ON public.audit_log FROM anon, authenticated';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.log_audit_entry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  INSERT INTO public.audit_log
    (actor_user_id, action, entity_type, entity_id, detail)
  VALUES (auth.uid(), TG_ARGV[0], TG_TABLE_NAME, NEW.id::text, to_jsonb(NEW));
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_audit_tenant_decision ON public.tenants;
CREATE TRIGGER trg_audit_tenant_decision
  AFTER UPDATE OF status ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_entry('tenant_decision');

DROP TRIGGER IF EXISTS trg_audit_plan_request_decision ON public.plan_requests;
CREATE TRIGGER trg_audit_plan_request_decision
  AFTER UPDATE OF status ON public.plan_requests
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_entry('plan_request_decision');

DROP TRIGGER IF EXISTS trg_audit_plan_change ON public.plans;
CREATE TRIGGER trg_audit_plan_change
  AFTER UPDATE ON public.plans
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_entry('plan_change');

CREATE OR REPLACE FUNCTION public.get_audit_log(p_limit integer DEFAULT 100)
RETURNS SETOF public.audit_log
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Apenas o super admin pode consultar o registo de auditoria.';
  END IF;
  RETURN QUERY SELECT * FROM public.audit_log
    ORDER BY id DESC
    LIMIT GREATEST(1, p_limit);
END $$;


-- ============================================================================
-- PARTE 6 — Conta de funcionário via RPC (sem e-mail)  [migração 005]
-- ============================================================================
-- Conta criada por inserção direta em auth.users + auth.identities com hash
-- bcrypt (pgcrypto) — síncrona e TRANSACIONAL, vínculo na loja na MESMA
-- transação (sem contas órfãs). O Supabase atual removeu
-- auth.admin_create_user; a Admin API do GoTrue é HTTP e assíncrona.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Remove a versão antiga (apenas conta, sem vínculo — 3 parâmetros) para
-- não ficar sobrecarregada no banco.
DROP FUNCTION IF EXISTS public.create_employee_account(text, text, text);

CREATE OR REPLACE FUNCTION public.create_employee_account(
  p_employee_id text,
  p_email text,
  p_password text,
  p_full_name text,
  p_store_id text,
  p_role text DEFAULT 'employee'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
-- `extensions` no search_path: em projetos Supabase geridos as funções do
-- pgcrypto (crypt/gen_salt) vivem no schema `extensions`, não no `public`.
SET search_path = public, extensions
AS $$
DECLARE
  v_owner uuid := auth.uid();
  v_user_id uuid;
  v_tenant_id text;
  v_linked uuid;
BEGIN
  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para cadastrar funcionário.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.tenants t WHERE t.owner_user_id = v_owner
  ) THEN
    RAISE EXCEPTION 'Apenas o dono do tenant pode cadastrar funcionários.';
  END IF;
  IF char_length(p_password) < 8 THEN
    RAISE EXCEPTION 'A senha deve ter pelo menos 8 caracteres.';
  END IF;
  IF p_full_name IS NULL OR trim(p_full_name) = '' THEN
    RAISE EXCEPTION 'Informe o nome do funcionário.';
  END IF;
  IF p_role IS NULL OR p_role NOT IN ('manager', 'employee') THEN
    RAISE EXCEPTION 'Cargo inválido para o funcionário.';
  END IF;
  IF p_email IS NULL OR position('@' IN p_email) = 0 THEN
    RAISE EXCEPTION 'Informe um e-mail válido para o funcionário.';
  END IF;

  -- A loja precisa pertencer a um tenant do DONO autenticado.
  SELECT s.tenant_id INTO v_tenant_id
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = p_store_id AND t.owner_user_id = v_owner;
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Escolha uma loja do seu tenant.';
  END IF;

  -- Idempotência: retry após sucesso devolve o mesmo user_id. O vínculo é
  -- localizado PELA MESMA LOJA — nunca devolve o user_id de outra loja/tenant.
  IF EXISTS (
    SELECT 1 FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id
  ) THEN
    SELECT user_id INTO v_user_id FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id;
    RETURN v_user_id::text;
  END IF;

  -- E-mail duplicado (mensagem amigável). A corrida é protegida pelo
  -- índice único parcial (lower(email) WHERE deleted_at IS NULL) do GoTrue.
  IF EXISTS (
    SELECT 1 FROM auth.users u
    WHERE lower(u.email) = lower(p_email) AND u.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Já existe uma conta com este e-mail.';
  END IF;

  -- Conta confirmada (sem e-mail): inserção direta em auth.users +
  -- auth.identities com hash bcrypt (pgcrypto). Síncrona e transacional —
  -- se o vínculo abaixo falhar, a conta é desfeita junto.
  --
  -- ⚠️ O struct User do GoTrue faz SELECT * e faz scan de TODAS as colunas;
  -- os campos NÃO-anuláveis em Go (string/bool/int) NÃO podem ficar NULL no
  -- banco, senão o login do funcionário rebenta com 500 "Database error
  -- querying schema". Por isso TODAS as colunas do struct são preenchidas
  -- com os mesmos zero-values que o GoTrue grava no signup ('' / false / 0).
  -- `confirmed_at` é coluna GERADA (nunca inserida); `last_sign_in_at`,
  -- `banned_until`, `deleted_at` e os *_sent_at são *time.Time no struct
  -- (NULL é seguro nesses).
  v_user_id := gen_random_uuid();
  INSERT INTO auth.users
    (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
     confirmation_token, recovery_token,
     email_change_token_current, email_change_token_new, email_change,
     email_change_confirm_status, phone_change_token, phone_change,
     reauthentication_token, is_sso_user, is_anonymous,
     raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES
    (v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', lower(p_email), crypt(p_password, gen_salt('bf', 10)),
     now(), '', '', '', '', '', 0, '', '', '', FALSE, FALSE,
     '{"provider":"email","providers":["email"]}'::jsonb,
     jsonb_build_object('full_name', btrim(p_full_name)), now(), now());

  INSERT INTO auth.identities
    (id, provider_id, user_id, identity_data, provider, last_sign_in_at,
     created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_user_id::text, v_user_id,
     jsonb_build_object('sub', v_user_id::text, 'email', lower(p_email),
                        'email_verified', true, 'phone_verified', false,
                        'date_last_signed_in', now()::text),
     'email', now(), now(), now());

  -- Vínculo na loja NA MESMA transação. O trigger enforce_employee_limit
  -- valida o limite do plano e a aprovação do tenant; se falhar, a conta
  -- criada acima é desfeita junto (sem contas órfãs).
  INSERT INTO public.store_employees
    (id, tenant_id, store_id, user_id, full_name, email, role)
  VALUES (p_employee_id, v_tenant_id, p_store_id, v_user_id,
          btrim(p_full_name), lower(p_email), p_role);

  RETURN v_user_id::text;

EXCEPTION
  WHEN unique_violation THEN
    -- Corrida: ou o MESMO vínculo foi criado por outra chamada (retry), ou
    -- o e-mail foi criado por outra chamada concorrente.
    SELECT user_id INTO v_linked FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id;
    IF v_linked IS NOT NULL THEN
      RETURN v_linked::text;
    END IF;
    IF EXISTS (
      SELECT 1 FROM auth.users u
      WHERE lower(u.email) = lower(p_email) AND u.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Já existe uma conta com este e-mail.';
    END IF;
    RAISE EXCEPTION 'Não foi possível criar a conta do funcionário. Tente novamente.';
END;
$$;


-- ============================================================================
-- PARTE 7 — W4: dinheiro em CENTAVOS inteiros (NUMERIC → BIGINT)  [010]
-- ============================================================================
-- Guarda central: só migra se as colunas ainda forem NUMERIC (legado).
-- Bancos já migrados (BIGINT) ou novos (schema.sql) são ignorados — sem
-- dupla multiplicação.
DO $$
DECLARE
  v_type TEXT;
BEGIN
  SELECT data_type INTO v_type
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'products'
    AND column_name = 'purchase_price';

  IF v_type IS NULL OR v_type = 'bigint' THEN
    RETURN; -- já migrado (ou schema novo) — nada a fazer.
  END IF;

  -- products
  ALTER TABLE public.products
    ALTER COLUMN purchase_price TYPE BIGINT USING (ROUND(purchase_price * 100)::bigint),
    ALTER COLUMN sale_price     TYPE BIGINT USING (ROUND(sale_price * 100)::bigint);
  -- sales / sale_items
  ALTER TABLE public.sales
    ALTER COLUMN total_amount TYPE BIGINT USING (ROUND(total_amount * 100)::bigint);
  ALTER TABLE public.sale_items
    ALTER COLUMN unit_price TYPE BIGINT USING (ROUND(unit_price * 100)::bigint);
  -- financial_transactions / debts
  ALTER TABLE public.financial_transactions
    ALTER COLUMN amount TYPE BIGINT USING (ROUND(amount * 100)::bigint);
  ALTER TABLE public.debts
    ALTER COLUMN amount TYPE BIGINT USING (ROUND(amount * 100)::bigint);
  -- purchases / purchase_items
  ALTER TABLE public.purchases
    ALTER COLUMN total_amount TYPE BIGINT USING (ROUND(total_amount * 100)::bigint);
  ALTER TABLE public.purchase_items
    ALTER COLUMN unit_price TYPE BIGINT USING (ROUND(unit_price * 100)::bigint);
  -- plans
  ALTER TABLE public.plans
    ALTER COLUMN price_monthly TYPE BIGINT USING (ROUND(price_monthly * 100)::bigint);
END $$;


-- ============================================================================
-- PARTE 8 — RPCs de dinheiro/KPIs: VERSÕES FINAIS em centavos  [004/007/009/011]
-- ============================================================================
-- Recriadas SEMPRE (CREATE OR REPLACE) e DEPOIS da Parte 7: numa base
-- pré-W4 as versões antigas comparavam `ROUND(x * 100)` — com as colunas
-- já em centavos isso quebraria os totais. As definições abaixo espelham
-- EXATAMENTE o supabase/schema.sql (fonte da verdade).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 8.1 process_sale — venda + itens + baixa de estoque + caixa (1 transação)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_sale(p_sale jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_sale->>'store_id';
  -- W4: total em CENTAVOS inteiros (BIGINT) — comparação exata.
  v_total bigint := (p_sale->>'total_amount')::bigint;
  v_lang text;
  -- Número SEQUENCIAL da venda na loja (sale_number).
  v_sale_number bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar a venda.';
  END IF;
  -- Guarda de acesso: a loja precisa pertencer ao usuário (dono do tenant
  -- ou funcionário vinculado). Substitui o RLS dentro do SECURITY DEFINER.
  IF NOT public.is_my_store(v_store) THEN
    RAISE EXCEPTION 'A loja % não pertence ao usuário logado.', v_store;
  END IF;
  -- Idioma do tenant (escolha do dono) — define a descrição/categoria
  -- gravadas na entrada do caixa (padrão pt).
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  -- Idempotência: o id da venda é a chave de idempotência — um retry após
  -- sucesso (ex.: timeout no cliente) não duplica nada.
  IF EXISTS (SELECT 1 FROM public.sales WHERE id = p_sale->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A venda deve conter ao menos um item.';
  END IF;

  -- Total deve corresponder aos itens — tudo em CENTAVOS inteiros (W4),
  -- comparação exata sem arredondamento.
  IF (SELECT SUM((x->>'quantity')::bigint * (x->>'unit_price')::bigint)
      FROM jsonb_array_elements(p_items) x)
     <> v_total THEN
    RAISE EXCEPTION 'O total da venda não corresponde aos itens.';
  END IF;

  -- Trava e valida o estoque de TODOS os itens (fecha TOCTOU).
  PERFORM public.lock_products_or_raise(p_items, v_store, TRUE);

  -- Número SEQUENCIAL da venda na loja: atribuído AQUI no servidor, dentro
  -- da mesma transação, sob uma advisory lock por loja — duas vendas
  -- concorrentes na mesma loja nunca recebem o mesmo número. O id continua
  -- sendo a chave de idempotência (o RETURN acima não consome número).
  PERFORM pg_advisory_xact_lock(hashtextextended('sale_number:' || v_store, 0));
  SELECT COALESCE(MAX(sale_number), 0) + 1 INTO v_sale_number
  FROM public.sales WHERE store_id = v_store;

  -- Venda + itens (snapshot de nome/preço).
  INSERT INTO public.sales
    (id, user_id, store_id, sale_number, total_amount, payment_method, date_time)
  VALUES (p_sale->>'id', v_uid, v_store, v_sale_number, v_total,
          p_sale->>'payment_method', (p_sale->>'date_time')::timestamptz);

  INSERT INTO public.sale_items
    (sale_id, user_id, product_id, product_name, quantity, unit_price)
  SELECT p_sale->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::bigint
  FROM jsonb_array_elements(p_items) x;

  -- Baixa do estoque (valor atômico no banco — sem leitura/escrita cega).
  UPDATE public.products p
  SET stock_quantity = p.stock_quantity - (x->>'quantity')::int
  FROM jsonb_array_elements(p_items) x
  WHERE p.id = (x->>'product_id') AND p.store_id = v_store;

  -- Entrada no caixa (mesma transação).
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || (p_sale->>'id'), v_uid, v_store,
          CASE v_lang WHEN 'en' THEN 'Sale — ' WHEN 'fr' THEN 'Vente — '
                      ELSE 'Venda ' END
            || public.payment_method_label(p_sale->>'payment_method', v_lang),
          v_total, 'income',
          CASE v_lang WHEN 'en' THEN 'Sales' WHEN 'fr' THEN 'Ventes'
                      ELSE 'Vendas' END,
          (p_sale->>'date_time')::timestamptz, 'paid');
END;
$$;

-- ---------------------------------------------------------------------------
-- 8.2 register_debt — dívida + pendência financeira vinculada (1 transação)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.register_debt(p_debt jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_debt->>'store_id';
  v_customer_debt boolean := (p_debt->>'is_customer_debt')::boolean;
  v_lang text;
  -- Número SEQUENCIAL da dívida na loja (debt_number).
  v_debt_number bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar o fiado.';
  END IF;
  IF NOT public.is_my_store(v_store) THEN
    RAISE EXCEPTION 'A loja % não pertence ao usuário logado.', v_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  IF (p_debt->>'amount')::bigint <= 0 THEN
    RAISE EXCEPTION 'O valor da dívida deve ser maior que zero.';
  END IF;
  -- Idempotência: retry após sucesso não duplica dívida nem pendência.
  IF EXISTS (SELECT 1 FROM public.debts WHERE id = p_debt->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;

  -- Número SEQUENCIAL da dívida na loja: atribuído AQUI no servidor,
  -- dentro da mesma transação, sob uma advisory lock por loja — duas
  -- dívidas concorrentes na mesma loja nunca recebem o mesmo número.
  -- O id continua sendo a chave de idempotência (o RETURN acima não
  -- consome número).
  PERFORM pg_advisory_xact_lock(hashtextextended('debt_number:' || v_store, 0));
  SELECT COALESCE(MAX(debt_number), 0) + 1 INTO v_debt_number
  FROM public.debts WHERE store_id = v_store;

  -- Dívida + pendência financeira vinculada em UMA transação.
  INSERT INTO public.debts
    (id, user_id, store_id, debt_number, person_name, amount, due_date,
     is_customer_debt, is_paid, paid_at, customer_id)
  VALUES (p_debt->>'id', v_uid, v_store, v_debt_number, p_debt->>'person_name',
          (p_debt->>'amount')::bigint, (p_debt->>'due_date')::timestamptz,
          v_customer_debt, FALSE, NULL, p_debt->>'customer_id');

  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
  VALUES ('t' || (p_debt->>'id'), v_uid, v_store,
          CASE v_lang WHEN 'en' THEN
            CASE WHEN v_customer_debt
                 THEN 'Credit to receive — ' || (p_debt->>'person_name')
                 ELSE 'Credit to pay — ' || (p_debt->>'person_name') END
            WHEN 'fr' THEN
            CASE WHEN v_customer_debt
                 THEN 'Crédit à recevoir — ' || (p_debt->>'person_name')
                 ELSE 'Crédit à payer — ' || (p_debt->>'person_name') END
          ELSE
            CASE WHEN v_customer_debt
                 THEN 'Fiado a receber — ' || (p_debt->>'person_name')
                 ELSE 'Fiado a pagar — ' || (p_debt->>'person_name') END
          END,
          (p_debt->>'amount')::bigint,
          CASE WHEN v_customer_debt THEN 'income' ELSE 'expense' END,
          CASE v_lang WHEN 'en' THEN 'Credit' WHEN 'fr' THEN 'Crédit'
                      ELSE 'Fiado' END,
          now(), 'pending', p_debt->>'id');
END;
$$;

-- ---------------------------------------------------------------------------
-- 8.3 settle_debt — baixa da dívida + realização da pendência (1 transação)
-- ---------------------------------------------------------------------------
-- A pendência vinculada é carimbada com date = now() (DATA DE REALIZAÇÃO) —
-- mesma semântica do datasource SQLite local (markAsPaid): o caixa realizado
-- reconhece o dinheiro quando ele ENTRA (auditoria Aug 6).
CREATE OR REPLACE FUNCTION public.settle_debt(p_debt_id text, p_store text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_debt public.debts%ROWTYPE;
  v_lang text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para quitar o fiado.';
  END IF;
  IF NOT public.is_my_store(p_store) THEN
    RAISE EXCEPTION 'A loja % não pertence ao usuário logado.', p_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = p_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;

  SELECT * INTO v_debt FROM public.debts
  WHERE id = p_debt_id AND store_id = p_store;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dívida % não encontrada na loja %.', p_debt_id, p_store;
  END IF;

  -- Idempotência: retry após sucesso (ex.: timeout no cliente) não
  -- duplica a entrada no caixa.
  IF v_debt.is_paid THEN
    RETURN;
  END IF;

  -- 1. Baixa da dívida (guarda de concorrência: só baixa se ainda
  --    pendente — se outra chamada já quitou, retorna sem efeito).
  UPDATE public.debts SET is_paid = TRUE, paid_at = now()
  WHERE id = p_debt_id AND store_id = p_store
    AND NOT is_paid;
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- 2. Pendência vinculada (debt_id): marca a MESMA transação como paga
  --    (nunca cria duplicata no caixa) e carimba a DATA DE REALIZAÇÃO.
  UPDATE public.financial_transactions
  SET status = 'paid', date = now()
  WHERE debt_id = p_debt_id AND store_id = p_store
    AND status = 'pending';

  -- 3. Fiado antigo SEM nenhuma transação vinculada (pendente ou paga):
  --    registra a entrada direto. O id usa o sufixo '_settle' para nunca
  --    colidir com a pendência do register_debt nem com ids do AppIds.
  IF NOT EXISTS (
    SELECT 1 FROM public.financial_transactions
    WHERE debt_id = p_debt_id AND store_id = p_store
  ) THEN
    INSERT INTO public.financial_transactions
      (id, user_id, store_id, description, amount, type, category,
       date, status, debt_id)
    VALUES ('t' || p_debt_id || '_settle', v_uid, p_store,
            CASE v_lang WHEN 'en'
                 THEN 'Credit received — ' || v_debt.person_name
                 WHEN 'fr'
                 THEN 'Crédit reçu — ' || v_debt.person_name
                 ELSE 'Recebimento de fiado — ' || v_debt.person_name END,
            v_debt.amount, 'income',
            CASE v_lang WHEN 'en' THEN 'Credit' WHEN 'fr' THEN 'Crédit'
                        ELSE 'Fiado' END,
            now(), 'paid', p_debt_id);
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8.4 process_purchase — compra + itens + entrada de estoque + caixa
-- ---------------------------------------------------------------------------
-- Nível gerencial: exige is_manager_of_store (dono OU gerente) — substitui o
-- RLS dentro do SECURITY DEFINER.
CREATE OR REPLACE FUNCTION public.process_purchase(p_purchase jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_purchase->>'store_id';
  -- W4: total em CENTAVOS inteiros (BIGINT) — comparação exata.
  v_total bigint := (p_purchase->>'total_amount')::bigint;
  v_lang text;
  -- Número SEQUENCIAL da compra na loja (purchase_number).
  v_purchase_number bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar a compra.';
  END IF;
  -- Guarda de nível gerencial (matriz de acesso Aug 6): compras exigem
  -- DONO ou GERENTE da loja — o funcionário comum opera vendas/estoque,
  -- mas NÃO registra compras.
  IF NOT public.is_manager_of_store(v_store) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem registrar compras na loja %.', v_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  -- Idempotência: o id da compra é a chave de idempotência.
  IF EXISTS (SELECT 1 FROM public.purchases WHERE id = p_purchase->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A compra deve conter ao menos um item.';
  END IF;

  -- Total em CENTAVOS inteiros (W4) — comparação exata sem arredondamento.
  IF (SELECT SUM((x->>'quantity')::bigint * (x->>'unit_price')::bigint)
      FROM jsonb_array_elements(p_items) x)
     <> v_total THEN
    RAISE EXCEPTION 'O total da compra não corresponde aos itens.';
  END IF;

  -- Valida e trava a existência de TODOS os produtos ANTES de mutar.
  PERFORM public.lock_products_or_raise(p_items, v_store, FALSE);

  -- Número SEQUENCIAL da compra na loja: atribuído AQUI no servidor,
  -- dentro da mesma transação, sob uma advisory lock por loja — duas
  -- compras concorrentes na mesma loja nunca recebem o mesmo número.
  -- O id continua sendo a chave de idempotência (o RETURN acima não
  -- consome número).
  PERFORM pg_advisory_xact_lock(
    hashtextextended('purchase_number:' || v_store, 0));
  SELECT COALESCE(MAX(purchase_number), 0) + 1 INTO v_purchase_number
  FROM public.purchases WHERE store_id = v_store;

  -- Compra + itens. payment_method vem no payload (mesmo enum de vendas);
  -- clientes antigos sem o campo caem em 'cash' (compra à vista).
  INSERT INTO public.purchases
    (id, user_id, store_id, purchase_number, supplier_name, total_amount, payment_method, date_time)
  VALUES (p_purchase->>'id', v_uid, v_store, v_purchase_number,
          p_purchase->>'supplier_name',
          v_total, COALESCE(p_purchase->>'payment_method', 'cash'),
          (p_purchase->>'date_time')::timestamptz);

  INSERT INTO public.purchase_items
    (purchase_id, user_id, product_id, product_name, quantity, unit_price)
  SELECT p_purchase->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::bigint
  FROM jsonb_array_elements(p_items) x;

  -- Entrada de estoque (produtos já validados acima).
  UPDATE public.products p
  SET stock_quantity = p.stock_quantity + (x->>'quantity')::int
  FROM jsonb_array_elements(p_items) x
  WHERE p.id = (x->>'product_id') AND p.store_id = v_store;

  -- Saída no caixa (mesma transação).
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || (p_purchase->>'id'), v_uid, v_store,
          CASE v_lang WHEN 'en'
               THEN 'Purchase — ' || (p_purchase->>'supplier_name')
               WHEN 'fr'
               THEN 'Achat — ' || (p_purchase->>'supplier_name')
               ELSE 'Compra — ' || (p_purchase->>'supplier_name') END,
          v_total, 'expense',
          CASE v_lang WHEN 'en' THEN 'Purchases' WHEN 'fr' THEN 'Achats'
                      ELSE 'Compras' END,
          (p_purchase->>'date_time')::timestamptz, 'paid');
END;
$$;

-- ---------------------------------------------------------------------------
-- 8.5 get_dashboard_kpis — 4 indicadores da loja em UMA chamada (W5)
-- ---------------------------------------------------------------------------
-- W4: retornos em CENTAVOS inteiros (BIGINT). O período [p_start, p_end]
-- afeta APENAS o caixa (status paid); vendas, fiado e estoque são totais.
CREATE OR REPLACE FUNCTION public.get_dashboard_kpis(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ
)
RETURNS TABLE (
  total_sales   BIGINT,
  cash_income   BIGINT,
  cash_expense  BIGINT,
  pending_total BIGINT,
  stock_total   BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Acesso negado a esta loja.';
  END IF;

  RETURN QUERY
  SELECT
    -- Apenas vendas ATIVAS: anuladas saem do KPI (o caixa é ajustado
    -- pelo estorno em financial_transactions, que já não as inclui).
    COALESCE((SELECT SUM(s.total_amount) FROM public.sales s
              WHERE s.store_id = p_store_id AND s.status = 'active'), 0)::bigint,
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'income'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0)::bigint,
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'expense'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0)::bigint,
    COALESCE((SELECT SUM(d.amount) FROM public.debts d
              WHERE d.store_id = p_store_id
                AND d.is_customer_debt = TRUE AND d.is_paid = FALSE), 0)::bigint,
    COALESCE((SELECT SUM(p.stock_quantity) FROM public.products p
              WHERE p.store_id = p_store_id), 0)::bigint;
END $$;

-- ---------------------------------------------------------------------------
-- 8.6 get_cash_flow — entradas − saídas PAID no período (H2)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_cash_flow(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ
)
RETURNS TABLE (
  income_cents  BIGINT,
  expense_cents BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Acesso negado a esta loja.';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'income'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0)::bigint,
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'expense'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0)::bigint;
END $$;

-- ---------------------------------------------------------------------------
-- 8.7 get_sales_report — faturamento, lucro, top 5 e vendas/dia (H2)
-- ---------------------------------------------------------------------------
-- O dia é agrupado no fuso do dispositivo (p_tz_offset_minutes) para casar
-- com o DateTime(y, m, d) local do cliente. O cast usa AT TIME ZONE 'UTC'
-- para ser imune ao fuso da sessão do banco.
CREATE OR REPLACE FUNCTION public.get_sales_report(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_tz_offset_minutes INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_revenue BIGINT;
  v_profit  BIGINT;
  v_best    JSONB;
  v_daily   JSONB;
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Acesso negado a esta loja.';
  END IF;

  -- Faturamento: soma dos totais das vendas no período.
  SELECT COALESCE(SUM(s.total_amount), 0)::bigint INTO v_revenue
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.date_time >= p_start AND s.date_time <= p_end;

  -- Lucro bruto: Σ quantity × (unit_price − purchase_price ATUAL do
  -- catálogo; 0 para produtos que não existem mais) — mesma semântica
  -- client-side.
  SELECT COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(pr.purchase_price, 0))), 0)::bigint
  INTO v_profit
  FROM public.sale_items si
  JOIN public.sales s ON s.id = si.sale_id
  LEFT JOIN public.products pr
         ON pr.id = si.product_id AND pr.store_id = p_store_id
  WHERE s.store_id = p_store_id
    AND s.date_time >= p_start AND s.date_time <= p_end;

  -- Mais vendidos (top 5 por quantidade) com receita por produto.
  SELECT COALESCE(jsonb_agg(row ORDER BY row.quantity DESC), '[]'::jsonb)
  INTO v_best
  FROM (
    SELECT si.product_id, si.product_name,
           SUM(si.quantity)::bigint AS quantity,
           SUM(si.quantity * si.unit_price)::bigint AS revenue_cents
    FROM public.sale_items si
    JOIN public.sales s ON s.id = si.sale_id
    WHERE s.store_id = p_store_id
      AND s.date_time >= p_start AND s.date_time <= p_end
    GROUP BY si.product_id, si.product_name
    ORDER BY quantity DESC
    LIMIT 5
  ) row;

  -- Vendas por dia (fuso local do cliente via offset em minutos).
  SELECT COALESCE(jsonb_agg(d ORDER BY d.day), '[]'::jsonb)
  INTO v_daily
  FROM (
    SELECT ((s.date_time + make_interval(mins => p_tz_offset_minutes)) AT TIME ZONE 'UTC')::date AS day,
           SUM(s.total_amount)::bigint AS total_cents
    FROM public.sales s
    WHERE s.store_id = p_store_id
      AND s.date_time >= p_start AND s.date_time <= p_end
    GROUP BY 1
  ) d;

  RETURN jsonb_build_object(
    'total_revenue_cents', v_revenue,
    'total_profit_cents', v_profit,
    'best_sellers', v_best,
    'per_day', v_daily
  );
END $$;


-- ============================================================================
-- PARTE 13 — Ajustes do tenant (moeda/idioma) por RPC (update_tenant_settings)
-- ============================================================================
-- O dono altera moeda/idioma em Lojas → Ajustes via RPC SECURITY DEFINER
-- (guarda is_tenant_owner + UPDATE restrito às colunas de apresentação) em
-- vez de UPDATE direto: a política RLS tenants_update continua restrita ao
-- super admin (status/plano são decisões do admin). Sem esta RPC, o UPDATE
-- do dono batia na política e retornava 0 linhas — os ajustes nunca salvavam.
CREATE OR REPLACE FUNCTION public.update_tenant_settings(
  p_tenant_id TEXT,
  p_currency_code TEXT,
  p_language TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_currency text := CASE WHEN p_currency_code IN ('BRL','USD','EUR','MZN')
                          THEN p_currency_code ELSE 'MZN' END;
  v_lang text := CASE WHEN p_language IN ('pt','en','fr')
                      THEN p_language ELSE 'pt' END;
BEGIN
  IF NOT public.is_tenant_owner(p_tenant_id) THEN
    RAISE EXCEPTION 'Apenas o dono do tenant pode alterar moeda e idioma.';
  END IF;

  UPDATE public.tenants
     SET currency_code = v_currency,
         language = v_lang
   WHERE id = p_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tenant % não encontrado.', p_tenant_id;
  END IF;
END;
$$;

-- ============================================================================
-- PARTE 14 — Número SEQUENCIAL de venda por loja (sale_number)
-- ============================================================================
-- O app exibe "S-00001, S-00002..." (número SEQUENCIAL dentro da loja, em
-- ordem de data). A coluna é atribuída pelo RPC process_sale (atualizado na
-- Parte 8.1 acima — CREATE OR REPLACE) sob advisory lock por loja; bases
-- antigas ganham a coluna aqui e têm as vendas existentes re-numeradas
-- (a mais antiga da loja = 1). Idempotente: ADD COLUMN IF NOT EXISTS;
-- re-executar renumera com base na ordem atual (sem duplicatas, pois o
-- backfill usa ROW_NUMBER e o índice único garante a unicidade).
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS sale_number BIGINT;

-- Backfill IDEMPOTENTE: numera APENAS as vendas ainda sem número (NULL),
-- começando depois do maior número já existente da loja. Nunca renumera
-- linhas já numeradas — reaplicar o upgrade.sql com dados é um no-op (não
-- reordena números nem gera violação transitória do índice único por troca
-- de valores durante o UPDATE).
UPDATE public.sales s
SET sale_number = s2.max_so_far + s2.rn
FROM (
  SELECT s1.id,
         ROW_NUMBER() OVER (
           PARTITION BY s1.store_id ORDER BY s1.date_time, s1.id
         ) AS rn,
         mx.max_so_far
  FROM public.sales s1
  JOIN (
    SELECT store_id, COALESCE(MAX(sale_number), 0) AS max_so_far
    FROM public.sales
    GROUP BY store_id
  ) mx ON mx.store_id = s1.store_id
  WHERE s1.sale_number IS NULL
) s2
WHERE s.id = s2.id;

-- A partir daqui todo INSERT precisa informar o número (o process_sale
-- atribui; o PostgREST direto sem sale_number falha — comportamento
-- intencional: numeração é responsabilidade do servidor).
ALTER TABLE public.sales ALTER COLUMN sale_number SET NOT NULL;

-- Unicidade do número por loja (defesa em profundidade).
CREATE UNIQUE INDEX IF NOT EXISTS uq_sales_store_number
  ON public.sales (store_id, sale_number);

-- ============================================================================
-- PARTE 15 — Número SEQUENCIAL de compra por loja (purchase_number)
-- ============================================================================
-- O app exibe "C-00001, C-00002..." (número SEQUENCIAL dentro da loja, em
-- ordem de data). A coluna é atribuída pelo RPC process_purchase
-- (atualizado na Parte 8.2 acima — CREATE OR REPLACE) sob advisory lock
-- por loja; bases antigas ganham a coluna aqui e têm as compras existentes
-- re-numeradas (a mais antiga da loja = 1). Idempotente: ADD COLUMN IF NOT
-- EXISTS; o backfill numera APENAS as linhas sem número, começando depois
-- do maior número já existente da loja (reaplicar com dados é um no-op).
ALTER TABLE public.purchases ADD COLUMN IF NOT EXISTS purchase_number BIGINT;

-- Backfill IDEMPOTENTE: numera APENAS as compras ainda sem número (NULL),
-- começando depois do maior número já existente da loja. Nunca renumera
-- linhas já numeradas — reaplicar o upgrade.sql com dados é um no-op (não
-- reordena números nem gera violação transitória do índice único por troca
-- de valores durante o UPDATE).
UPDATE public.purchases s
SET purchase_number = s2.max_so_far + s2.rn
FROM (
  SELECT s1.id,
         ROW_NUMBER() OVER (
           PARTITION BY s1.store_id ORDER BY s1.date_time, s1.id
         ) AS rn,
         mx.max_so_far
  FROM public.purchases s1
  JOIN (
    SELECT store_id, COALESCE(MAX(purchase_number), 0) AS max_so_far
    FROM public.purchases
    GROUP BY store_id
  ) mx ON mx.store_id = s1.store_id
  WHERE s1.purchase_number IS NULL
) s2
WHERE s.id = s2.id;

-- A partir daqui todo INSERT precisa informar o número (o process_purchase
-- atribui; o PostgREST direto sem purchase_number falha — comportamento
-- intencional: numeração é responsabilidade do servidor).
ALTER TABLE public.purchases ALTER COLUMN purchase_number SET NOT NULL;

-- Unicidade do número por loja (defesa em profundidade).
CREATE UNIQUE INDEX IF NOT EXISTS uq_purchases_store_number
  ON public.purchases (store_id, purchase_number);

-- ============================================================================
-- PARTE 16 — Número SEQUENCIAL de fiado por loja (debt_number)
-- ============================================================================
-- O app exibe "D-00001, D-00002..." (número SEQUENCIAL dentro da loja, em
-- ordem de vencimento). A coluna é atribuída pelo RPC register_debt
-- (atualizado na Parte 8.2 acima — CREATE OR REPLACE) sob advisory lock
-- por loja; bases antigas ganham a coluna aqui e têm as dívidas existentes
-- re-numeradas (a mais antiga da loja = 1). Idempotente: ADD COLUMN IF NOT
-- EXISTS; o backfill numera APENAS as linhas sem número, começando depois
-- do maior número já existente da loja (reaplicar com dados é um no-op).
ALTER TABLE public.debts ADD COLUMN IF NOT EXISTS debt_number BIGINT;

-- Backfill IDEMPOTENTE: numera APENAS as dívidas ainda sem número (NULL),
-- começando depois do maior número já existente da loja. Nunca renumera
-- linhas já numeradas — reaplicar o upgrade.sql com dados é um no-op (não
-- reordena números nem gera violação transitória do índice único por troca
-- de valores durante o UPDATE).
UPDATE public.debts s
SET debt_number = s2.max_so_far + s2.rn
FROM (
  SELECT s1.id,
         ROW_NUMBER() OVER (
           PARTITION BY s1.store_id ORDER BY s1.due_date, s1.id
         ) AS rn,
         mx.max_so_far
  FROM public.debts s1
  JOIN (
    SELECT store_id, COALESCE(MAX(debt_number), 0) AS max_so_far
    FROM public.debts
    GROUP BY store_id
  ) mx ON mx.store_id = s1.store_id
  WHERE s1.debt_number IS NULL
) s2
WHERE s.id = s2.id;

-- A partir daqui todo INSERT precisa informar o número (o register_debt
-- atribui; o PostgREST direto sem debt_number falha — comportamento
-- intencional: numeração é responsabilidade do servidor).
ALTER TABLE public.debts ALTER COLUMN debt_number SET NOT NULL;

-- Unicidade do número por loja (defesa em profundidade).
CREATE UNIQUE INDEX IF NOT EXISTS uq_debts_store_number
  ON public.debts (store_id, debt_number);


-- ============================================================================
-- PARTE 17 — Formas de pagamento: Pix → M-Pesa e E-Mola
-- ============================================================================
-- O produto trocou o Pix (BR) pelas carteiras de dinheiro móvel de
-- Moçambique (M-Pesa e E-Mola). O payment_method é TEXT com CHECK — bases
-- antigas precisam: (1) DERrubar o CHECK legado ANTES de migrar os dados
-- (o constraint antigo aceita 'pix' mas NÃO 'mPesa' — o UPDATE com o CHECK
-- em pé violaria 23514), (2) migrar os registros 'pix' para 'mPesa'
-- (escolha do produto: M-Pesa é a operadora dominante; o enum Dart é
-- persistido pelo nome, então sem migração a leitura quebraria), (3) criar
-- o CHECK novo com a lista oficial e (4) recriar o payment_method_label
-- (rótulos da descrição no caixa). Idempotente: o DROP/ADD do CHECK é IF
-- EXISTS / recriação com o mesmo nome e a migração só toca 'pix'.
-- ============================================================================

-- 17.1 DROP do CHECK legado PRIMEIRO (sem ele, o UPDATE abaixo viola o
-- constraint antigo: 23514 check_violation).
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_payment_method_check;

-- 17.2 Migração de dados: 'pix' → 'mPesa' (no-op se não houver 'pix').
UPDATE public.sales SET payment_method = 'mPesa'
WHERE payment_method = 'pix';

-- 17.3 CHECK novo (CREATE TABLE IF NOT EXISTS não altera tabelas
-- existentes; o nome segue a convenção <tabela>_<coluna>_check).
ALTER TABLE public.sales ADD CONSTRAINT sales_payment_method_check
  CHECK (payment_method IN
    ('cash', 'debitCard', 'creditCard', 'mPesa', 'eMola', 'transfer'));

-- 17.4 Rótulo localizado (espelha o TransactionDescriptions.paymentMethodName
-- do Dart e o payment_method_label do schema.sql — fonte da verdade; o
-- process_sale da Parte 8.1 chama esta função, então a nova versão vale
-- imediatamente).
CREATE OR REPLACE FUNCTION public.payment_method_label(
  p_method text,
  p_lang text DEFAULT 'pt'
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT CASE p_lang WHEN 'en' THEN
      CASE p_method
        WHEN 'cash' THEN 'Cash' WHEN 'debitCard' THEN 'Debit card'
        WHEN 'creditCard' THEN 'Credit card' WHEN 'mPesa' THEN 'M-Pesa'
        WHEN 'eMola' THEN 'E-Mola' WHEN 'transfer' THEN 'Bank transfer'
        ELSE p_method END
    WHEN 'fr' THEN
      CASE p_method
        WHEN 'cash' THEN 'Espèces' WHEN 'debitCard' THEN 'Carte de débit'
        WHEN 'creditCard' THEN 'Carte de crédit' WHEN 'mPesa' THEN 'M-Pesa'
        WHEN 'eMola' THEN 'E-Mola' WHEN 'transfer' THEN 'Virement'
        ELSE p_method END
    ELSE
      CASE p_method
        WHEN 'cash' THEN 'Dinheiro' WHEN 'debitCard' THEN 'Cartão de débito'
        WHEN 'creditCard' THEN 'Cartão de crédito' WHEN 'mPesa' THEN 'M-Pesa'
        WHEN 'eMola' THEN 'E-Mola' WHEN 'transfer' THEN 'Transferência'
        ELSE p_method END
    END;
$$;

-- ============================================================================
-- 18. Compras: forma de pagamento do fornecedor (mesmo enum de vendas)
-- ============================================================================
-- O Purchase ganhou `paymentMethod` (espelha o enum de Vendas). A compra
-- antiga não registrava o método — a coluna nasce com DEFAULT 'cash'
-- (interpretação: pagamento à vista) e o CHECK passa a valer a lista
-- oficial. O `process_purchase` (Parte 8.4) já lê `payment_method` do
-- payload (COALESCE 'cash' para clientes antigos). Idempotente: ADD
-- COLUMN IF NOT EXISTS + DROP/ADD do CHECK com o mesmo nome.
-- ============================================================================

-- 18.1 Coluna + backfill implícito (DEFAULT 'cash' para linhas existentes).
ALTER TABLE public.purchases
  ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'cash';

-- 18.2 CHECK novo (DROP + ADD: CREATE TABLE IF NOT EXISTS não altera
-- tabelas existentes; o nome segue a convenção <tabela>_<coluna>_check).
ALTER TABLE public.purchases
  DROP CONSTRAINT IF EXISTS purchases_payment_method_check;
ALTER TABLE public.purchases
  ADD CONSTRAINT purchases_payment_method_check
  CHECK (payment_method IN
    ('cash', 'debitCard', 'creditCard', 'mPesa', 'eMola', 'transfer'));

-- ============================================================================
-- 19. Ativação/desativação de funcionários (dono) + bloqueio de inativos
-- ============================================================================
-- O dono ativa/desativa funcionários; o funcionário DESATIVADO perde o
-- acesso imediatamente: `is_my_store`/`is_manager_of_store` passam a
-- exigir vínculo ATIVO (abaixo), então RLS e guardas das RPCs negam
-- qualquer operação nas lojas. Coluna nasce DEFAULT TRUE (funcionários
-- existentes permanecem ativos). Idempotente (ADD COLUMN IF NOT EXISTS).
-- ============================================================================

-- 19.1 Coluna is_active no vínculo store_employees. (Já adicionada na
-- Parte 3.0 — ANTES das funções LANGUAGE sql is_my_store/is_manager_of_store
-- que a referenciam. Repetida aqui por clareza; ADD COLUMN IF NOT EXISTS é
-- idempotente.)
ALTER TABLE public.store_employees
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 19.2 RPC set_employee_active (SECURITY DEFINER + guarda is_tenant_owner):
-- apenas o DONO do tenant do vínculo muda o status.
CREATE OR REPLACE FUNCTION public.set_employee_active(
  p_employee_id TEXT,
  p_is_active BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant_id TEXT;
BEGIN
  SELECT tenant_id INTO v_tenant_id
  FROM public.store_employees WHERE id = p_employee_id;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Funcionário não encontrado.';
  END IF;
  IF NOT public.is_tenant_owner(v_tenant_id) THEN
    RAISE EXCEPTION 'Apenas o dono do tenant pode ativar/desativar funcionários.';
  END IF;

  UPDATE public.store_employees
  SET is_active = p_is_active
  WHERE id = p_employee_id;
END;
$$;

-- 19.3 is_my_store / is_manager_of_store exigem vínculo ATIVO (aplicado
-- também acima nas definições das funções; idempotente por definição).

-- ============================================================================
-- 20. Realtime de funcionários: publica store_employees (bloqueio instantâneo)
-- ============================================================================
-- O app assina `postgres_changes` em `store_employees` com filtro
-- `user_id = auth.uid()` para derrubar a sessão de um funcionário
-- desativado NA HORA (sem polling). Sem a tabela na publicação
-- `supabase_realtime`, o canal nunca recebe eventos. O RLS da tabela
-- limita cada sessão ao PRÓPRIO vínculo (e o funcionário segue lendo a
-- própria linha após desativado, então ele recebe a mudança de
-- `is_active`). Idempotente (fix Aug 8): em PostgreSQL PURO, ADD TABLE
-- numa tabela já publicada é um no-op, mas no SUPABASE é um ERRO 42710
-- (duplicate_object) — o bloco confere a associação em
-- pg_publication_tables ANTES de publicar. Em PostgreSQL puro
-- (sql_check.sh) a publicação não existe → no-op também.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'store_employees'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.store_employees;
  END IF;
END
$$;

-- ============================================================================
-- 21. Seed idempotente do CATÁLOGO DE PLANOS (fix Aug 8 — registro de dono)
-- ============================================================================
-- BUG CORRIGIDO: o catálogo de planos (pl1/pl2/pl3) era inserido apenas na
-- Parte 2 do `schema.sql` (instalação nova). Bancos EXISTENTES migrados por
-- ESTE arquivo ficavam com a tabela `plans` VAZIA → o onboarding do dono
-- carregava zero planos → o registro de novo tenant era impossível (e o
-- INSERT em `tenants` falharia por FK `plan_id REFERENCES public.plans`).
--
-- Este seed é o MESMO do schema.sql (Parte 2): a tabela de preços REAL,
-- espelhando o catálogo local (PlanCatalog no app — pl1/pl2/pl3), NÃO dados
-- de demonstração. Idempotente: ON CONFLICT (id) DO NOTHING — pode reexecutar
-- o upgrade.sql à vontade; planos editados pelo super admin não são tocados.
-- (No SQL Editor a sessão é dona do schema e ignora o RLS, então o INSERT
-- passa mesmo com a política plans_insert exigindo is_super_admin.)
INSERT INTO public.plans
  (id, name, description, price_monthly, max_stores, max_employees, is_active)
VALUES
  ('pl1', 'Essencial', 'Para começar: 1 loja e até 3 funcionários.', 50000, 1, 3, TRUE),
  ('pl2', 'Profissional', 'Para crescer: 3 lojas e até 10 funcionários.', 100000, 3, 10, TRUE),
  ('pl3', 'Empresa', 'Para expandir: 10 lojas e até 50 funcionários.', 200000, 10, 50, TRUE)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 21b. Políticas RLS de `plans` (super admin escreve; logados leem)
-- ============================================================================
-- Espelha o schema.sql (seção 1.7): planos são leitura para qualquer usuário
-- logado (catálogo do onboarding/upgrade) e escrita SOMENTE do super admin
-- (painel de gestão de planos). Bancos existentes migrados por ESTE script
-- podem ter sido criados ANTES das políticas por is_super_admin (auditoria
-- C3) — o DROP + CREATE idempotente garante que o super admin SEMPRE possa
-- criar/editar/salvar planos e que o RLS não bloqueie o INSERT/UPDATE.
DROP POLICY IF EXISTS plans_select ON public.plans;
CREATE POLICY plans_select ON public.plans
  FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS plans_insert ON public.plans;
CREATE POLICY plans_insert ON public.plans
  FOR INSERT WITH CHECK (public.is_super_admin());
DROP POLICY IF EXISTS plans_update ON public.plans;
CREATE POLICY plans_update ON public.plans
  FOR UPDATE USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());
DROP POLICY IF EXISTS plans_delete ON public.plans;
CREATE POLICY plans_delete ON public.plans
  FOR DELETE USING (public.is_super_admin());
-- ============================================================================
-- 22. W11 — FIFO, validade por lotes e vendas por peso (milésimos)
-- ============================================================================
-- Módulo de controle de validade (lotes FIFO) + vendas por fração/peso:
--   * NOVAS colunas em products (code/venda_por_fracao/unit_label) e
--     purchase_items (expiry_date);
--   * NOVA tabela stock_lots (lote = entrada de mercadoria; baixa no PDV em
--     ordem de validade / data de entrada);
--   * TODAS as quantidades convertidas de unidades inteiras para MILÉSIMOS
--     (×1000) — produtos, itens de venda e itens de compra; cada produto com
--     estoque ganha um lote inicial (sem validade) para a invariante
--     `stock = Σ lotes` valer desde o primeiro dia;
--   * RPCs process_sale (baixa FIFO) / process_purchase (cria lotes) /
--     get_sales_report (matemática em milésimos) recriadas.
--
-- 100% idempotente: colunas usam ADD COLUMN IF NOT EXISTS, a tabela usa
-- CREATE TABLE IF NOT EXISTS, funções usam CREATE OR REPLACE, e a migração
-- ×1000 + backfill roda apenas quando stock_lots está VAZIO (primeira
-- execução — reexecutar é um no-op).
-- ============================================================================

-- 22.1 Colunas novas (idempotente — bancos novos já as criam no schema.sql)
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS code TEXT,
  ADD COLUMN IF NOT EXISTS venda_por_fracao BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS unit_label TEXT NOT NULL DEFAULT 'un';

-- Validade opcional por item de compra (lote FIFO correspondente).
ALTER TABLE public.purchase_items
  ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- 22.2 Tabela de lotes (espelha a entidade StockLot) + índices
CREATE TABLE IF NOT EXISTS public.stock_lots (
  id                TEXT PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id          TEXT NOT NULL DEFAULT 'st1',
  product_id        TEXT NOT NULL,
  -- data_entrada: data da compra que originou o lote (FIFO sem validade).
  entry_date        TIMESTAMPTZ NOT NULL,
  -- data_validade: NULL para produtos sem validade (não perecíveis).
  expiry_date       TIMESTAMPTZ,
  -- quantidade_inicial recebida (milésimos) — referência histórica.
  initial_quantity  BIGINT NOT NULL CHECK (initial_quantity >= 0),
  -- quantidade_atual disponível (milésimos) — diminui a cada baixa FIFO.
  current_quantity  BIGINT NOT NULL CHECK (current_quantity >= 0),
  -- custo_aquisicao em CENTAVOS inteiros (W4) — custo do lote na compra.
  cost_price        BIGINT NOT NULL CHECK (cost_price >= 0)
);
CREATE INDEX IF NOT EXISTS idx_stock_lots_product
  ON public.stock_lots (product_id, store_id);
CREATE INDEX IF NOT EXISTS idx_stock_lots_expiry
  ON public.stock_lots (expiry_date) WHERE current_quantity > 0;

-- 22.3 Migração para MILÉSIMOS + backfill de lotes iniciais
-- Guarda: roda apenas quando stock_lots está VAZIO (primeira execução);
-- reexecutar o upgrade é um no-op. Produtos com estoque ganham um lote
-- inicial sem validade (custo = preço de compra atual).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.stock_lots LIMIT 1) THEN
    UPDATE public.products SET stock_quantity = stock_quantity * 1000;
    UPDATE public.sale_items SET quantity = quantity * 1000;
    UPDATE public.purchase_items SET quantity = quantity * 1000;

    INSERT INTO public.stock_lots
      (id, user_id, store_id, product_id, entry_date, expiry_date,
       initial_quantity, current_quantity, cost_price)
    SELECT 'lot-mig-' || id, user_id, store_id, id, now(), NULL,
           stock_quantity, stock_quantity, purchase_price
    FROM public.products
    WHERE stock_quantity > 0;
  END IF;
END $$;

-- 22.4 RLS + políticas + triggers da tabela de lotes
ALTER TABLE public.stock_lots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS stock_lots_select ON public.stock_lots;
CREATE POLICY stock_lots_select ON public.stock_lots
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS stock_lots_insert ON public.stock_lots;
CREATE POLICY stock_lots_insert ON public.stock_lots
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS stock_lots_update ON public.stock_lots;
CREATE POLICY stock_lots_update ON public.stock_lots
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS stock_lots_delete ON public.stock_lots;
CREATE POLICY stock_lots_delete ON public.stock_lots
  FOR DELETE USING (auth.uid() = user_id);

-- user_id = auth.uid() em todo INSERT (defesa em profundidade).
DROP TRIGGER IF EXISTS trg_stock_lots_user_id ON public.stock_lots;
CREATE TRIGGER trg_stock_lots_user_id
  BEFORE INSERT ON public.stock_lots
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- store_id = loja do usuário quando o valor enviado não pertence a ele.
DROP TRIGGER IF EXISTS trg_stock_lots_store_id ON public.stock_lots;
CREATE TRIGGER trg_stock_lots_store_id
  BEFORE INSERT ON public.stock_lots
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- 22.5 RPC process_sale — baixa do estoque em FIFO por lotes (W11)
CREATE OR REPLACE FUNCTION public.process_sale(p_sale jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_sale->>'store_id';
  -- W4: total em CENTAVOS inteiros (BIGINT) — comparação exata.
  v_total bigint := (p_sale->>'total_amount')::bigint;
  v_lang text;
  -- Número SEQUENCIAL da venda na loja (sale_number).
  v_sale_number bigint;
  -- W11 (FIFO por lotes): iteração sobre os itens e consumo dos lotes.
  v_item jsonb;
  v_remaining bigint;
  v_lot record;
  v_take bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar a venda.';
  END IF;
  -- Guarda de acesso: a loja precisa pertencer ao usuário (dono do tenant
  -- ou funcionário vinculado). Substitui o RLS dentro do SECURITY DEFINER.
  IF NOT public.is_my_store(v_store) THEN
    RAISE EXCEPTION 'A loja % não pertence ao usuário logado.', v_store;
  END IF;
  -- Idioma do tenant (escolha do dono) — define a descrição/categoria
  -- gravadas na entrada do caixa (padrão pt).
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  -- Idempotência: o id da venda é a chave de idempotência — um retry após
  -- sucesso (ex.: timeout no cliente) não duplica nada.
  IF EXISTS (SELECT 1 FROM public.sales WHERE id = p_sale->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A venda deve conter ao menos um item.';
  END IF;

  -- Total deve corresponder aos itens — tudo em CENTAVOS inteiros (W4 +
  -- W11): quantidade em MILÉSIMOS × preço unitário / 1000, divisão inteira
  -- por item (mesmo cálculo do cliente). Comparação exata.
  IF (SELECT SUM((x->>'quantity')::bigint * (x->>'unit_price')::bigint / 1000)
      FROM jsonb_array_elements(p_items) x)
     <> v_total THEN
    RAISE EXCEPTION 'O total da venda não corresponde aos itens.';
  END IF;

  -- Trava e valida o estoque de TODOS os itens (fecha TOCTOU).
  PERFORM public.lock_products_or_raise(p_items, v_store, TRUE);

  -- Número SEQUENCIAL da venda na loja: atribuído AQUI no servidor, dentro
  -- da mesma transação, sob uma advisory lock por loja — duas vendas
  -- concorrentes na mesma loja nunca recebem o mesmo número. O id continua
  -- sendo a chave de idempotência (o RETURN acima não consome número).
  PERFORM pg_advisory_xact_lock(hashtextextended('sale_number:' || v_store, 0));
  SELECT COALESCE(MAX(sale_number), 0) + 1 INTO v_sale_number
  FROM public.sales WHERE store_id = v_store;

  -- Venda + itens (snapshot de nome/preço).
  INSERT INTO public.sales
    (id, user_id, store_id, sale_number, total_amount, payment_method, date_time)
  VALUES (p_sale->>'id', v_uid, v_store, v_sale_number, v_total,
          p_sale->>'payment_method', (p_sale->>'date_time')::timestamptz);

  INSERT INTO public.sale_items
    (sale_id, user_id, product_id, product_name, quantity, unit_price)
  SELECT p_sale->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::bigint
  FROM jsonb_array_elements(p_items) x;

  -- Baixa do estoque em FIFO por lotes (W11): para cada item, consome os
  -- lotes ativos em ordem de VALIDADE (mais próxima primeiro; sem validade
  -- no fim, por data de entrada — e id como desempate estável). Os lotes
  -- são travados com FOR UPDATE (fecha TOCTOU entre vendas concorrentes);
  -- o total do produto (stock_quantity) cai na quantidade vendida, na
  -- mesma transação — a invariante `stock = Σ lotes` nunca quebra.
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_remaining := (v_item->>'quantity')::bigint;
    FOR v_lot IN
      SELECT l.id, l.current_quantity
      FROM public.stock_lots l
      WHERE l.product_id = (v_item->>'product_id')
        AND l.store_id = v_store
        AND l.current_quantity > 0
      ORDER BY CASE WHEN l.expiry_date IS NULL THEN 1 ELSE 0 END,
               l.expiry_date ASC, l.entry_date ASC, l.id ASC
      FOR UPDATE
    LOOP
      IF v_remaining <= 0 THEN EXIT; END IF;
      v_take := LEAST(v_lot.current_quantity, v_remaining);
      UPDATE public.stock_lots
        SET current_quantity = current_quantity - v_take
        WHERE id = v_lot.id;
      -- Registra o consumo do lote (MESMA transação): é o que permite à
      -- anulação (cancel_sale, Parte 23) devolver o estoque aos lotes
      -- EXATOS. v_take é bigint; a coluna quantity é INTEGER — cast
      -- explícito (mesmo padrão do process_purchase).
      INSERT INTO public.sale_lot_consumption
        (sale_id, user_id, lot_id, product_id, quantity)
      VALUES (p_sale->>'id', v_uid, v_lot.id, (v_item->>'product_id'), v_take::int);
      v_remaining := v_remaining - v_take;
    END LOOP;
    IF v_remaining > 0 THEN
      -- Defesa em profundidade (o lock_products_or_raise acima já validou
      -- pelo total do produto): os lotes não cobrem a venda — o estoque
      -- nunca fica negativo por esta RPC.
      RAISE EXCEPTION 'Estoque insuficiente para o produto % (loja %).',
        v_item->>'product_id', v_store;
    END IF;
    UPDATE public.products
      SET stock_quantity = stock_quantity - (v_item->>'quantity')::bigint
      WHERE id = (v_item->>'product_id') AND store_id = v_store;
  END LOOP;

  -- Entrada no caixa (mesma transação).
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || (p_sale->>'id'), v_uid, v_store,
          CASE v_lang WHEN 'en' THEN 'Sale — ' WHEN 'fr' THEN 'Vente — '
                      ELSE 'Venda ' END
            || public.payment_method_label(p_sale->>'payment_method', v_lang),
          v_total, 'income',
          CASE v_lang WHEN 'en' THEN 'Sales' WHEN 'fr' THEN 'Ventes'
                      ELSE 'Vendas' END,
          (p_sale->>'date_time')::timestamptz, 'paid');
END;
$$;

-- 22.6 RPC process_purchase — cria os LOTES FIFO na entrada (W11)
CREATE OR REPLACE FUNCTION public.process_purchase(p_purchase jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_purchase->>'store_id';
  -- W4: total em CENTAVOS inteiros (BIGINT) — comparação exata.
  v_total bigint := (p_purchase->>'total_amount')::bigint;
  v_lang text;
  -- Número SEQUENCIAL da compra na loja (purchase_number).
  v_purchase_number bigint;
  -- W11 (lotes FIFO): iteração sobre os itens para criar os lotes.
  v_item jsonb;
  v_expiry timestamptz;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar a compra.';
  END IF;
  -- Guarda de nível gerencial (matriz de acesso Aug 6): compras exigem
  -- DONO ou GERENTE da loja — o funcionário comum opera vendas/estoque,
  -- mas NÃO registra compras. Substitui o RLS dentro do SECURITY DEFINER
  -- (e o RLS de purchases também exige is_manager_of_store).
  IF NOT public.is_manager_of_store(v_store) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem registrar compras na loja %.', v_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  -- Idempotência: o id da compra é a chave de idempotência.
  IF EXISTS (SELECT 1 FROM public.purchases WHERE id = p_purchase->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A compra deve conter ao menos um item.';
  END IF;

  IF (SELECT SUM((x->>'quantity')::bigint * (x->>'unit_price')::bigint / 1000)
      FROM jsonb_array_elements(p_items) x)
     <> v_total THEN
    RAISE EXCEPTION 'O total da compra não corresponde aos itens.';
  END IF;

  -- Valida e trava a existência de TODOS os produtos ANTES de mutar
  -- (mesmo padrão do process_sale; fecha corrida com exclusão).
  PERFORM public.lock_products_or_raise(p_items, v_store, FALSE);

  -- Número SEQUENCIAL da compra na loja: atribuído AQUI no servidor,
  -- dentro da mesma transação, sob uma advisory lock por loja — duas
  -- compras concorrentes na mesma loja nunca recebem o mesmo número.
  -- O id continua sendo a chave de idempotência (o RETURN acima não
  -- consome número).
  PERFORM pg_advisory_xact_lock(
    hashtextextended('purchase_number:' || v_store, 0));
  SELECT COALESCE(MAX(purchase_number), 0) + 1 INTO v_purchase_number
  FROM public.purchases WHERE store_id = v_store;

  -- Compra + itens. payment_method vem no payload (mesmo enum de vendas);
  -- clientes antigos sem o campo caem em 'cash' (compra à vista).
  INSERT INTO public.purchases
    (id, user_id, store_id, purchase_number, supplier_name, total_amount, payment_method, date_time)
  VALUES (p_purchase->>'id', v_uid, v_store, v_purchase_number,
          p_purchase->>'supplier_name',
          v_total, COALESCE(p_purchase->>'payment_method', 'cash'),
          (p_purchase->>'date_time')::timestamptz);

  INSERT INTO public.purchase_items
    (purchase_id, user_id, product_id, product_name, quantity, unit_price,
     expiry_date)
  SELECT p_purchase->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::bigint,
         NULLIF(x->>'expiry_date', '')::timestamptz
  FROM jsonb_array_elements(p_items) x;

  -- Lotes FIFO (W11): cada item da compra cria um LOTE com data de entrada
  -- = data da compra, validade opcional (NULL = sem validade) e custo de
  -- aquisição = preço unitário da compra. O id do lote deriva do id da
  -- compra (idempotente — a compra já não existe em retries).
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_expiry := NULLIF(v_item->>'expiry_date', '')::timestamptz;
    INSERT INTO public.stock_lots
      (id, user_id, store_id, product_id, entry_date, expiry_date,
       initial_quantity, current_quantity, cost_price)
    VALUES
      ('lot-' || (p_purchase->>'id') || '-' || (v_item->>'product_id'),
       v_uid, v_store, (v_item->>'product_id'),
       (p_purchase->>'date_time')::timestamptz,
       v_expiry,
       (v_item->>'quantity')::bigint, (v_item->>'quantity')::bigint,
       (v_item->>'unit_price')::bigint);
  END LOOP;

  -- Entrada de estoque (produtos já validados acima).
  UPDATE public.products p
  SET stock_quantity = p.stock_quantity + (x->>'quantity')::bigint
  FROM jsonb_array_elements(p_items) x
  WHERE p.id = (x->>'product_id') AND p.store_id = v_store;

  -- Saída no caixa (mesma transação).
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || (p_purchase->>'id'), v_uid, v_store,
          CASE v_lang WHEN 'en'
               THEN 'Purchase — ' || (p_purchase->>'supplier_name')
               WHEN 'fr'
               THEN 'Achat — ' || (p_purchase->>'supplier_name')
               ELSE 'Compra — ' || (p_purchase->>'supplier_name') END,
          v_total, 'expense',
          CASE v_lang WHEN 'en' THEN 'Purchases' WHEN 'fr' THEN 'Achats'
                      ELSE 'Compras' END,
          (p_purchase->>'date_time')::timestamptz, 'paid');
END;
$$;

-- 22.7 RPC get_sales_report — matemática em MILÉSIMOS (W11)
CREATE OR REPLACE FUNCTION public.get_sales_report(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_tz_offset_minutes INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_revenue BIGINT;
  v_profit  BIGINT;
  v_best    JSONB;
  v_daily   JSONB;
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Acesso negado a esta loja.';
  END IF;

  -- Faturamento: soma dos totais das vendas ATIVAS no período (anuladas
  -- saem do relatório — o estorno já ajustou o caixa).
  SELECT COALESCE(SUM(s.total_amount), 0)::bigint INTO v_revenue
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.date_time >= p_start AND s.date_time <= p_end;

  -- Lucro bruto: Σ quantity (MILÉSIMOS — W11) × (unit_price −
  -- purchase_price ATUAL do catálogo; 0 para produtos que não existem
  -- mais) / 1000 — divisão inteira por item, mesma semântica client-side.
  SELECT COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(pr.purchase_price, 0)) / 1000), 0)::bigint
  INTO v_profit
  FROM public.sale_items si
  JOIN public.sales s ON s.id = si.sale_id
  LEFT JOIN public.products pr
         ON pr.id = si.product_id AND pr.store_id = p_store_id
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.date_time >= p_start AND s.date_time <= p_end;

  -- Mais vendidos (top 5 por quantidade) com receita por produto.
  SELECT COALESCE(jsonb_agg(row ORDER BY row.quantity DESC), '[]'::jsonb)
  INTO v_best
  FROM (
    SELECT si.product_id, si.product_name,
           SUM(si.quantity)::bigint AS quantity,
           SUM(si.quantity * si.unit_price / 1000)::bigint AS revenue_cents
    FROM public.sale_items si
    JOIN public.sales s ON s.id = si.sale_id
    WHERE s.store_id = p_store_id
      AND s.status = 'active'
      AND s.date_time >= p_start AND s.date_time <= p_end
    GROUP BY si.product_id, si.product_name
    ORDER BY quantity DESC
    LIMIT 5
  ) row;

  -- Vendas por dia (fuso local do cliente via offset em minutos).
  SELECT COALESCE(jsonb_agg(d ORDER BY d.day), '[]'::jsonb)
  INTO v_daily
  FROM (
    SELECT ((s.date_time + make_interval(mins => p_tz_offset_minutes)) AT TIME ZONE 'UTC')::date AS day,
           SUM(s.total_amount)::bigint AS total_cents
    FROM public.sales s
    WHERE s.store_id = p_store_id
      AND s.status = 'active'
      AND s.date_time >= p_start AND s.date_time <= p_end
    GROUP BY 1
  ) d;

  RETURN jsonb_build_object(
    'total_revenue_cents', v_revenue,
    'total_profit_cents', v_profit,
    'best_sellers', v_best,
    'per_day', v_daily
  );
END $$;

-- ============================================================================
-- PARTE 23 — ANULAÇÃO DE VENDAS (status + consumo de lotes + cancel_sale)
-- ============================================================================
-- Venda anulada (operação GERENCIAL — dono/gerente): permanece no
-- histórico com status 'cancelled' (trilha de auditoria), mas sai dos
-- relatórios/KPIs/resumo do dia; o estoque volta aos lotes EXATOS
-- consumidos (sale_lot_consumption) e o caixa recebe um estorno.
--
-- Idempotente e reexecutável: ALTER/ADD COLUMN IF NOT EXISTS, CREATE TABLE
-- IF NOT EXISTS, DROP POLICY IF EXISTS + CREATE POLICY, triggers com DROP
-- IF EXISTS e CREATE OR REPLACE FUNCTION.
-- ---------------------------------------------------------------------------

-- 23.1 Colunas de status em sales (idempotente — bases antigas recebem via
-- ALTER; bases novas já criam no CREATE TABLE do schema.sql).
ALTER TABLE IF EXISTS public.sales
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE IF EXISTS public.sales
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- 23.2 Consumo de LOTES por venda — gravado na MESMA transação do
-- process_sale (Parte 22.5 já grava). Permite à cancel_sale devolver o
-- estoque aos lotes exatos, preservando validade e custo.
CREATE TABLE IF NOT EXISTS public.sale_lot_consumption (
  id         BIGSERIAL PRIMARY KEY,
  sale_id    TEXT NOT NULL REFERENCES public.sales (id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  lot_id     TEXT NOT NULL,
  product_id TEXT NOT NULL,
  -- Quantidade abatida do lote, em MILÉSIMOS de unidade (W11).
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  UNIQUE (sale_id, lot_id)
);

ALTER TABLE public.sale_lot_consumption ENABLE ROW LEVEL SECURITY;

-- Políticas: idem sale_items — sem store_id; o acesso vem do pai
-- (`sales.store_id`) via subconsulta. Escrita direta só pelas RPCs
-- (SECURITY DEFINER — RLS não se aplica dentro delas); as políticas são
-- defesa para acesso direto ao PostgREST.
DROP POLICY IF EXISTS sale_lot_consumption_select ON public.sale_lot_consumption;
CREATE POLICY sale_lot_consumption_select ON public.sale_lot_consumption
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_lot_consumption.sale_id
        AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_lot_consumption_insert ON public.sale_lot_consumption;
CREATE POLICY sale_lot_consumption_insert ON public.sale_lot_consumption
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_lot_consumption.sale_id
        AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_lot_consumption_update ON public.sale_lot_consumption;
CREATE POLICY sale_lot_consumption_update ON public.sale_lot_consumption
  FOR UPDATE USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_lot_consumption.sale_id
        AND public.is_my_store(s.store_id)
    )
  ) WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_lot_consumption.sale_id
        AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_lot_consumption_delete ON public.sale_lot_consumption;
-- DELETE só de registros PRÓPRIOS (o app não exclui nada).
CREATE POLICY sale_lot_consumption_delete ON public.sale_lot_consumption
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_sale_lot_consumption_sale
  ON public.sale_lot_consumption (sale_id);

DROP TRIGGER IF EXISTS trg_sale_lot_consumption_user_id
  ON public.sale_lot_consumption;
CREATE TRIGGER trg_sale_lot_consumption_user_id
  BEFORE INSERT ON public.sale_lot_consumption
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- 23.3 RPC cancel_sale — estorno completo em UMA transação
-- (guarda gerencial is_manager_of_store: apenas dono ou gerente anulam).
CREATE OR REPLACE FUNCTION public.cancel_sale(p_sale_id text, p_store_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_total bigint;
  v_method text;
  v_status text;
  v_lang text;
  v_consumption record;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para anular a venda.';
  END IF;
  -- Guarda GERENCIAL (matriz de acesso): anular venda é operação de
  -- gestão — dono ou gerente. O funcionário comum NÃO anula, mesmo por
  -- fora do app (o servidor é a autoridade).
  IF NOT public.is_manager_of_store(p_store_id) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem anular vendas na loja %.',
      p_store_id;
  END IF;
  -- Idioma do tenant (descrição/categoria do estorno — padrão pt).
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = p_store_id;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en', 'fr') THEN
    v_lang := 'pt';
  END IF;
  -- Lê e trava a venda (escopo por loja). Idempotência: venda já anulada
  -- ou inexistente é no-op.
  SELECT total_amount, payment_method, status INTO v_total, v_method, v_status
  FROM public.sales
  WHERE id = p_sale_id AND store_id = p_store_id
  FOR UPDATE;
  IF NOT FOUND OR v_total IS NULL THEN
    RETURN;
  END IF;
  IF v_status = 'cancelled' THEN
    RETURN;
  END IF;

  -- Devolve o estoque aos lotes EXATOS consumidos pela venda. Cada lote é
  -- travado FOR UPDATE (fecha corrida com outras operações) e o total do
  -- produto (stock_quantity) sobe na quantidade devolvida — a invariante
  -- `stock = Σ lotes` nunca quebra.
  FOR v_consumption IN
    SELECT c.lot_id, c.product_id, c.quantity
    FROM public.sale_lot_consumption c
    WHERE c.sale_id = p_sale_id
    ORDER BY c.id
    FOR UPDATE
  LOOP
    UPDATE public.stock_lots
      SET current_quantity = current_quantity + v_consumption.quantity
      WHERE id = v_consumption.lot_id AND store_id = p_store_id;
    UPDATE public.products
      SET stock_quantity = stock_quantity + v_consumption.quantity
      WHERE id = v_consumption.product_id AND store_id = p_store_id;
  END LOOP;

  -- Estorno no caixa: saída no valor da venda, categoria de vendas — o
  -- par (entrada original + estorno) fecha o caixa em zero.
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || p_sale_id || '_rev', v_uid, p_store_id,
          CASE v_lang WHEN 'en' THEN 'Sale reversal — '
                      WHEN 'fr' THEN 'Annulation de vente — '
                      ELSE 'Estorno de venda — ' END
            || public.payment_method_label(v_method, v_lang),
          v_total, 'expense',
          CASE v_lang WHEN 'en' THEN 'Sales' WHEN 'fr' THEN 'Ventes'
                      ELSE 'Vendas' END,
          now(), 'paid');

  -- Marca a venda como anulada (permanece no histórico).
  UPDATE public.sales
     SET status = 'cancelled', cancelled_at = now()
   WHERE id = p_sale_id AND store_id = p_store_id;
END;
$$;

-- ============================================================================
-- 24. EDIÇÃO DE PRODUTO: produto inativo (is_active) + ajuste manual de
--     estoque (adjust_product_stock)
-- ============================================================================
-- O produto ganhou `is_active` (desativado = some do PDV e das compras,
-- mas permanece no histórico com estoque preservado) e o AJUSTE MANUAL de
-- estoque (contagem física/quebra) define a quantidade absoluta
-- criando/consumindo LOTES FIFO em UMA transação. Idempotente e
-- reexecutável (ADD COLUMN IF NOT EXISTS + CREATE OR REPLACE).
-- ============================================================================

-- 24.1 Coluna is_active em products (DEFAULT TRUE — produtos existentes
-- permanecem ativos; idempotente para bases novas que já criam no CREATE
-- TABLE do schema.sql).
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 24.2 lock_products_or_raise com guarda de produto INATIVO: desativado
-- não pode ser VENDIDO nem REPOSTO (process_sale/process_purchase). Só
-- existe no schema.sql — recriada AQUI para as bases live ganharem a
-- versão nova (CREATE OR REPLACE). A ordem dos erros é preservada
-- (inexistente → desativado → estoque).
CREATE OR REPLACE FUNCTION public.lock_products_or_raise(
  p_items jsonb,
  p_store text,
  p_require_stock boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item jsonb;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    -- Existe? (trava a linha — fecha corrida com exclusão/edição)
    PERFORM 1 FROM public.products
      WHERE id = (v_item->>'product_id') AND store_id = p_store
      FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Produto % não existe no catálogo da loja %.',
        v_item->>'product_id', p_store;
    END IF;
    -- Produto DESATIVADO não pode ser vendido nem reposto.
    PERFORM 1 FROM public.products
      WHERE id = (v_item->>'product_id') AND store_id = p_store
        AND is_active;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'O produto % está desativado na loja %.',
        v_item->>'product_id', p_store;
    END IF;
    -- Estoque suficiente (apenas quando a operação baixa estoque).
    IF p_require_stock THEN
      PERFORM 1 FROM public.products
        WHERE id = (v_item->>'product_id') AND store_id = p_store
          AND stock_quantity >= (v_item->>'quantity')::int;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Estoque insuficiente para o produto % (loja %).',
          v_item->>'product_id', p_store;
      END IF;
    END IF;
  END LOOP;
END;
$$;

-- 24.3 RPC adjust_product_stock — ajuste manual em UMA transação (guarda
-- GERENCIAL is_manager_of_store: apenas dono/gerente ajustam estoque;
-- funcionário comum NÃO, mesmo por fora do app). AUMENTO cria lote novo
-- (sem validade, custo = preço de compra atual); REDUÇÃO abate em ordem
-- FIFO (validade mais próxima primeiro); IGUAL é no-op (idempotente). A
-- invariante `stock = Σ lotes` nunca quebra.
CREATE OR REPLACE FUNCTION public.adjust_product_stock(
  p_product_id TEXT,
  p_store_id TEXT,
  p_new_quantity BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_current bigint;
  v_cost bigint;
  v_delta bigint;
  v_remaining bigint;
  v_lot record;
  v_take bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para ajustar o estoque.';
  END IF;
  IF NOT public.is_manager_of_store(p_store_id) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem ajustar o estoque na loja %.',
      p_store_id;
  END IF;
  IF p_new_quantity < 0 THEN
    RAISE EXCEPTION 'O estoque não pode ficar negativo.';
  END IF;

  -- Trava o produto (fecha corrida) e lê estoque atual + custo do catálogo.
  SELECT stock_quantity, purchase_price INTO v_current, v_cost
  FROM public.products
  WHERE id = p_product_id AND store_id = p_store_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Produto % não existe no catálogo da loja %.',
      p_product_id, p_store_id;
  END IF;

  v_delta := p_new_quantity - v_current;
  IF v_delta = 0 THEN
    RETURN; -- idempotente: retry após sucesso é no-op
  END IF;

  IF v_delta > 0 THEN
    -- Ajuste para CIMA: lote novo (sem validade — FIFO por data de
    -- entrada; custo = preço de compra atual do catálogo).
    INSERT INTO public.stock_lots
      (id, store_id, product_id, entry_date, expiry_date,
       initial_quantity, current_quantity, cost_price)
    VALUES ('lot-adjust-' || p_product_id || '-' || gen_random_uuid()::text,
            p_store_id, p_product_id, now(), NULL,
            v_delta, v_delta, v_cost);
  ELSE
    -- Ajuste para BAIXO: abate dos lotes em ordem FIFO (validade mais
    -- próxima primeiro; sem validade por data de entrada). Cada lote é
    -- travado FOR UPDATE — a invariante `stock = Σ lotes` nunca quebra.
    v_remaining := -v_delta;
    FOR v_lot IN
      SELECT l.id, l.current_quantity
      FROM public.stock_lots l
      WHERE l.product_id = p_product_id AND l.store_id = p_store_id
        AND l.current_quantity > 0
      ORDER BY l.expiry_date ASC NULLS LAST, l.entry_date ASC, l.id ASC
      FOR UPDATE
    LOOP
      IF v_remaining <= 0 THEN EXIT; END IF;
      v_take := LEAST(v_lot.current_quantity, v_remaining);
      UPDATE public.stock_lots
        SET current_quantity = current_quantity - v_take
        WHERE id = v_lot.id AND store_id = p_store_id;
      v_remaining := v_remaining - v_take;
    END LOOP;
    IF v_remaining > 0 THEN
      -- Defesa em profundidade: os lotes não cobrem o ajuste — a
      -- invariante foi quebrada por fora; aborta sem mutar nada.
      RAISE EXCEPTION 'Estoque insuficiente para ajustar o produto % (loja %).',
        p_product_id, p_store_id;
    END IF;
  END IF;

  -- Define a quantidade ABSOLUTA nova (produto + lotes na mesma transação).
  UPDATE public.products
    SET stock_quantity = p_new_quantity
    WHERE id = p_product_id AND store_id = p_store_id;
END;
$$;

-- ============================================================================
-- 25. FECHO DE CAIXA DIÁRIO (Z-report) — cash_closings + close_cash_register
-- ============================================================================
-- O fecho do dia da loja (Z-report) registra o snapshot do dia: total de
-- vendas ativas (todas as formas), o ESPERADO na gaveta (Σ das vendas
-- ATIVAS pagas em DINHEIRO — cartão/M-Pesa/E-Mola/transferência não
-- passam pela gaveta física), a contagem física do usuário e a abertura
-- por forma de pagamento (JSONB). Um fecho por loja por dia (unicidade
-- store_id + closing_date — refazer o fecho do dia atualiza a contagem,
-- nunca duplica). Operação GERENCIAL (dono/gerente): o RPC valida
-- is_manager_of_store. Idempotente e reexecutável (CREATE TABLE IF NOT
-- EXISTS, ADD COLUMN IF NOT EXISTS, DROP POLICY IF EXISTS + CREATE
-- POLICY, DROP TRIGGER IF EXISTS + CREATE TRIGGER, CREATE OR REPLACE
-- FUNCTION).
-- ============================================================================

-- 25.1 Tabela cash_closings (bases novas já criam no schema.sql; aqui é
-- idempotente para qualquer base).
CREATE TABLE IF NOT EXISTS public.cash_closings (
  id               TEXT PRIMARY KEY,
  user_id          UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id         TEXT NOT NULL DEFAULT 'st1',
  closing_date     TIMESTAMPTZ NOT NULL,
  total_sales      BIGINT NOT NULL CHECK (total_sales >= 0),
  expected_cash    BIGINT NOT NULL CHECK (expected_cash >= 0),
  counted_cash     BIGINT NOT NULL CHECK (counted_cash >= 0),
  sales_by_method  JSONB NOT NULL DEFAULT '{}'::jsonb,
  closed_at        TIMESTAMPTZ NOT NULL,
  UNIQUE (store_id, closing_date)
);

-- 25.2 RLS: leitura para dono/funcionários da loja (histórico de fechos);
-- escrita via RPC (SECURITY DEFINER, guarda gerencial). INSERT exige loja
-- própria; UPDATE/DELETE só de registros PRÓPRIOS (defesa em profundidade).
ALTER TABLE public.cash_closings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cash_closings_select ON public.cash_closings;
CREATE POLICY cash_closings_select ON public.cash_closings
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS cash_closings_insert ON public.cash_closings;
CREATE POLICY cash_closings_insert ON public.cash_closings
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS cash_closings_update ON public.cash_closings;
CREATE POLICY cash_closings_update ON public.cash_closings
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS cash_closings_delete ON public.cash_closings;
CREATE POLICY cash_closings_delete ON public.cash_closings
  FOR DELETE USING (auth.uid() = user_id);

-- 25.3 Índice de varredura por loja (histórico + fecho do dia).
CREATE INDEX IF NOT EXISTS idx_cash_closings_store
  ON public.cash_closings (store_id);

-- 25.4 Triggers de user_id/store_id (mesmos helpers do restante do schema).
DROP TRIGGER IF EXISTS trg_cash_closings_user_id ON public.cash_closings;
CREATE TRIGGER trg_cash_closings_user_id
  BEFORE INSERT ON public.cash_closings
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_cash_closings_store_id ON public.cash_closings;
CREATE TRIGGER trg_cash_closings_store_id
  BEFORE INSERT ON public.cash_closings
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- 25.5 RPC close_cash_register — fecha (ou refaz) o dia da loja em UMA
-- transação: guarda gerencial, cálculo NO SERVIDOR do esperado/total/
-- abertura por forma, e UPSERT por (store_id, closing_date). O cliente
-- NUNCA envia valores calculados — o servidor é a autoridade.
CREATE OR REPLACE FUNCTION public.close_cash_register(
  p_store_id TEXT,
  p_day TIMESTAMPTZ,
  p_counted_cash_cents BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_day_start timestamptz;
  v_day_end timestamptz;
  v_total_sales bigint;
  v_expected_cash bigint;
  v_by_method jsonb;
  v_id text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para fechar o caixa.';
  END IF;
  IF NOT public.is_manager_of_store(p_store_id) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem fechar o caixa da loja %.', p_store_id;
  END IF;
  IF p_counted_cash_cents < 0 THEN
    RAISE EXCEPTION 'A contagem física não pode ser negativa.';
  END IF;

  -- Janela do dia no fuso local do cliente (p_day chega como início do
  -- dia LOCAL em UTC). Vendas anuladas ficam de fora (o estorno já
  -- ajustou o caixa — mesmo critério dos relatórios e KPIs).
  v_day_start := p_day;
  v_day_end := p_day + interval '1 day';

  SELECT COALESCE(SUM(s.total_amount), 0)::bigint
  INTO v_total_sales
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.date_time >= v_day_start AND s.date_time < v_day_end;

  SELECT COALESCE(SUM(s.total_amount), 0)::bigint
  INTO v_expected_cash
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.payment_method = 'cash'
    AND s.date_time >= v_day_start AND s.date_time < v_day_end;

  -- Abertura por forma de pagamento (relatório Z).
  SELECT COALESCE(jsonb_object_agg(s.payment_method, s.total), '{}'::jsonb)
  INTO v_by_method
  FROM (
    SELECT s.payment_method, SUM(s.total_amount)::bigint AS total
    FROM public.sales s
    WHERE s.store_id = p_store_id
      AND s.status = 'active'
      AND s.date_time >= v_day_start AND s.date_time < v_day_end
    GROUP BY s.payment_method
  ) s;

  -- UPSERT por (store_id, closing_date): refazer o fecho do dia atualiza
  -- a contagem física (e os snapshots), sem duplicar.
  v_id := 'cc-' || p_store_id || '-' || to_char(v_day_start, 'YYYYMMDD');
  INSERT INTO public.cash_closings
    (id, user_id, store_id, closing_date, total_sales, expected_cash,
     counted_cash, sales_by_method, closed_at)
  VALUES
    (v_id, v_uid, p_store_id, v_day_start, v_total_sales, v_expected_cash,
     p_counted_cash_cents, v_by_method, now())
  ON CONFLICT (store_id, closing_date) DO UPDATE SET
    id = EXCLUDED.id,
    total_sales = EXCLUDED.total_sales,
    expected_cash = EXCLUDED.expected_cash,
    counted_cash = EXCLUDED.counted_cash,
    sales_by_method = EXCLUDED.sales_by_method,
    closed_at = EXCLUDED.closed_at;

  RETURN jsonb_build_object(
    'id', v_id,
    'store_id', p_store_id,
    'closing_date', v_day_start,
    'total_sales', v_total_sales,
    'expected_cash', v_expected_cash,
    'counted_cash', p_counted_cash_cents,
    'sales_by_method', v_by_method,
    'closed_at', now()
  );
END;
$$;

-- ============================================================================
-- 26. PRÉVIA DO FECHO DE CAIXA NO SERVIDOR (get_cash_closing_summary, H2)
-- ============================================================================
-- Mesmo critério da RPC close_cash_register, só de LEITURA: o resumo do
-- dia para a pré-visualização do Z-report é agregado NO SERVIDOR (UMA
-- chamada) — total de vendas ativas, esperado na gaveta (só dinheiro) e
-- abertura por forma — além do fecho já registrado, evitando carregar o
-- histórico inteiro de vendas no cliente (escala H2, mesmo padrão de
-- get_cash_flow/get_sales_report). Guarda is_my_store. Idempotente
-- (CREATE OR REPLACE FUNCTION).
-- ============================================================================

-- 26.1 RPC get_cash_closing_summary — prévia agregada server-side.
CREATE OR REPLACE FUNCTION public.get_cash_closing_summary(
  p_store_id TEXT,
  p_day TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_day_start timestamptz;
  v_day_end timestamptz;
  v_total_sales bigint;
  v_expected_cash bigint;
  v_by_method jsonb;
  v_existing jsonb;
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Acesso negado a esta loja.';
  END IF;

  v_day_start := p_day;
  v_day_end := p_day + interval '1 day';

  SELECT COALESCE(SUM(s.total_amount), 0)::bigint
  INTO v_total_sales
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.date_time >= v_day_start AND s.date_time < v_day_end;

  SELECT COALESCE(SUM(s.total_amount), 0)::bigint
  INTO v_expected_cash
  FROM public.sales s
  WHERE s.store_id = p_store_id
    AND s.status = 'active'
    AND s.payment_method = 'cash'
    AND s.date_time >= v_day_start AND s.date_time < v_day_end;

  SELECT COALESCE(jsonb_object_agg(s.payment_method, s.total), '{}'::jsonb)
  INTO v_by_method
  FROM (
    SELECT s.payment_method, SUM(s.total_amount)::bigint AS total
    FROM public.sales s
    WHERE s.store_id = p_store_id
      AND s.status = 'active'
      AND s.date_time >= v_day_start AND s.date_time < v_day_end
    GROUP BY s.payment_method
  ) s;

  -- Fecho já registrado do dia (null = dia ainda aberto).
  SELECT jsonb_build_object(
    'id', c.id,
    'closing_date', c.closing_date,
    'total_sales', c.total_sales,
    'expected_cash', c.expected_cash,
    'counted_cash', c.counted_cash,
    'sales_by_method', c.sales_by_method,
    'closed_at', c.closed_at
  )
  INTO v_existing
  FROM public.cash_closings c
  WHERE c.store_id = p_store_id AND c.closing_date = v_day_start;

  RETURN jsonb_build_object(
    'day', v_day_start,
    'total_sales_cents', v_total_sales,
    'expected_cash_cents', v_expected_cash,
    'sales_by_method_cents', v_by_method,
    'existing_closing', v_existing
  );
END;
$$;

-- ============================================================================
-- 27. FOTOS DE PRODUTO — Supabase Storage (image_path + bucket + políticas)
-- ============================================================================
-- O app capta/atende a foto do produto e a sobe para o bucket PÚBLICO
-- `product-images` no caminho `<storeId>/<produto>.jpg` (o PRIMEIRO
-- segmento É o store_id — as políticas de escrita abaixo comparam
-- `is_my_store((storage.foldername(name))[1])`; um prefixo tipo
-- `products/...` faria a guarda comparar 'products' e negar o upload). A
-- URL pública é gravada em products.image_path — o banco relacional NUNCA
-- guarda o blob. 100% idempotente: coluna usa ADD COLUMN IF NOT EXISTS,
-- bucket usa ON CONFLICT (id) DO NOTHING e políticas usam DROP POLICY IF
-- EXISTS + CREATE. As políticas de ESCRITA usam a MESMA guarda is_my_store
-- das RPCs (Parte 3 — o servidor é a autoridade; um cliente adulterado
-- não sobe foto em pasta de outra loja). A leitura é pública (URL via CDN).
-- ============================================================================

-- 27.1 Coluna image_path em products (opcional; vazio = sem foto).
-- Espelha o CREATE TABLE do schema.sql (TEXT, nullable, sem DEFAULT —
-- linhas existentes ficam NULL e a UI mostra o ícone de fallback).
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS image_path TEXT;

-- 27.2 Bucket público de imagens (no-op se já existir).
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 27.3 Políticas de acesso ao storage (DROP + CREATE — reexecutável).
DROP POLICY IF EXISTS product_images_public_read ON storage.objects;
CREATE POLICY product_images_public_read ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS product_images_auth_insert ON storage.objects;
CREATE POLICY product_images_auth_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

DROP POLICY IF EXISTS product_images_auth_update ON storage.objects;
CREATE POLICY product_images_auth_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

DROP POLICY IF EXISTS product_images_auth_delete ON storage.objects;
CREATE POLICY product_images_auth_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

-- ============================================================================
-- Parte 20 — Campos de faturação na tabela stores
-- ============================================================================
-- Adiciona phone, email, nuit e city à tabela stores para suportar
-- faturação com dados completos da loja.
-- Data: 2026-08-25
-- ============================================================================

-- Adicionar colunas (idempotente: IF NOT EXISTS)
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS phone  TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS email  TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS nuit   TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS city   TEXT NOT NULL DEFAULT '';

-- Comentários nas colunas (documentação)
COMMENT ON COLUMN public.stores.phone IS 'Telefone de contacto da loja';
COMMENT ON COLUMN public.stores.email IS 'E-mail de contacto da loja';
COMMENT ON COLUMN public.stores.nuit  IS 'Número de Identificação Única de Contribuinte (NUIT)';
COMMENT ON COLUMN public.stores.city  IS 'Cidade onde se situa a loja';

-- ============================================================================
-- PARTE 31 — ADD-ONS, FATURAÇÃO (billing) E MENSAGENS ADMIN [consolidada]
-- ============================================================================
-- Migrações 20260902–20260905 (add-ons) e 020/021/023 (billing + mensagens)
-- consolidadas numa única parte IDEMPOTENTE para bases EXISTENTES. Uma
-- instalação NOVA já recebe estes objetos pelo `schema.sql` (PARTE 1.9) —
-- os arquivos originais das migrações foram arquivados em
-- `supabase/archived_migrations/` (auditoria Set/2026: 13 SQL → 2).
--
-- Conteúdo: tenant_addons, custom_invoices, quotations, employee_mgmt
-- (ponto/comissões/metas + RPC de comissões), invoices + billing (ciclo
-- mensal com trial de 14 dias) e admin_messages.
--
-- Idempotente: CREATE TABLE IF NOT EXISTS, ADD COLUMN IF NOT EXISTS,
-- DROP POLICY IF EXISTS + CREATE POLICY, DROP TRIGGER IF EXISTS + CREATE
-- TRIGGER, CREATE OR REPLACE FUNCTION, Realtime com guarda
-- pg_publication_tables (PostgreSQL puro = no-op). Pode ser reexecutado
-- à vontade (aplicação dupla validada pelo scripts/sql_check.sh).
-- ============================================================================


-- ---------------------------------------------------------------
-- 1.9.1 tenant_addons — add-ons contratados por tenant
-- ---------------------------------------------------------------
-- Cada linha é um add-on ativo (factura personalizada, cotação etc.)
-- contratado além do plano base. Um tenant tem NO MÁXIMO UMA ativação por
-- add-on (UNIQUE). RLS: dono gerencia os seus; super admin gerencia todos
-- (sem essa política, o painel admin não consegue ativar add-ons).
CREATE TABLE IF NOT EXISTS public.tenant_addons (
  id            TEXT DEFAULT ('ao_' || substr(md5(random()::text), 1, 12)) PRIMARY KEY,
  tenant_id     TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  add_on_id     TEXT NOT NULL,  -- ID do catálogo (ex.: ao_custom_invoice)
  activated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ,    -- NULL = sem expiração (assinatura mensal recorrente)
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_tenant_addon UNIQUE (tenant_id, add_on_id)
);

CREATE INDEX IF NOT EXISTS idx_tenant_addons_tenant_id
  ON public.tenant_addons (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_addons_active
  ON public.tenant_addons (tenant_id, is_active);

ALTER TABLE public.tenant_addons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_addons_select_own ON public.tenant_addons;
CREATE POLICY tenant_addons_select_own
  ON public.tenant_addons
  FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS tenant_addons_insert_own ON public.tenant_addons;
CREATE POLICY tenant_addons_insert_own
  ON public.tenant_addons
  FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS tenant_addons_update_own ON public.tenant_addons;
CREATE POLICY tenant_addons_update_own
  ON public.tenant_addons
  FOR UPDATE
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS tenant_addons_delete_own ON public.tenant_addons;
CREATE POLICY tenant_addons_delete_own
  ON public.tenant_addons
  FOR DELETE
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS tenant_addons_super_admin_all ON public.tenant_addons;
CREATE POLICY tenant_addons_super_admin_all
  ON public.tenant_addons
  FOR ALL
  USING (
    auth.uid() IN (SELECT user_id FROM public.super_admins)
  )
  WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.super_admins)
  );

-- ---------------------------------------------------------------
-- 1.9.2 custom_invoices — facturas personalizadas (add-on ao_custom_invoice)
-- ---------------------------------------------------------------
-- Documento por loja com número sequencial DENTRO da loja (MAX+1 sob
-- advisory lock). O corpo completo (items snapshot, descontos, notas,
-- pagamento) é JSONB: a factura é um documento, não um agregado com RPCs
-- de dinheiro. RLS: dono + funcionários da loja via is_my_store; DELETE
-- só de registros PRÓPRIOS (o app não apaga — zero impacto).
CREATE TABLE IF NOT EXISTS public.custom_invoices (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL,
  invoice_number BIGINT NOT NULL DEFAULT 0,
  payload        JSONB NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_custom_invoices_store_number UNIQUE (store_id, invoice_number)
);

CREATE INDEX IF NOT EXISTS idx_custom_invoices_store
  ON public.custom_invoices (store_id, created_at DESC);

-- user_id = usuário logado (reforço anti-forja — função da seção 1.x).
DROP TRIGGER IF EXISTS trg_custom_invoices_user_id
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_user_id
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- store_id = loja do usuário (anti-forja — função da seção 1.x).
DROP TRIGGER IF EXISTS trg_custom_invoices_store_id
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_store_id
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- Número sequencial por loja com advisory lock (duas escritas concorrentes
-- nunca recebem o mesmo número). Número 0 = atribuir; já preenchido
-- (restauração) é preservado.
CREATE OR REPLACE FUNCTION public.get_next_custom_invoice_number(
  p_store_id TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext('custom_invoice_number'),
    hashtext(p_store_id)
  );

  SELECT COALESCE(MAX(invoice_number), 0) + 1
  INTO v_next
  FROM public.custom_invoices
  WHERE store_id = p_store_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_custom_invoice_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.invoice_number = 0 THEN
    NEW.invoice_number := public.get_next_custom_invoice_number(NEW.store_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_custom_invoices_number
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_number
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_custom_invoice_number();

ALTER TABLE public.custom_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS custom_invoices_select ON public.custom_invoices;
CREATE POLICY custom_invoices_select ON public.custom_invoices
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS custom_invoices_insert ON public.custom_invoices;
CREATE POLICY custom_invoices_insert ON public.custom_invoices
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS custom_invoices_delete ON public.custom_invoices;
CREATE POLICY custom_invoices_delete ON public.custom_invoices
  FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 1.9.3 quotations — cotações/orçamentos (add-on ao_quotation)
-- ---------------------------------------------------------------
-- Mesmo padrão das facturas personalizadas: documento JSONB por loja com
-- número sequencial sob advisory lock. UPDATE é necessário para as
-- transições de estado (rascunho → enviada → aceite/rejeitada); DELETE só
-- de registros PRÓPRIOS.
CREATE TABLE IF NOT EXISTS public.quotations (
  id                TEXT PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id          TEXT NOT NULL,
  quotation_number  BIGINT NOT NULL DEFAULT 0,
  payload           JSONB NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_quotations_store_number UNIQUE (store_id, quotation_number)
);

CREATE INDEX IF NOT EXISTS idx_quotations_store
  ON public.quotations (store_id, created_at DESC);

DROP TRIGGER IF EXISTS trg_quotations_user_id ON public.quotations;
CREATE TRIGGER trg_quotations_user_id
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_quotations_store_id ON public.quotations;
CREATE TRIGGER trg_quotations_store_id
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

CREATE OR REPLACE FUNCTION public.get_next_quotation_number(
  p_store_id TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext('quotation_number'),
    hashtext(p_store_id)
  );

  SELECT COALESCE(MAX(quotation_number), 0) + 1
  INTO v_next
  FROM public.quotations
  WHERE store_id = p_store_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_quotation_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.quotation_number = 0 THEN
    NEW.quotation_number := public.get_next_quotation_number(NEW.store_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_quotations_number ON public.quotations;
CREATE TRIGGER trg_quotations_number
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_quotation_number();

ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS quotations_select ON public.quotations;
CREATE POLICY quotations_select ON public.quotations
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_insert ON public.quotations;
CREATE POLICY quotations_insert ON public.quotations
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_update ON public.quotations;
CREATE POLICY quotations_update ON public.quotations
  FOR UPDATE USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_delete ON public.quotations;
CREATE POLICY quotations_delete ON public.quotations
  FOR DELETE USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 1.9.4 employee_mgmt — ponto, comissões e metas (add-on ao_employee_mgmt)
-- ---------------------------------------------------------------
-- Três tabelas por loja + UMA RPC de agregação:
--   employee_attendance       — ponto: UMA linha por funcionário por dia
--                               (entrada insere, saída atualiza a MESMA
--                               linha; clock_out NULL = presente);
--   employee_commission_rates — taxa de comissão em PONTOS BASE
--                               (500 = 5%) — inteiro, sem floats;
--   employee_targets          — meta mensal de vendas (month = 'YYYY-MM').
-- COMISSÕES NUNCA SÃO ARMAZENADAS: a RPC calcula das VENDAS REAIS
-- (sales.user_id = caixa, status 'active') × taxa cadastrada.

-- Guarda: o usuário é funcionário ATIVO da loja?
CREATE OR REPLACE FUNCTION public.is_store_employee_active(
  p_store_id TEXT,
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.store_employees e
    WHERE e.store_id = p_store_id
      AND e.user_id = p_user_id
      AND e.is_active = TRUE
  );
$$;

CREATE TABLE IF NOT EXISTS public.employee_attendance (
  id          TEXT PRIMARY KEY,
  -- SUJEITO: o funcionário (NÃO o actor — o dono registra pelo
  -- funcionário; por isso o trigger set_tenant_user_id NÃO é usado aqui).
  user_id     UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id    TEXT NOT NULL,
  -- Dia de trabalho 'YYYY-MM-DD' — chave de unicidade por funcionário.
  work_date   TEXT NOT NULL,
  clock_in    TIMESTAMPTZ NOT NULL,
  clock_out   TIMESTAMPTZ,
  -- ACTOR: quem executou a acção (auth.uid() pelo trigger abaixo).
  recorded_by UUID,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_employee_attendance_day
    UNIQUE (store_id, user_id, work_date)
);

CREATE INDEX IF NOT EXISTS idx_employee_attendance_store
  ON public.employee_attendance (store_id, work_date DESC);

-- recorded_by = usuário logado (ACTOR). NÃO usa set_tenant_user_id (que
-- forçaria user_id = auth.uid() e apagaria o SUJEITO).
CREATE OR REPLACE FUNCTION public.set_employee_attendance_actor()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.recorded_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_employee_attendance_recorded_by
  ON public.employee_attendance;
CREATE TRIGGER trg_employee_attendance_recorded_by
  BEFORE INSERT ON public.employee_attendance
  FOR EACH ROW EXECUTE FUNCTION public.set_employee_attendance_actor();

DROP TRIGGER IF EXISTS trg_employee_attendance_store_id
  ON public.employee_attendance;
CREATE TRIGGER trg_employee_attendance_store_id
  BEFORE INSERT ON public.employee_attendance
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

CREATE TABLE IF NOT EXISTS public.employee_commission_rates (
  id         TEXT PRIMARY KEY,
  store_id   TEXT NOT NULL,
  user_id    UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  rate_bps   INTEGER NOT NULL CHECK (rate_bps >= 0 AND rate_bps <= 10000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_employee_commission_rate UNIQUE (store_id, user_id)
);

DROP TRIGGER IF EXISTS trg_employee_rates_store_id
  ON public.employee_commission_rates;
CREATE TRIGGER trg_employee_rates_store_id
  BEFORE INSERT ON public.employee_commission_rates
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

CREATE TABLE IF NOT EXISTS public.employee_targets (
  id           TEXT PRIMARY KEY,
  store_id     TEXT NOT NULL,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  month        TEXT NOT NULL,
  target_cents BIGINT NOT NULL CHECK (target_cents >= 0),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_employee_target UNIQUE (store_id, user_id, month)
);

CREATE INDEX IF NOT EXISTS idx_employee_targets_store
  ON public.employee_targets (store_id, month);

DROP TRIGGER IF EXISTS trg_employee_targets_store_id
  ON public.employee_targets;
CREATE TRIGGER trg_employee_targets_store_id
  BEFORE INSERT ON public.employee_targets
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_commission_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_targets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS employee_attendance_select ON public.employee_attendance;
CREATE POLICY employee_attendance_select ON public.employee_attendance
  FOR SELECT USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_attendance_insert ON public.employee_attendance;
CREATE POLICY employee_attendance_insert ON public.employee_attendance
  FOR INSERT WITH CHECK (
    public.is_my_store(store_id)
    AND public.is_store_employee_active(store_id, user_id)
  );

DROP POLICY IF EXISTS employee_attendance_update ON public.employee_attendance;
CREATE POLICY employee_attendance_update ON public.employee_attendance
  FOR UPDATE USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_attendance_delete ON public.employee_attendance;
CREATE POLICY employee_attendance_delete ON public.employee_attendance
  FOR DELETE USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_rates_select ON public.employee_commission_rates;
CREATE POLICY employee_rates_select ON public.employee_commission_rates
  FOR SELECT USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_rates_insert ON public.employee_commission_rates;
CREATE POLICY employee_rates_insert ON public.employee_commission_rates
  FOR INSERT WITH CHECK (
    public.is_my_store(store_id)
    AND public.is_store_employee_active(store_id, user_id)
  );

DROP POLICY IF EXISTS employee_rates_update ON public.employee_commission_rates;
CREATE POLICY employee_rates_update ON public.employee_commission_rates
  FOR UPDATE USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_rates_delete ON public.employee_commission_rates;
CREATE POLICY employee_rates_delete ON public.employee_commission_rates
  FOR DELETE USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_targets_select ON public.employee_targets;
CREATE POLICY employee_targets_select ON public.employee_targets
  FOR SELECT USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_targets_insert ON public.employee_targets;
CREATE POLICY employee_targets_insert ON public.employee_targets
  FOR INSERT WITH CHECK (
    public.is_my_store(store_id)
    AND public.is_store_employee_active(store_id, user_id)
  );

DROP POLICY IF EXISTS employee_targets_update ON public.employee_targets;
CREATE POLICY employee_targets_update ON public.employee_targets
  FOR UPDATE USING (public.is_my_store(store_id));

DROP POLICY IF EXISTS employee_targets_delete ON public.employee_targets;
CREATE POLICY employee_targets_delete ON public.employee_targets
  FOR DELETE USING (public.is_my_store(store_id));

-- RPC: resumo de comissões CALCULADO das vendas reais — por funcionário
-- ATIVO da loja (0 bps = sem taxa → comissão 0). SECURITY DEFINER com
-- guarda is_my_store (mesmo padrão get_cash_flow/get_sales_report).
CREATE OR REPLACE FUNCTION public.get_employee_commission_summary(
  p_store_id TEXT,
  p_month TEXT
)
RETURNS TABLE (
  user_id          UUID,
  full_name        TEXT,
  sales_cents      BIGINT,
  rate_bps         INTEGER,
  commission_cents BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start TIMESTAMPTZ;
  v_end   TIMESTAMPTZ;
BEGIN
  IF NOT public.is_my_store(p_store_id) THEN
    RAISE EXCEPTION 'Loja não acessível';
  END IF;
  IF p_month !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Mês inválido (esperado YYYY-MM): %', p_month;
  END IF;

  v_start := to_timestamp(p_month || '-01', 'YYYY-MM-DD');
  v_end := v_start + interval '1 month';

  RETURN QUERY
  SELECT
    e.user_id,
    e.full_name,
    COALESCE(SUM(s.total_amount) FILTER (
      WHERE s.status = 'active'
    ), 0) AS sales_cents,
    COALESCE(r.rate_bps, 0) AS rate_bps,
    COALESCE(SUM(s.total_amount) FILTER (
      WHERE s.status = 'active'
    ), 0) * COALESCE(r.rate_bps, 0) / 10000 AS commission_cents
  FROM public.store_employees e
  LEFT JOIN public.sales s
    ON s.store_id = e.store_id
   AND s.user_id = e.user_id
   AND s.date_time >= v_start
   AND s.date_time < v_end
  LEFT JOIN public.employee_commission_rates r
    ON r.store_id = e.store_id
   AND r.user_id = e.user_id
  WHERE e.store_id = p_store_id
    AND e.is_active = TRUE
  GROUP BY e.user_id, e.full_name, r.rate_bps
  ORDER BY commission_cents DESC;
END;
$$;

-- ---------------------------------------------------------------
-- 1.9.5 invoices + billing — cobrança mensal e notificações (021)
-- ---------------------------------------------------------------
-- Ciclo de facturação: `plan_expires_at` = expiração do plano atual
-- (renovação mensal a partir de approved_at; trial = 14 dias);
-- `next_invoice_at` = data em que a próxima factura deve ser gerada
-- (7 dias antes da expiração).
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS plan_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS next_invoice_at TIMESTAMPTZ;

COMMENT ON COLUMN public.tenants.plan_expires_at
  IS 'Data de expiração do plano actual (renovação mensal a partir de approved_at). Trial: 14 dias.';
COMMENT ON COLUMN public.tenants.next_invoice_at
  IS 'Data em que a próxima factura de renovação deve ser gerada (7 dias antes de plan_expires_at).';

-- Facturas de cobrança mensal (valor em CENTAVOS — mesma unidade do
-- plans.price_monthly). Super admin gerencia; o dono LÊ as suas.
CREATE TABLE IF NOT EXISTS public.invoices (
  id            TEXT PRIMARY KEY,
  number        BIGINT NOT NULL DEFAULT 0,
  tenant_id     TEXT NOT NULL REFERENCES public.tenants (id) ON DELETE CASCADE,
  plan_id       TEXT NOT NULL REFERENCES public.plans (id),
  amount_cents  BIGINT NOT NULL CHECK (amount_cents >= 0),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN
    ('pending', 'paid', 'expired', 'cancelled')),
  due_date      TIMESTAMPTZ NOT NULL,
  period        TEXT NOT NULL DEFAULT '',
  paid_at       TIMESTAMPTZ,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.invoices
  IS 'Facturas de cobrança geradas para renovação mensal do plano dos tenants.';
COMMENT ON COLUMN public.invoices.number
  IS 'Número sequencial da factura (INV-00001, INV-00002...)';
COMMENT ON COLUMN public.invoices.period
  IS 'Período que a factura cobre (ex.: "Janeiro 2026")';
COMMENT ON COLUMN public.invoices.amount_cents
  IS 'Valor em CENTAVOS inteiros (mesma unidade do Plan.price_monthly)';

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS invoices_super_admin_all ON public.invoices;
CREATE POLICY invoices_super_admin_all ON public.invoices
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS invoices_tenant_owner_select ON public.invoices;
CREATE POLICY invoices_tenant_owner_select ON public.invoices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenants t
      WHERE t.id = invoices.tenant_id
        AND t.owner_user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_invoices_tenant
  ON public.invoices (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_status
  ON public.invoices (status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_period
  ON public.invoices (tenant_id, period, status);

-- Número sequencial por tenant (advisory lock — sem duplicata).
CREATE OR REPLACE FUNCTION public.get_next_invoice_number(p_tenant_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext('invoice_number'),
    hashtext(p_tenant_id)
  );

  SELECT COALESCE(MAX(number), 0) + 1
  INTO v_next
  FROM public.invoices
  WHERE tenant_id = p_tenant_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_invoice_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.number = 0 THEN
    NEW.number := public.get_next_invoice_number(NEW.tenant_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_invoices_number ON public.invoices;
CREATE TRIGGER trg_invoices_number
  BEFORE INSERT ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_invoice_number();

-- Notificações in-app para o dono (factura gerada/paga/a expirar),
-- publicadas no Realtime para notificação instantânea.
CREATE TABLE IF NOT EXISTS public.invoice_notifications (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL REFERENCES public.tenants (id) ON DELETE CASCADE,
  invoice_id    TEXT REFERENCES public.invoices (id) ON DELETE SET NULL,
  type          TEXT NOT NULL CHECK (type IN
    ('invoiceGenerated', 'invoiceDueSoon', 'invoiceExpired', 'invoicePaid')),
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at       TIMESTAMPTZ
);

COMMENT ON TABLE public.invoice_notifications
  IS 'Notificações in-app para o dono do tenant sobre facturas.';
COMMENT ON COLUMN public.invoice_notifications.type
  IS 'Tipo: invoiceGenerated, invoiceDueSoon, invoiceExpired, invoicePaid';

ALTER TABLE public.invoice_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS invoice_notifications_super_admin_all
  ON public.invoice_notifications;
CREATE POLICY invoice_notifications_super_admin_all
  ON public.invoice_notifications
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS invoice_notifications_tenant_owner_all
  ON public.invoice_notifications;
CREATE POLICY invoice_notifications_tenant_owner_all
  ON public.invoice_notifications
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tenants t
      WHERE t.id = invoice_notifications.tenant_id
        AND t.owner_user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_invoice_notifications_tenant
  ON public.invoice_notifications (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_notifications_unread
  ON public.invoice_notifications (tenant_id)
  WHERE is_read = FALSE;

-- Realtime com guarda (PostgreSQL puro não tem a publicação — no-op).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'invoices'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.invoices;
  END IF;
END
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'invoice_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.invoice_notifications;
  END IF;
END
$$;

-- ---------------------------------------------------------------
-- 1.9.6 admin_messages — mensagens do super admin para tenants (023)
-- ---------------------------------------------------------------
-- Cotações, avisos de validade do plano e mensagens gerais. Super admin
-- gerencia; o dono lê as suas e marca como lidas. Realtime para
-- notificação instantânea (com guarda).
CREATE TABLE IF NOT EXISTS public.admin_messages (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN ('billingQuote', 'planExpiryChange', 'planExpiringSoon', 'general')),
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_admin_messages_tenant
  ON public.admin_messages (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_messages_unread
  ON public.admin_messages (tenant_id, is_read)
  WHERE is_read = FALSE;

ALTER TABLE public.admin_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_messages_super_admin_all ON public.admin_messages;
CREATE POLICY admin_messages_super_admin_all
  ON public.admin_messages
  FOR ALL
  USING (public.is_super_admin());

DROP POLICY IF EXISTS admin_messages_owner_read ON public.admin_messages;
CREATE POLICY admin_messages_owner_read
  ON public.admin_messages
  FOR SELECT
  USING (public.is_tenant_owner(tenant_id));

DROP POLICY IF EXISTS admin_messages_owner_update ON public.admin_messages;
CREATE POLICY admin_messages_owner_update
  ON public.admin_messages
  FOR UPDATE
  USING (public.is_tenant_owner(tenant_id))
  WITH CHECK (public.is_tenant_owner(tenant_id));

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'admin_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_messages;
  END IF;
END
$$;
