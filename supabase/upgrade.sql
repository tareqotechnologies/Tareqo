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
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'BRL',
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

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'tenants_language_check'
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_language_check
      CHECK (language IN ('pt', 'en'));
  END IF;
END $$;


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
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
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

  -- Venda + itens (snapshot de nome/preço).
  INSERT INTO public.sales
    (id, user_id, store_id, total_amount, payment_method, date_time)
  VALUES (p_sale->>'id', v_uid, v_store, v_total,
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
          CASE WHEN v_lang = 'en' THEN 'Sale — ' ELSE 'Venda ' END
            || public.payment_method_label(p_sale->>'payment_method', v_lang),
          v_total, 'income',
          CASE WHEN v_lang = 'en' THEN 'Sales' ELSE 'Vendas' END,
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
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
    v_lang := 'pt';
  END IF;
  IF (p_debt->>'amount')::bigint <= 0 THEN
    RAISE EXCEPTION 'O valor da dívida deve ser maior que zero.';
  END IF;
  -- Idempotência: retry após sucesso não duplica dívida nem pendência.
  IF EXISTS (SELECT 1 FROM public.debts WHERE id = p_debt->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;

  -- Dívida + pendência financeira vinculada em UMA transação.
  INSERT INTO public.debts
    (id, user_id, store_id, person_name, amount, due_date,
     is_customer_debt, is_paid, paid_at, customer_id)
  VALUES (p_debt->>'id', v_uid, v_store, p_debt->>'person_name',
          (p_debt->>'amount')::bigint, (p_debt->>'due_date')::timestamptz,
          v_customer_debt, FALSE, NULL, p_debt->>'customer_id');

  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
  VALUES ('t' || (p_debt->>'id'), v_uid, v_store,
          CASE WHEN v_lang = 'en' THEN
            CASE WHEN v_customer_debt
                 THEN 'Credit to receive — ' || (p_debt->>'person_name')
                 ELSE 'Credit to pay — ' || (p_debt->>'person_name') END
          ELSE
            CASE WHEN v_customer_debt
                 THEN 'Fiado a receber — ' || (p_debt->>'person_name')
                 ELSE 'Fiado a pagar — ' || (p_debt->>'person_name') END
          END,
          (p_debt->>'amount')::bigint,
          CASE WHEN v_customer_debt THEN 'income' ELSE 'expense' END,
          CASE WHEN v_lang = 'en' THEN 'Credit' ELSE 'Fiado' END,
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
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
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
            CASE WHEN v_lang = 'en'
                 THEN 'Credit received — ' || v_debt.person_name
                 ELSE 'Recebimento de fiado — ' || v_debt.person_name END,
            v_debt.amount, 'income',
            CASE WHEN v_lang = 'en' THEN 'Credit' ELSE 'Fiado' END,
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
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
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

  -- Compra + itens.
  INSERT INTO public.purchases
    (id, user_id, store_id, supplier_name, total_amount, date_time)
  VALUES (p_purchase->>'id', v_uid, v_store, p_purchase->>'supplier_name',
          v_total, (p_purchase->>'date_time')::timestamptz);

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
          CASE WHEN v_lang = 'en'
               THEN 'Purchase — ' || (p_purchase->>'supplier_name')
               ELSE 'Compra — ' || (p_purchase->>'supplier_name') END,
          v_total, 'expense',
          CASE WHEN v_lang = 'en' THEN 'Purchases' ELSE 'Compras' END,
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
    COALESCE((SELECT SUM(s.total_amount) FROM public.sales s
              WHERE s.store_id = p_store_id), 0)::bigint,
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
