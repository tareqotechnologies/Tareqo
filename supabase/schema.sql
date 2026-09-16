-- ============================================================================
-- Dumbhanengue ERP — Schema do banco no Supabase (PostgreSQL)
-- ============================================================================
-- Como usar:
--   1. Abra o SQL Editor do seu projeto:
--      https://supabase.com/dashboard/project/<SEU_REF>/sql/new
--   2. Cole TODO o script e execute (o comando "Run").
--   3. Idempotente: pode ser executado a qualquer momento. O ERP NÃO semeia
--      dados de demonstração: cada tenant começa vazio e registra apenas
--      dados reais (a única exceção é o catálogo de planos — PARTE 2).
--
-- ⚙️ CONSOLIDAÇÃO (Set/2026): este é o ÚNICO script de instalação nova —
--    PARTE 1 (estrutura + RLS + RPCs), PARTE 1.9 (add-ons: facturas
--    personalizadas, cotações, gestão de funcionários; billing: invoices +
--    notificações; mensagens admin) e PARTE 2 (catálogo de planos).
--    As 7 migrações originais foram arquivadas em `supabase/archived_migrations/`.
--    Bases EXISTENTES: usar `upgrade.sql` (PARTE 31 = mesmo conteúdo da 1.9).
--    Guia completo: docs/pt/19-supabase-producao-passo-a-passo.md.
--
-- O design segue o modelo multi-tenant documentado: cada tabela tem a coluna
-- `user_id` (vínculo com auth.users) e o RLS isola os dados por
-- `auth.uid() = user_id` — mesmo que a UI vaze dados, o banco os filtra.
-- Na Fase 2, cada registro de negócio também tem `store_id` (escopo por loja).
-- As chaves primárias são TEXT (mesmo formato usado pelo app: p1, s1, t1...).
--
-- ⚠️ O script inteiro roda em UMA transação (BEGIN … COMMIT): as FKs de
-- `store_id → public.stores` referenciam uma tabela criada mais adiante no
-- script (seção 1.6). O Postgres só valida FKs no COMMIT — sem a transação,
-- cada statement comitaria sozinho e a criação falharia. Idempotente: pode
-- reexecutar à vontade (tudo é IF NOT EXISTS / ON CONFLICT / DROP IF EXISTS).
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1 — ESTRUTURA (tabelas + RLS + políticas + índices)
-- ============================================================================

-- ---------------------------------------------------------------
-- 1.1 Tabelas
-- ---------------------------------------------------------------

-- Produtos (espelha a entidade Product) — store_id: cada loja tem seu
-- próprio estoque (Fase 2 do multi-tenancy). Sem FK para public.stores
-- (definida adiante no script); a integridade é garantida pelo trigger
-- anti-forja `set_record_store_id` + RLS.
CREATE TABLE IF NOT EXISTS public.products (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL DEFAULT 'st1',
  name           TEXT NOT NULL,
  description    TEXT NOT NULL DEFAULT '',
  -- W4: dinheiro em CENTAVOS inteiros (BIGINT) — sem fração de double.
  purchase_price BIGINT NOT NULL CHECK (purchase_price >= 0),
  sale_price     BIGINT NOT NULL CHECK (sale_price >= 0),
  -- W11: estoque em MILÉSIMOS de unidade (1000 = 1 unidade/kg) — inteiro
  -- exato, mesma filosofia dos centavos (W4).
  stock_quantity BIGINT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  -- W11: código de barras/PLU (até 5 dígitos, opcional) das balanças
  -- etiquetadoras; venda por PESO (fração) e unidade de venda.
  code TEXT,
  venda_por_fracao BOOLEAN NOT NULL DEFAULT FALSE,
  unit_label TEXT NOT NULL DEFAULT 'un',
  -- Produto ATIVO no catálogo (padrão). Desativado, some do PDV e das
  -- compras (lock_products_or_raise nega), mas permanece no histórico com
  -- o estoque preservado para a reativação.
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- Foto do produto (opcional): URL pública do Supabase Storage (modo
  -- SaaS) ou caminho de arquivo local (modo SQLite). Vazio = sem foto.
  image_path TEXT
);

-- Vendas (espelha a entidade Sale) — store_id: histórico por loja.
-- `sale_number` é o número SEQUENCIAL da venda dentro da loja (S-00001,
-- S-00002...): atribuído pelo RPC process_sale sob advisory lock por loja
-- (bases antigas recebem a coluna + backfill via upgrade.sql, Parte 14).
-- Unicidade (store_id, sale_number) garantida pelo índice uq_sales_store_number.
CREATE TABLE IF NOT EXISTS public.sales (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL DEFAULT 'st1',
  sale_number    BIGINT NOT NULL,
  total_amount   BIGINT NOT NULL CHECK (total_amount >= 0),
  -- Formas de pagamento (mercado-alvo Moçambique: dinheiro móvel
  -- M-Pesa/E-Mola no lugar do Pix BR). O nome do enum é o valor gravado.
  payment_method TEXT NOT NULL CHECK (payment_method IN
    ('cash', 'debitCard', 'creditCard', 'mPesa', 'eMola', 'transfer')),
  date_time      TIMESTAMPTZ NOT NULL,
  -- Anulação de venda (nível gerencial — dono/gerente): 'active' =
  -- venda normal; 'cancelled' = anulada (permanece no histórico como
  -- trilha, mas sai de relatórios/KPIs; o estoque volta aos lotes exatos
  -- e o caixa recebe um estorno). DEFAULT 'active' preserva vendas de
  -- bancos antigos (a coluna é adicionada via ALTER abaixo).
  status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN
    ('active', 'cancelled')),
  cancelled_at   TIMESTAMPTZ
);
-- Migração idempotente para bancos já criados (CREATE TABLE IF NOT EXISTS
-- não altera tabelas existentes): adiciona as colunas com defaults.
ALTER TABLE IF EXISTS public.sales
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE IF EXISTS public.sales
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Itens de venda (espelha a entidade SaleItem — snapshot de nome/preço)
CREATE TABLE IF NOT EXISTS public.sale_items (
  id           BIGSERIAL PRIMARY KEY,
  sale_id      TEXT NOT NULL REFERENCES public.sales (id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id   TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity > 0),
  unit_price   BIGINT NOT NULL CHECK (unit_price >= 0),
  UNIQUE (sale_id, product_id)
);

-- Consumo de LOTES por venda — registrado na MESMA transação do
-- process_sale (a baixa FIFO grava cada lote abatido e a quantidade).
-- Permite à anulação (cancel_sale) devolver o estoque aos lotes EXATOS
-- consumidos, preservando data de validade e custo de cada lote.
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

-- Movimentações financeiras (espelha a entidade FinancialTransaction) —
-- store_id: o caixa é por loja.
CREATE TABLE IF NOT EXISTS public.financial_transactions (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id    TEXT NOT NULL DEFAULT 'st1',
  description TEXT NOT NULL,
  amount      BIGINT NOT NULL CHECK (amount >= 0),
  type        TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category    TEXT NOT NULL,
  date        TIMESTAMPTZ NOT NULL,
  status      TEXT NOT NULL DEFAULT 'paid' CHECK (status IN ('paid', 'pending')),
  debt_id     TEXT
);

-- Fechos de caixa DIÁRIOS (Z-report — espelha a entidade CashClosing):
-- um fecho por loja por dia (unicidade store_id + closing_date). O
-- `expected_cash` é o que DEVERIA estar na gaveta — Σ das vendas ATIVAS
-- pagas em DINHEIRO no dia (cartão/M-Pesa/E-Mola/transferência não passam
-- pela gaveta física); o `counted_cash` é a contagem física do usuário; a
-- diferença (sobra/falta) é calculada na UI. `sales_by_method` guarda a
-- abertura por forma de pagamento (JSONB) para o relatório Z. Fecho é
-- operação GERENCIAL (dono/gerente) — o RPC close_cash_register valida
-- is_manager_of_store; as políticas de escrita permitem apenas INSERT do
-- próprio usuário/dono (o RPC SECURITY DEFINER persiste por fora do RLS).
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

-- Dívidas / "fiado" (espelha a entidade Debt)
-- (coluna customer_id adicionada também via ALTER para bancos já criados
--  antes do módulo de clientes — idempotente)
ALTER TABLE IF EXISTS public.debts
  ADD COLUMN IF NOT EXISTS customer_id TEXT;
-- `debt_number` é o número SEQUENCIAL da dívida dentro da loja (D-00001,
-- D-00002...): atribuído pelo RPC register_debt sob advisory lock por loja
-- (bases antigas recebem a coluna + backfill via upgrade.sql, Parte 16).
-- Unicidade (store_id, debt_number) garantida pelo índice
-- uq_debts_store_number.
ALTER TABLE IF EXISTS public.debts
  ADD COLUMN IF NOT EXISTS debt_number BIGINT;
CREATE TABLE IF NOT EXISTS public.debts (
  id              TEXT PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id        TEXT NOT NULL DEFAULT 'st1',
  debt_number     BIGINT NOT NULL,
  person_name     TEXT NOT NULL,
  amount          BIGINT NOT NULL CHECK (amount >= 0),
  due_date        TIMESTAMPTZ NOT NULL,
  is_customer_debt BOOLEAN NOT NULL,
  is_paid         BOOLEAN NOT NULL DEFAULT FALSE,
  paid_at         TIMESTAMPTZ,
  customer_id     TEXT
);

-- Clientes (espelha a entidade Customer) — store_id: clientes por loja.
CREATE TABLE IF NOT EXISTS public.customers (
  id      TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id TEXT NOT NULL DEFAULT 'st1',
  name    TEXT NOT NULL,
  phone   TEXT NOT NULL DEFAULT '',
  email   TEXT NOT NULL DEFAULT ''
);

-- Compras de fornecedores (espelha a entidade Purchase) — store_id: a
-- entrada de estoque é por loja.
-- `purchase_number` é o número SEQUENCIAL da compra dentro da loja
-- (C-00001, C-00002...): atribuído pelo RPC process_purchase sob advisory
-- lock por loja (bases antigas recebem a coluna + backfill via
-- upgrade.sql, Parte 15). Unicidade (store_id, purchase_number) garantida
-- pelo índice uq_purchases_store_number.
CREATE TABLE IF NOT EXISTS public.purchases (
  id              TEXT PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id        TEXT NOT NULL DEFAULT 'st1',
  purchase_number BIGINT NOT NULL,
  supplier_name   TEXT NOT NULL,
  total_amount    BIGINT NOT NULL CHECK (total_amount >= 0),
  -- Forma de pagamento do fornecedor (mesmo enum de vendas). O nome do
  -- enum é o valor gravado. DEFAULT 'cash': compras antigas não registravam
  -- o método — a migração (upgrade.sql, Parte 18) interpreta como à vista.
  payment_method  TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN
    ('cash', 'debitCard', 'creditCard', 'mPesa', 'eMola', 'transfer')),
  date_time       TIMESTAMPTZ NOT NULL
);

-- Itens de compra (espelha a entidade PurchaseItem — snapshot de nome/preço)
CREATE TABLE IF NOT EXISTS public.purchase_items (
  id           BIGSERIAL PRIMARY KEY,
  purchase_id  TEXT NOT NULL REFERENCES public.purchases (id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id   TEXT NOT NULL,
  product_name TEXT NOT NULL,
  -- W11: quantidade em MILÉSIMOS de unidade (1000 = 1 unidade/kg).
  quantity     INTEGER NOT NULL CHECK (quantity > 0),
  unit_price   BIGINT NOT NULL CHECK (unit_price >= 0),
  -- W11: data de VALIDADE do lote criado por este item (NULL = sem
  -- validade — FIFO por data de entrada).
  expiry_date  TIMESTAMPTZ,
  UNIQUE (purchase_id, product_id)
);

-- Lotes FIFO (W11 — espelha a entidade StockLot). Cada entrada de
-- mercadoria cria um lote; a baixa no PDV consome em ordem de validade
-- (mais próxima primeiro) e, sem validade, por data de entrada. A
-- `stock_quantity` do produto é SEMPRE a soma das `current_quantity` dos
-- lotes ativos (invariante do módulo). `user_id` = dono do tenant;
-- `store_id` = loja dona do lote (Fase 2 do multi-tenancy).
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

-- ---------------------------------------------------------------
-- 1.1b Camada de Contas: planos, tenants, lojas, funcionários, upgrades
-- ---------------------------------------------------------------
-- Criadas AQUI (antes dos triggers de store_id) porque o helper
-- `is_my_store()` e o seed referenciam public.stores — que precisa
-- existir antes dos triggers que o consultam.

-- Planos de assinatura — criados/editados pelo super admin; limitam a
-- estrutura de cada tenant (nº de lojas, funcionários, etc.).
CREATE TABLE IF NOT EXISTS public.plans (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  price_monthly BIGINT NOT NULL DEFAULT 0
                CHECK (price_monthly >= 0),
  max_stores    INTEGER NOT NULL DEFAULT 1 CHECK (max_stores >= 1),
  max_employees INTEGER NOT NULL DEFAULT 1 CHECK (max_employees >= 1),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tenants (empresas). O dono cria a solicitação com status `pending`;
-- o super admin aprova/rejeita manualmente (prazo de até 24h).
CREATE TABLE IF NOT EXISTS public.tenants (
  id               TEXT PRIMARY KEY,
  owner_user_id    UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  business_name    TEXT NOT NULL,
  plan_id          TEXT NOT NULL REFERENCES public.plans (id),
  status           TEXT NOT NULL DEFAULT 'pending' CHECK (status IN
    ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  approved_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Preferências de apresentação escolhidas pelo DONO no onboarding
  -- (alteráveis em Lojas → Ajustes): moeda dos valores e idioma do app.
  -- `language` ∈ ('pt', 'en', 'fr') — o app só usa esses três valores.
  -- Moeda padrão dos novos tenants: MZN (metical — mercado-alvo
  -- Moçambique); o dono altera em Lojas → Ajustes.
  currency_code    TEXT NOT NULL DEFAULT 'MZN'
                    CHECK (currency_code IN ('BRL', 'USD', 'EUR', 'MZN')),
  language         TEXT NOT NULL DEFAULT 'pt'
                    CHECK (language IN ('pt', 'en', 'fr')),

  -- P1 (MFA server-side): quando TRUE, TODA escrita do caminho de dinheiro
  -- (venda/compra/fiado/quitação/anulação/fecho) do tenant EXIGE sessão
  -- aal2 — o 2º fator TOTP verificado no GoTrue. Default FALSE: ativação
  -- explícita pelo dono (Lojas → Ajustes), nunca trancando bases
  -- existentes. Leitura não é bloqueada.
  mfa_enforced     BOOLEAN NOT NULL DEFAULT FALSE
);

-- Migração idempotente para bancos já criados (CREATE TABLE IF NOT EXISTS
-- não altera tabelas existentes): adiciona as colunas com defaults.
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'MZN';
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'pt';
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS mfa_enforced BOOLEAN NOT NULL DEFAULT FALSE;

-- Lojas de um tenant — cada loja terá seus funcionários e, na Fase 2,
-- seu próprio estoque e vendas (escopo por store_id).
CREATE TABLE IF NOT EXISTS public.stores (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL REFERENCES public.tenants (id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  address    TEXT NOT NULL DEFAULT '',
  phone      TEXT NOT NULL DEFAULT '',
  email      TEXT NOT NULL DEFAULT '',
  nuit       TEXT NOT NULL DEFAULT '',
  city       TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Funcionários vinculados a lojas (o dono cria a conta: nome, e-mail,
-- senha, loja e cargo; o funcionário só faz login depois).
CREATE TABLE IF NOT EXISTS public.store_employees (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL REFERENCES public.tenants (id) ON DELETE CASCADE,
  store_id   TEXT NOT NULL REFERENCES public.stores (id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name  TEXT NOT NULL,
  email      TEXT NOT NULL,
  role       TEXT NOT NULL DEFAULT 'employee' CHECK (role IN
    ('manager', 'employee')),
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pedidos de upgrade de plano — criados pelo dono, decididos pelo super
-- admin; ao aprovar, o plano do tenant muda para o solicitado.
CREATE TABLE IF NOT EXISTS public.plan_requests (
  id                TEXT PRIMARY KEY,
  tenant_id         TEXT NOT NULL REFERENCES public.tenants (id)
                    ON DELETE CASCADE,
  current_plan_id   TEXT NOT NULL REFERENCES public.plans (id),
  requested_plan_id TEXT NOT NULL REFERENCES public.plans (id),
  status            TEXT NOT NULL DEFAULT 'pending' CHECK (status IN
    ('pending', 'approved', 'rejected')),
  decided_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------
-- 1.2 Habilitar Row Level Security em todas as tabelas
-- ---------------------------------------------------------------
ALTER TABLE public.products               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_lot_consumption   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_closings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_lots             ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------
-- 1.2b Helpers de acesso (definidos AQUI, ANTES das políticas 1.3 que os
-- consultam): o usuário é dono do tenant? / tem acesso à loja?
-- ---------------------------------------------------------------

-- Helper: o usuário é dono do tenant [target_tenant_id]?
--
-- SECURITY DEFINER + search_path fixo (auditoria Aug 6 — regressão 54001
-- max_stack_depth): estes helpers são chamados DENTRO das políticas RLS e
-- consultam tabelas (tenants/stores/store_employees) que TÊM políticas
-- próprias que voltam a chamar os helpers — um ciclo entre tabelas que,
-- dependendo do plano de execução/versão do Postgres, estoura a pilha
-- (erro 54001 em varreduras completas no Supabase). Com SECURITY DEFINER
-- as consultas internas ignoram o RLS (o mesmo padrão de is_super_admin e
-- das RPCs do dinheiro), quebrando o ciclo POR CONSTRUÇÃO — a recursão
-- vira impossível em qualquer versão. Segurança: a função só devolve um
-- BOOLEAN sobre um id explícito (não exfiltra dados) e o search_path está
-- fixado em public.
CREATE OR REPLACE FUNCTION public.is_tenant_owner(target_tenant_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.id = target_tenant_id AND t.owner_user_id = auth.uid()
  );
$$;

-- Helper: o usuário tem acesso à loja [target_store_id]? O dono do tenant
-- vale para todas as lojas do tenant; o FUNCIONÁRIO vale para a loja do
-- vínculo em store_employees (auditoria C2 — acesso por loja no SaaS).
--
-- SECURITY DEFINER + search_path fixo: mesmo motivo do is_tenant_owner
-- acima — as políticas de stores/tenants/store_employees formam um ciclo
-- entre tabelas que pode estourar a pilha (54001) em varreduras completas;
-- o definer quebra o ciclo (ver comentário do is_tenant_owner).
CREATE OR REPLACE FUNCTION public.is_my_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- Helper: o usuário tem PODER DE GESTÃO na loja [target_store_id]? (dono
-- do tenant OU funcionário com cargo 'manager' no vínculo).
--
-- Matriz de acesso (Aug 6): compras e relatórios são nível GERENCIAL — o
-- FUNCIONÁRIO comum opera vendas/estoque/fiado, mas NÃO registra compras
-- nem acede aos relatórios de negócio. Este helper é usado na guarda do
-- `process_purchase` (RPC) e nas políticas RLS de purchases/purchase_items
-- — o servidor é a autoridade, mesmo que um cliente modificado chame o
-- PostgREST diretamente.
--
-- SECURITY DEFINER + search_path fixo: mesmo padrão dos demais helpers RLS
-- (is_tenant_owner/is_my_store) — evita o ciclo entre tabelas (54001) e
-- só devolve um BOOLEAN sobre um id explícito (não exfiltra dados).
CREATE OR REPLACE FUNCTION public.is_manager_of_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ---------------------------------------------------------------
-- 1.2c Helpers de MFA no SERVIDOR (P1 — auditoria forense)
--
-- O MFA/TOTP do app era APENAS client-side: a flag e o segredo viviam no
-- armazenamento seguro do DISPOSITIVO e a verificação era local — um
-- portador da senha autenticava pela API direta com sessão válida e o RLS
-- aceitava (as políticas só consultam auth.uid()). Estes helpers movem a
-- decisão para o SERVIDOR:
--   * o fato verificado vive em auth.mfa_factors (GoTrue — matrícula via
--     enroll/challenge/verify, igual ao tool/enroll_owner_mfa.dart);
--   * a sessão carrega o claim `aal` ('aal1' senha / 'aal2' senha+fator);
--   * o dono ativa a EXIGÊNCIA por tenant (tenants.mfa_enforced) —
--     default FALSE, para que bases existentes e contas sem autenticador
--     não sejam trancadas por uma migração.
-- SECURITY DEFINER + search_path fixo: consulta auth.mfa_factors (schema
-- auth, sem políticas) dentro de políticas RLS sem recursão.
-- ---------------------------------------------------------------

-- Nº de fatores TOTP VERIFICADOS do usuário logado no GoTrue.
CREATE OR REPLACE FUNCTION public.mfa_verified_factor_count(p_user uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT COUNT(*)::int
  FROM auth.mfa_factors
  WHERE user_id = p_user
    AND status = 'verified'
    AND factor_type = 'totp';
$$;

-- O usuário logado concluiu o 2º fator NESTA sessão?
-- O claim `aal` do JWT só sobe para 'aal2' após o challenge+verify
-- (AuthChangeEvent.mfaChallengeVerified renova o token com aal2).
CREATE OR REPLACE FUNCTION public.mfa_satisfied(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT COALESCE(auth.jwt() ->> 'aal', 'aal1') = 'aal2';
$$;

-- A exigência de MFA está ATIVA para o usuário [p_user]?
-- Dono: mfa_enforced do tenant dele. Funcionário: a exigência do tenant
-- da loja do vínculo ATIVO. Sem vínculo/tenant: FALSE (nunca trancar).
CREATE OR REPLACE FUNCTION public.mfa_enforced_for_user(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tenants t
    WHERE t.mfa_enforced
      AND (
        t.owner_user_id = p_user
        OR EXISTS (
          SELECT 1
          FROM public.stores s
          JOIN public.store_employees e ON e.store_id = s.id
          WHERE s.tenant_id = t.id
            AND e.user_id = p_user
            AND e.is_active
        )
      )
  );
$$;

-- Guarda ÚNICA usada por políticas e RPCs do dinheiro:
-- TRUE quando o usuário NÃO está sujeito à exigência (MFA desligado no
-- tenant OU já concluiu o 2º fator nesta sessão). Policy/RPC usa
-- `mfa_ok()` — leitura NUNCA é bloqueada; escrita do dinheiro SIM.
--
-- Nota de fail-safe: se a leitura de auth.mfa_factors falhar dentro de
-- mfa_verified_factor_count (p.ex. projeto sem GoTrue — testes locais),
-- a EXISTS do enforcement ainda precisa do tenants.mfa_enforced para
-- bloquear; bases antigas nascem com FALSE (sem tranca).
CREATE OR REPLACE FUNCTION public.mfa_ok(p_user uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT NOT public.mfa_enforced_for_user(p_user)
      OR public.mfa_satisfied(p_user);
$$;

-- ---------------------------------------------------------------
-- 1.3 Políticas de isolamento por tenant E LOJA (auditoria C2)
--
-- Regra de acesso às tabelas de negócio: o registro é visível/gravável
-- quando o usuário logado É o criador (`auth.uid() = user_id`) OU quando
-- tem acesso à LOJA do registro (`public.is_my_store(store_id)`) — o dono
-- do tenant vale para todas as lojas do tenant; o FUNCIONÁRIO vale para a
-- loja do vínculo em `store_employees`. Sem isso, funcionários (outros
-- usuários) não enxergavam NENHUM dado de negócio no modo SaaS (bloqueador
-- C2 da auditoria forense).
--
-- `is_my_store`/`is_tenant_owner` são STABLE + SECURITY DEFINER e consultam
-- `stores`/`tenants`/`store_employees` SEM RLS interno — sem ciclo de
-- políticas entre tabelas, logo sem recursão (regressão 54001 resolvida
-- por construção; ver o comentário das funções em 1.2b).
--
-- Usamos DROP POLICY IF EXISTS + CREATE POLICY: compatível com
-- PostgreSQL 12/13/14 (o CREATE OR REPLACE POLICY é do PG 15+) e
-- idempotente — pode reexecutar a parte 1 quantas vezes quiser.
-- ---------------------------------------------------------------

-- products
DROP POLICY IF EXISTS products_select ON public.products;
CREATE POLICY products_select ON public.products
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS products_insert ON public.products;
CREATE POLICY products_insert ON public.products
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS products_update ON public.products;
CREATE POLICY products_update ON public.products
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS products_delete ON public.products;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY products_delete ON public.products
  FOR DELETE USING (auth.uid() = user_id);

-- stock_lots (W11) — leitura/escrita para dono e funcionários da loja
-- (mesmo padrão de products); DELETE só de registros PRÓPRIOS.
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

-- sales
DROP POLICY IF EXISTS sales_select ON public.sales;
CREATE POLICY sales_select ON public.sales
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS sales_insert ON public.sales;
CREATE POLICY sales_insert ON public.sales
  FOR INSERT WITH CHECK (
    (auth.uid() = user_id OR public.is_my_store(store_id))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS sales_update ON public.sales;
CREATE POLICY sales_update ON public.sales
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK ((auth.uid() = user_id OR public.is_my_store(store_id))
              AND public.mfa_ok());
DROP POLICY IF EXISTS sales_delete ON public.sales;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY sales_delete ON public.sales
  FOR DELETE USING (auth.uid() = user_id);

-- sale_items: NÃO tem store_id — o acesso vem do pai (`sales.store_id`)
-- via subconsulta. O RLS da subconsulta (sales_select) já filtra pelo que
-- o usuário pode ver; o EXISTS apenas confirma o vínculo no pai visível.
DROP POLICY IF EXISTS sale_items_select ON public.sale_items;
CREATE POLICY sale_items_select ON public.sale_items
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_items_insert ON public.sale_items;
CREATE POLICY sale_items_insert ON public.sale_items
  FOR INSERT WITH CHECK (
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS sale_items_update ON public.sale_items;
CREATE POLICY sale_items_update ON public.sale_items
  FOR UPDATE USING (
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  ) WITH CHECK (
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS sale_items_delete ON public.sale_items;
-- DELETE só de registros PRÓPRIOS (o app não exclui nada).
CREATE POLICY sale_items_delete ON public.sale_items
  FOR DELETE USING (auth.uid() = user_id);

-- sale_lot_consumption: idem sale_items — sem store_id; o acesso vem do
-- pai (`sales.store_id`) via subconsulta. Escrita direta é usada apenas
-- pelas RPCs (SECURITY DEFINER — o RLS não se aplica dentro delas); as
-- políticas são defesa para acesso direto ao PostgREST.
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
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_lot_consumption.sale_id
         AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS sale_lot_consumption_update ON public.sale_lot_consumption;
CREATE POLICY sale_lot_consumption_update ON public.sale_lot_consumption
  FOR UPDATE USING (
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_lot_consumption.sale_id
         AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  ) WITH CHECK (
    (auth.uid() = user_id
     OR EXISTS (
       SELECT 1 FROM public.sales s
       WHERE s.id = sale_lot_consumption.sale_id
         AND public.is_my_store(s.store_id)
     ))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS sale_lot_consumption_delete ON public.sale_lot_consumption;
-- DELETE só de registros PRÓPRIOS (o app não exclui nada).
CREATE POLICY sale_lot_consumption_delete ON public.sale_lot_consumption
  FOR DELETE USING (auth.uid() = user_id);

-- financial_transactions
DROP POLICY IF EXISTS financial_transactions_select ON public.financial_transactions;
CREATE POLICY financial_transactions_select ON public.financial_transactions
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS financial_transactions_insert ON public.financial_transactions;
CREATE POLICY financial_transactions_insert ON public.financial_transactions
  FOR INSERT WITH CHECK (
    (auth.uid() = user_id OR public.is_my_store(store_id))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS financial_transactions_update ON public.financial_transactions;
CREATE POLICY financial_transactions_update ON public.financial_transactions
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK ((auth.uid() = user_id OR public.is_my_store(store_id))
              AND public.mfa_ok());
DROP POLICY IF EXISTS financial_transactions_delete ON public.financial_transactions;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY financial_transactions_delete ON public.financial_transactions
  FOR DELETE USING (auth.uid() = user_id);

-- cash_closings — leitura para dono/funcionários da loja (histórico de
-- fechos); escrita via RPC (SECURITY DEFINER, guarda gerencial). A política
-- de INSERT exige loja própria (defesa em profundidade — o app no modo
-- SaaS nunca insere direto, mas um cliente direto também não pode forjar
-- um fecho de outra loja); UPDATE/DELETE só de registros PRÓPRIOS.
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

-- debts
DROP POLICY IF EXISTS debts_select ON public.debts;
CREATE POLICY debts_select ON public.debts
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS debts_insert ON public.debts;
CREATE POLICY debts_insert ON public.debts
  FOR INSERT WITH CHECK (
    (auth.uid() = user_id OR public.is_my_store(store_id))
    AND public.mfa_ok()
  );
DROP POLICY IF EXISTS debts_update ON public.debts;
CREATE POLICY debts_update ON public.debts
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK ((auth.uid() = user_id OR public.is_my_store(store_id))
              AND public.mfa_ok());
DROP POLICY IF EXISTS debts_delete ON public.debts;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY debts_delete ON public.debts
  FOR DELETE USING (auth.uid() = user_id);

-- customers
DROP POLICY IF EXISTS customers_select ON public.customers;
CREATE POLICY customers_select ON public.customers
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS customers_insert ON public.customers;
CREATE POLICY customers_insert ON public.customers
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS customers_update ON public.customers;
CREATE POLICY customers_update ON public.customers
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS customers_delete ON public.customers;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY customers_delete ON public.customers
  FOR DELETE USING (auth.uid() = user_id);

-- purchases
-- purchases — módulo de nível GERENCIAL (matriz de acesso Aug 6): dono e
-- gerente leem/gravam; FUNCIONÁRIO comum não acede. A autoridade é o
-- servidor: o RLS nega mesmo se o app esconder só na UI. (O app usa a RPC
-- process_purchase para gravar — as políticas são defesa para acesso
-- direto ao PostgREST.)
DROP POLICY IF EXISTS purchases_select ON public.purchases;
CREATE POLICY purchases_select ON public.purchases
  FOR SELECT USING (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_insert ON public.purchases;
CREATE POLICY purchases_insert ON public.purchases
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id)
                         AND public.mfa_ok());
DROP POLICY IF EXISTS purchases_update ON public.purchases;
CREATE POLICY purchases_update ON public.purchases
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id) AND public.mfa_ok());
DROP POLICY IF EXISTS purchases_delete ON public.purchases;
-- DELETE gerencial (intencional): compras são nível manager+ — um gerente
-- pode remover QUALQUER compra da loja (incluindo do dono), consistente com
-- o papel gerencial. O app não exclui nada hoje; se um dia excluir, a regra
-- continua coerente com a matriz (o dono cobre tudo via is_tenant_owner).
CREATE POLICY purchases_delete ON public.purchases
  FOR DELETE USING (public.is_manager_of_store(store_id));

-- purchase_items: idem sale_items — acesso via pai (`purchases.store_id`),
-- mas com a MESMA regra gerencial do pai (manager+).
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
-- DELETE gerencial (o app não exclui nada).
CREATE POLICY purchase_items_delete ON public.purchase_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );

-- ---------------------------------------------------------------
-- 1.4 Índices de consulta por tenant
-- ---------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_products_user_name
  ON public.products (user_id, name);
CREATE INDEX IF NOT EXISTS idx_products_store
  ON public.products (store_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_datetime
  ON public.sales (user_id, date_time DESC);
CREATE INDEX IF NOT EXISTS idx_sales_store
  ON public.sales (store_id);
-- Unicidade do número SEQUENCIAL de venda por loja (defesa em
-- profundidade — a atribuição no process_sale usa advisory lock).
CREATE UNIQUE INDEX IF NOT EXISTS uq_sales_store_number
  ON public.sales (store_id, sale_number);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id
  ON public.sale_items (sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_lot_consumption_sale
  ON public.sale_lot_consumption (sale_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_date
  ON public.financial_transactions (user_id, date);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_store
  ON public.financial_transactions (store_id);
-- Resolução de pendências vinculadas (settle_debt/register_debt).
CREATE INDEX IF NOT EXISTS idx_financial_transactions_debt
  ON public.financial_transactions (debt_id);
-- Fechos de caixa: consulta por loja (histórico) — a unicidade
-- (store_id, closing_date) é o índice único declarado na tabela.
CREATE INDEX IF NOT EXISTS idx_cash_closings_store
  ON public.cash_closings (store_id);
CREATE INDEX IF NOT EXISTS idx_debts_user_due
  ON public.debts (user_id, due_date);
CREATE INDEX IF NOT EXISTS idx_debts_store
  ON public.debts (store_id);
-- Unicidade do número SEQUENCIAL de dívida por loja (defesa em
-- profundidade — a atribuição no register_debt usa advisory lock).
CREATE UNIQUE INDEX IF NOT EXISTS uq_debts_store_number
  ON public.debts (store_id, debt_number);
CREATE INDEX IF NOT EXISTS idx_customers_user_name
  ON public.customers (user_id, name);
CREATE INDEX IF NOT EXISTS idx_customers_store
  ON public.customers (store_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user_datetime
  ON public.purchases (user_id, date_time DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_store
  ON public.purchases (store_id);
-- Unicidade do número SEQUENCIAL de compra por loja (defesa em
-- profundidade — a atribuição no process_purchase usa advisory lock).
CREATE UNIQUE INDEX IF NOT EXISTS uq_purchases_store_number
  ON public.purchases (store_id, purchase_number);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id
  ON public.purchase_items (purchase_id);

-- ---------------------------------------------------------------
-- 1.5 Trigger de tenant: user_id = auth.uid() em todo INSERT
-- ---------------------------------------------------------------
-- Defesa em profundidade: mesmo que o cliente (app) omita ou tente forjar o
-- user_id, o banco grava o usuário autenticado pelo JWT. O app já envia o
-- user_id explicitamente; este trigger garante a regra no servidor.
CREATE OR REPLACE FUNCTION public.set_tenant_user_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  -- Só força o valor quando há sessão (JWT). No SQL Editor (sem sessão),
  -- o valor informado é preservado.
  IF auth.uid() IS NOT NULL THEN
    NEW.user_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_user_id ON public.products;
CREATE TRIGGER trg_products_user_id
  BEFORE INSERT ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_sales_user_id ON public.sales;
CREATE TRIGGER trg_sales_user_id
  BEFORE INSERT ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_sale_items_user_id ON public.sale_items;
CREATE TRIGGER trg_sale_items_user_id
  BEFORE INSERT ON public.sale_items
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_sale_lot_consumption_user_id
  ON public.sale_lot_consumption;
CREATE TRIGGER trg_sale_lot_consumption_user_id
  BEFORE INSERT ON public.sale_lot_consumption
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_financial_transactions_user_id
  ON public.financial_transactions;
CREATE TRIGGER trg_financial_transactions_user_id
  BEFORE INSERT ON public.financial_transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_cash_closings_user_id ON public.cash_closings;
CREATE TRIGGER trg_cash_closings_user_id
  BEFORE INSERT ON public.cash_closings
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_debts_user_id ON public.debts;
CREATE TRIGGER trg_debts_user_id
  BEFORE INSERT ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_customers_user_id ON public.customers;
CREATE TRIGGER trg_customers_user_id
  BEFORE INSERT ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_purchases_user_id ON public.purchases;
CREATE TRIGGER trg_purchases_user_id
  BEFORE INSERT ON public.purchases
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_purchase_items_user_id ON public.purchase_items;
CREATE TRIGGER trg_purchase_items_user_id
  BEFORE INSERT ON public.purchase_items
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_stock_lots_user_id ON public.stock_lots;
CREATE TRIGGER trg_stock_lots_user_id
  BEFORE INSERT ON public.stock_lots
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- ---------------------------------------------------------------
-- 1.5b Trigger de loja: store_id = loja do usuário em todo INSERT
-- ---------------------------------------------------------------
-- Fase 2 do multi-tenancy: além do user_id, cada registro de negócio
-- pertence a uma LOJA. Este trigger força o store_id para uma loja do
-- próprio usuário (dono ou funcionário vinculado) — o cliente não pode
-- forjar um store_id de outra loja/tenant.
--
-- ⚠️ O app envia o store_id da loja ATIVA explicitamente; o trigger é a
-- defesa em profundidade no servidor. No SQL Editor (sem JWT) o valor
-- informado é preservado.

-- Helper: o usuário é dono do tenant [tenantId]? (definido na seção 1.2b —
-- o RLS da seção 1.7 também o usa).

CREATE OR REPLACE FUNCTION public.set_record_store_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    -- Se o valor enviado NÃO for uma loja do usuário, cai para a
    -- primeira loja que ele acessa (dono ou funcionário).
    IF NEW.store_id IS NULL OR NOT public.is_my_store(NEW.store_id) THEN
      NEW.store_id := (
        SELECT s.id FROM public.stores s
        WHERE public.is_tenant_owner(s.tenant_id)
           OR EXISTS (
             SELECT 1 FROM public.store_employees e
             WHERE e.store_id = s.id AND e.user_id = auth.uid()
           )
        ORDER BY s.created_at, s.id
        LIMIT 1
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_store_id ON public.products;
CREATE TRIGGER trg_products_store_id
  BEFORE INSERT ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_sales_store_id ON public.sales;
CREATE TRIGGER trg_sales_store_id
  BEFORE INSERT ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_financial_transactions_store_id
  ON public.financial_transactions;
CREATE TRIGGER trg_financial_transactions_store_id
  BEFORE INSERT ON public.financial_transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_cash_closings_store_id ON public.cash_closings;
CREATE TRIGGER trg_cash_closings_store_id
  BEFORE INSERT ON public.cash_closings
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_debts_store_id ON public.debts;
CREATE TRIGGER trg_debts_store_id
  BEFORE INSERT ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_customers_store_id ON public.customers;
CREATE TRIGGER trg_customers_store_id
  BEFORE INSERT ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_purchases_store_id ON public.purchases;
CREATE TRIGGER trg_purchases_store_id
  BEFORE INSERT ON public.purchases
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

DROP TRIGGER IF EXISTS trg_stock_lots_store_id ON public.stock_lots;
CREATE TRIGGER trg_stock_lots_store_id
  BEFORE INSERT ON public.stock_lots
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();


-- ---------------------------------------------------------------
-- 1.7 RLS das tabelas da Camada de Contas
-- ---------------------------------------------------------------
ALTER TABLE public.plans           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_requests   ENABLE ROW LEVEL SECURITY;

-- Publica `store_employees` no Realtime (bloqueio INSTANTÂNEO de
-- funcionários desativados): o app assina `postgres_changes` com filtro
-- `user_id = auth.uid()`; sem a publicação, o canal nunca recebe eventos.
-- O RLS da tabela (próprio usuário/dono/super admin) limita cada sessão
-- aos eventos do PRÓPRIO vínculo — o funcionário continua recebendo a
-- mudança de `is_active` mesmo após ser desativado (ele ainda lê a linha).
-- Idempotente (fix Aug 8): em PostgreSQL PURO, ADD TABLE numa tabela já
-- publicada é um no-op, mas no SUPABASE é um ERRO 42710
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

-- Super admin: papel BASEADO EM BANCO (tabela public.super_admins) —
-- substitui a checagem por e-mail hardcoded (auditoria C3). O papel vive
-- NESTA tabela, nunca no e-mail do JWT. Para promover um usuário:
--
--   INSERT INTO public.super_admins (user_id)
--   SELECT id FROM auth.users WHERE email = 'admin@seudominio.com'
--   ON CONFLICT (user_id) DO NOTHING;
--
-- Segurança: RLS HABILITADO sem nenhuma política (nega leitura e escrita
-- para anon/authenticated — impede até auto-promoção) + REVOKE explícito
-- como defesa extra. O acesso é exclusivo da função SECURITY DEFINER
-- abaixo (o dono do schema, superusuário, ignora o RLS). O REVOKE é
-- condicional para não quebrar o harness de teste em Postgres puro
-- (sqlcheck_stub.sql), onde os papéis anon/authenticated não existem.
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
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.super_admins WHERE user_id = auth.uid()
  );
$$;

-- Migração de continuidade (uma única vez): promove o dono do e-mail
-- legado ao papel em tabela. Depois de rodar o script, o e-mail deixa de
-- ter qualquer efeito — o papel passa a ser governado só pela tabela.
-- Pode ser removida (ou o INSERT feito manualmente) após a primeira
-- execução em produção.
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE lower(email) = 'admin@dumbhanengue.com'
ON CONFLICT (user_id) DO NOTHING;

-- ---------------------------------------------------------------
-- 2.3 Audit log (W9): trilha imutável e somente-super-admin
-- ---------------------------------------------------------------
-- Registo de decisões administrativas (aprovar/rejeitar tenant e pedido
-- de plano; alterações de planos). Escrita via triggers SECURITY DEFINER
-- (nenhum papel escreve direto); leitura apenas pela RPC get_audit_log,
-- que exige is_super_admin(). RLS sem políticas + REVOKE de
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

-- Função do trigger: grava a entrada com o ator resolvido do JWT e o
-- estado novo da linha (JSONB). A ação vem de TG_ARGV[0] (por trigger).
CREATE OR REPLACE FUNCTION public.log_audit_entry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
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

-- Leitura: apenas o super admin (guarda dentro da própria RPC — o papel
-- anon/authenticated não tem permissão de tabela e o RLS não tem
-- políticas; o SECURITY DEFINER + guarda fecham a porta).
CREATE OR REPLACE FUNCTION public.get_audit_log(p_limit integer DEFAULT 100)
RETURNS SETOF public.audit_log
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Apenas o super admin pode consultar o registo de auditoria.';
  END IF;
  RETURN QUERY SELECT * FROM public.audit_log
    ORDER BY id DESC
    LIMIT GREATEST(1, p_limit);
END $$;

-- W5 — KPIs do dashboard agregadas NO SERVIDOR (get_dashboard_kpis).
-- Uma única chamada RPC devolve os 4 indicadores da loja (vendas totais,
-- caixa do período, a receber, estoque) em vez de 4 listagens de até 1000
-- linhas agregadas no cliente. Guarda is_my_store (dono ou funcionário da
-- loja); o período [p_start, p_end] afeta APENAS o caixa (status paid) —
-- vendas, fiado e estoque são totais da loja (mesma semântica client-side).
CREATE OR REPLACE FUNCTION public.get_dashboard_kpis(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ
)
RETURNS TABLE (
  -- W4: valores em CENTAVOS inteiros (BIGINT).
  total_sales   BIGINT,
  cash_income   BIGINT,
  cash_expense  BIGINT,
  pending_total BIGINT,
  stock_total   BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
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

-- H2 — fluxo de caixa agregado NO SERVIDOR (get_cash_flow).
-- Mesma semântica do GetCashFlowUseCase client-side: apenas transações
-- PAID no período; vendas fiadas só contam quando recebidas. Guarda
-- is_my_store; retorna valores em CENTAVOS inteiros (BIGINT, W4).
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
SET search_path = pg_catalog, public, extensions
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

-- H2 — relatório de vendas agregado NO SERVIDOR (get_sales_report).
-- Mesma semântica do GetSalesReportUseCase client-side (faturamento,
-- lucro bruto, mais vendidos e vendas por dia), em CENTAVOS inteiros.
-- O dia é agrupado no fuso do dispositivo (p_tz_offset_minutes) para
-- casar com o DateTime(y, m, d) local do cliente. Guarda is_my_store.
CREATE OR REPLACE FUNCTION public.get_sales_report(
  p_store_id TEXT,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_tz_offset_minutes INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
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

-- plans — leitura para todos os logados; escrita só do super admin
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

-- tenants — dono (ou funcionário vinculado) lê; todos criam a própria
-- solicitação (INSERT com owner_user_id = auth.uid()); super admin decide.
DROP POLICY IF EXISTS tenants_select ON public.tenants;
CREATE POLICY tenants_select ON public.tenants
  FOR SELECT USING (
    owner_user_id = auth.uid()
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1 FROM public.store_employees e
      WHERE e.tenant_id = tenants.id AND e.user_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS tenants_insert ON public.tenants;
CREATE POLICY tenants_insert ON public.tenants
  FOR INSERT WITH CHECK (owner_user_id = auth.uid());
DROP POLICY IF EXISTS tenants_update ON public.tenants;
CREATE POLICY tenants_update ON public.tenants
  FOR UPDATE USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());
DROP POLICY IF EXISTS tenants_delete ON public.tenants;
CREATE POLICY tenants_delete ON public.tenants
  FOR DELETE USING (public.is_super_admin());

-- stores — dono do tenant (e funcionários) leem; dono/super admin escrevem
DROP POLICY IF EXISTS stores_select ON public.stores;
CREATE POLICY stores_select ON public.stores
  FOR SELECT USING (
    public.is_tenant_owner(stores.tenant_id)
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1 FROM public.store_employees e
      WHERE e.store_id = stores.id AND e.user_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS stores_insert ON public.stores;
CREATE POLICY stores_insert ON public.stores
  FOR INSERT WITH CHECK (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS stores_update ON public.stores;
CREATE POLICY stores_update ON public.stores
  FOR UPDATE USING (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  ) WITH CHECK (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS stores_delete ON public.stores;
CREATE POLICY stores_delete ON public.stores
  FOR DELETE USING (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );

-- store_employees — próprio funcionário/dono/super admin leem; dono/super
-- admin gerem (criar conta do funcionário é INSERT do dono).
DROP POLICY IF EXISTS store_employees_select ON public.store_employees;
CREATE POLICY store_employees_select ON public.store_employees
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_tenant_owner(tenant_id)
    OR public.is_super_admin()
  );
DROP POLICY IF EXISTS store_employees_insert ON public.store_employees;
CREATE POLICY store_employees_insert ON public.store_employees
  FOR INSERT WITH CHECK (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS store_employees_update ON public.store_employees;
CREATE POLICY store_employees_update ON public.store_employees
  FOR UPDATE USING (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  ) WITH CHECK (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS store_employees_delete ON public.store_employees;
CREATE POLICY store_employees_delete ON public.store_employees
  FOR DELETE USING (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );

-- plan_requests — dono do tenant lê/cria; super admin decide
DROP POLICY IF EXISTS plan_requests_select ON public.plan_requests;
CREATE POLICY plan_requests_select ON public.plan_requests
  FOR SELECT USING (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS plan_requests_insert ON public.plan_requests;
CREATE POLICY plan_requests_insert ON public.plan_requests
  FOR INSERT WITH CHECK (
    public.is_tenant_owner(tenant_id) OR public.is_super_admin()
  );
DROP POLICY IF EXISTS plan_requests_update ON public.plan_requests;
CREATE POLICY plan_requests_update ON public.plan_requests
  FOR UPDATE USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());
DROP POLICY IF EXISTS plan_requests_delete ON public.plan_requests;
CREATE POLICY plan_requests_delete ON public.plan_requests
  FOR DELETE USING (public.is_super_admin());

-- ---------------------------------------------------------------
-- 1.7c Ajustes do tenant (moeda/idioma) — RPC do DONO
-- ---------------------------------------------------------------
-- A política `tenants_update` acima só permite o SUPER ADMIN alterar a
-- linha do tenant (status/plano são decisões administrativas). Para o
-- DONO trocar moeda e idioma em Lojas → Ajustes sem abrir um UPDATE
-- irrestrito, a operação passa por esta RPC SECURITY DEFINER: a guarda
-- `is_tenant_owner` limita a chamada a quem é dono e o UPDATE toca
-- APENAS as duas colunas de apresentação — o dono nunca alcança
-- status/plano/motivo pelo banco.
CREATE OR REPLACE FUNCTION public.update_tenant_settings(
  p_tenant_id TEXT,
  p_currency_code TEXT,
  p_language TEXT,
  p_mfa_enforced BOOLEAN DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_currency text := CASE WHEN p_currency_code IN ('BRL','USD','EUR','MZN')
                          THEN p_currency_code ELSE 'MZN' END;
  v_lang text := CASE WHEN p_language IN ('pt','en','fr')
                      THEN p_language ELSE 'pt' END;
  v_mfa_current boolean;
BEGIN
  IF NOT public.is_tenant_owner(p_tenant_id) THEN
    RAISE EXCEPTION 'Apenas o dono do tenant pode alterar moeda e idioma.';
  END IF;

  SELECT mfa_enforced INTO v_mfa_current
    FROM public.tenants WHERE id = p_tenant_id;

  -- P1 (MFA server-side): só TRANSIÇÕES de estado alteram mfa_enforced —
  -- receber o MESMO valor é no-op (o ajuste de moeda/idioma da app envia
  -- sempre o estado atual do formulário e NUNCA deve tocar a exigência).
  --   * ativação (false→true): exige fator TOTP verificado no GoTrue — o
  --     ativador não pode trancar a si mesmo;
  --   * desativação (true→false): exige sessão aal2 — um invasor apenas
  --     com a senha (aal1) NÃO consegue desligar a proteção por RPC.
  IF p_mfa_enforced IS TRUE AND NOT COALESCE(v_mfa_current, FALSE) THEN
    IF public.mfa_verified_factor_count(auth.uid()) = 0 THEN
      RAISE EXCEPTION
        'Ative e verifique um fator TOTP antes de exigir MFA no tenant.';
    END IF;
    UPDATE public.tenants
       SET mfa_enforced = TRUE
     WHERE id = p_tenant_id;
  ELSIF p_mfa_enforced IS FALSE AND COALESCE(v_mfa_current, FALSE) THEN
    IF NOT public.mfa_satisfied(auth.uid()) THEN
      RAISE EXCEPTION
        'Desativar a exigência de MFA requer sessão com 2º fator (aal2).';
    END IF;
    UPDATE public.tenants
       SET mfa_enforced = FALSE
     WHERE id = p_tenant_id;
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

-- ---------------------------------------------------------------
-- 1.8 Índices da Camada de Contas
-- ---------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tenants_owner
  ON public.tenants (owner_user_id);
CREATE INDEX IF NOT EXISTS idx_tenants_status
  ON public.tenants (status);
CREATE INDEX IF NOT EXISTS idx_stores_tenant
  ON public.stores (tenant_id);
CREATE INDEX IF NOT EXISTS idx_store_employees_tenant
  ON public.store_employees (tenant_id);
CREATE INDEX IF NOT EXISTS idx_store_employees_user
  ON public.store_employees (user_id);
CREATE INDEX IF NOT EXISTS idx_store_employees_store
  ON public.store_employees (store_id);
CREATE INDEX IF NOT EXISTS idx_plan_requests_tenant
  ON public.plan_requests (tenant_id);
CREATE INDEX IF NOT EXISTS idx_plan_requests_status
  ON public.plan_requests (status);

-- Anti-spam (auditoria S3): no máximo UM tenant PENDENTE por usuário —
-- impede a criação ilimitada de solicitações (DoS na fila de aprovação
-- manual + abuso de signup). Tenants aprovados/rejeitados não contam.
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_one_pending
  ON public.tenants (owner_user_id) WHERE status = 'pending';

-- ---------------------------------------------------------------
-- 1.9 Triggers anti-forja da Camada de Contas
-- ---------------------------------------------------------------
-- tenants: o dono é sempre o usuário autenticado do JWT.
CREATE OR REPLACE FUNCTION public.set_tenant_owner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.owner_user_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tenants_owner ON public.tenants;
CREATE TRIGGER trg_tenants_owner
  BEFORE INSERT ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_owner();

-- stores: o tenant_id é sempre o tenant do usuário autenticado.
CREATE OR REPLACE FUNCTION public.set_store_tenant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.tenant_id := (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stores_tenant ON public.stores;
CREATE TRIGGER trg_stores_tenant
  BEFORE INSERT ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.set_store_tenant();

-- store_employees: o tenant_id é herdado da loja vinculada.
CREATE OR REPLACE FUNCTION public.set_employee_tenant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.tenant_id := (
      SELECT tenant_id FROM public.stores WHERE id = NEW.store_id
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_store_employees_tenant ON public.store_employees;
CREATE TRIGGER trg_store_employees_tenant
  BEFORE INSERT ON public.store_employees
  FOR EACH ROW EXECUTE FUNCTION public.set_employee_tenant();

-- plan_requests: o tenant_id é sempre o do usuário autenticado (dono).
CREATE OR REPLACE FUNCTION public.set_plan_request_tenant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    NEW.tenant_id := (
      SELECT id FROM public.tenants
      WHERE owner_user_id = auth.uid()
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_plan_requests_tenant ON public.plan_requests;
CREATE TRIGGER trg_plan_requests_tenant
  BEFORE INSERT ON public.plan_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_plan_request_tenant();


-- ---------------------------------------------------------------
-- 1.10 Triggers de limite de plano (defesa no banco — o app também
-- valida na UI/casos de uso, mas o banco é a autoridade)
-- ---------------------------------------------------------------
-- O cliente pode chamar o PostgREST diretamente (ou um app modificado) e
-- pular a validação em Dart. Estes triggers impedem criar lojas/funcionários
-- além do limite do plano contratado — mesmo por fora do app.
--
-- ⚠️ Ordem de execução: nomeados com prefixo 'zzz' para rodarem DEPOIS dos
-- triggers anti-forja (set_store_tenant / set_employee_tenant), garantindo
-- que NEW.tenant_id já esteja resolvido. Mesmo assim, a função resolve o
-- tenant do usuário se ainda estiver ausente (dupla defesa).

CREATE OR REPLACE FUNCTION public.enforce_store_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_tenant_id text;
  v_max int;
  v_count int;
BEGIN
  IF auth.uid() IS NULL OR public.is_super_admin() THEN
    RETURN NEW;
  END IF;

  -- Tenant do usuário (dono) — resolve caso o trigger rode antes do
  -- set_store_tenant.
  v_tenant_id := NEW.tenant_id;
  IF v_tenant_id IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM public.tenants
       WHERE id = v_tenant_id AND owner_user_id = auth.uid()
     ) THEN
    SELECT id INTO v_tenant_id FROM public.tenants
    WHERE owner_user_id = auth.uid() LIMIT 1;
  END IF;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Tenant do usuário não encontrado.';
  END IF;

  SELECT p.max_stores INTO v_max
  FROM public.tenants t JOIN public.plans p ON p.id = t.plan_id
  WHERE t.id = v_tenant_id AND t.status = 'approved';
  IF v_max IS NULL THEN
    RAISE EXCEPTION 'Tenant não aprovado: crie lojas após a aprovação.';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.stores WHERE tenant_id = v_tenant_id;
  IF v_count >= v_max THEN
    RAISE EXCEPTION 'Limite de lojas do plano atingido (%). Solicite um upgrade.', v_max;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_zzz_store_limit ON public.stores;
CREATE TRIGGER trg_zzz_store_limit
  BEFORE INSERT ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.enforce_store_limit();

CREATE OR REPLACE FUNCTION public.enforce_employee_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_tenant_id text;
  v_max int;
  v_count int;
BEGIN
  IF auth.uid() IS NULL OR public.is_super_admin() THEN
    RETURN NEW;
  END IF;

  -- Tenant do vínculo — resolve do store_id caso o trigger rode antes do
  -- set_employee_tenant.
  v_tenant_id := NEW.tenant_id;
  IF v_tenant_id IS NULL THEN
    SELECT tenant_id INTO v_tenant_id FROM public.stores WHERE id = NEW.store_id;
  END IF;

  IF v_tenant_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.tenants
    WHERE id = v_tenant_id AND owner_user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Loja/tenant inválido para cadastro de funcionário.';
  END IF;

  SELECT p.max_employees INTO v_max
  FROM public.tenants t JOIN public.plans p ON p.id = t.plan_id
  WHERE t.id = v_tenant_id AND t.status = 'approved';
  IF v_max IS NULL THEN
    RAISE EXCEPTION 'Tenant não aprovado: cadastre funcionários após a aprovação.';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.store_employees WHERE tenant_id = v_tenant_id;
  IF v_count >= v_max THEN
    RAISE EXCEPTION 'Limite de funcionários do plano atingido (%). Solicite um upgrade.', v_max;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_zzz_employee_limit ON public.store_employees;
CREATE TRIGGER trg_zzz_employee_limit
  BEFORE INSERT ON public.store_employees
  FOR EACH ROW EXECUTE FUNCTION public.enforce_employee_limit();

-- ---------------------------------------------------------------
-- 1.11 Processadores ATÔMICOS (RPC) — venda e compra em UMA transação
-- ---------------------------------------------------------------
-- O app no modo SaaS grava venda/compra via REST em chamadas separadas
-- (venda + itens, baixa de estoque, caixa) — sem atomicidade: uma falha no
-- meio deixava estado parcial. Estas funções `SECURITY DEFINER` executam
-- TUDO em uma única transação do Postgres.
--
-- ⚠️ Segurança: como a função roda com privilégios do definer (dono das
-- tabelas), o RLS é dispensado DENTRO da função — por isso TODA função
-- valida o acesso à loja com `public.is_my_store(v_store)` logo no início
-- (dono do tenant ou funcionário vinculado) e filtra explicitamente por
-- `store_id`, e o `search_path` é fixado em `public`. Nunca remova a
-- guarda nem os filtros — eles substituem o RLS dentro da função.
-- Escopo por loja (não por user_id): registros da loja pertencem ao
-- tenant; a guarda de acesso torna o filtro de user_id redundante e
-- permite que FUNCIONÁRIOS da loja também operem (bloqueador C2).
--
-- ⚠️ Armadilha de precedência (Postgres): `||` e `->>` têm a MESMA
-- precedência (associatividade à esquerda) — `'t' || p_sale->>'id'` é
-- parseado como `('t' || p_sale)->>'id'`, virando concatenação jsonb e
-- quebrando com `invalid input syntax for type json: Token "t" is invalid`.
-- SEMPRE isole a extração com parênteses: `'t' || (p_sale->>'id')` e
-- `'X' || (p->>'campo')`.

-- Rótulo localizado da forma de pagamento para a descrição da entrada no
-- caixa (process_sale). Mesmas traduções do helper Dart
-- TransactionDescriptions.paymentMethodName — os modos local e SaaS devem
-- gravar o mesmo texto.
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

-- Helper compartilhado dos processadores atômicos: trava (FOR UPDATE) as
-- linhas de produto dos itens e valida estoque (venda) ou existência
-- (compra). Um único lugar para a semântica de locking — os dois RPCs não
-- podem divergir.
CREATE OR REPLACE FUNCTION public.lock_products_or_raise(
  p_items jsonb,
  p_store text,
  p_require_stock boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
    -- Produto DESATIVADO não pode ser vendido nem reposto (a reativação
    -- passa pelo dono/gerente no app).
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

-- Ajuste MANUAL de estoque (W12 — edição de produto): define a quantidade
-- absoluta do produto criando/consumindo LOTES FIFO em UMA transação. A
-- invariante `stock = Σ lotes` nunca quebra.
--
--   * AUMENTO (p_new_quantity > atual): cria um lote novo (sem validade —
--     FIFO por data de entrada; custo = preço de compra atual do catálogo);
--   * REDUÇÃO: abate dos lotes em ordem FIFO (validade mais próxima
--     primeiro; sem validade por entrada) — mesma mecânica do process_sale;
--   * IGUAL: no-op (idempotente — retry após sucesso não duplica nada).
--
-- Guarda GERENCIAL (matriz de acesso Aug 6): ajustar estoque é operação de
-- gestão — DONO ou GERENTE. O funcionário comum NÃO ajusta, mesmo por fora
-- do app (o servidor é a autoridade). SECURITY DEFINER + search_path fixo
-- + escopo por loja em todos os acessos (mesma mecânica das demais RPCs).
CREATE OR REPLACE FUNCTION public.adjust_product_stock(
  p_product_id TEXT,
  p_store_id TEXT,
  p_new_quantity BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
  -- P1 (MFA server-side): ajuste muta estoque e cria/consume lotes.
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para ajustar o estoque.';
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

CREATE OR REPLACE FUNCTION public.process_sale(p_sale jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
  -- P1 (MFA server-side): escrita do dinheiro exige aal2 quando o tenant
  -- do dono/funcionário ativou a exigência (venda é operação de caixa —
  -- funcionário comum incluído; leitura nunca é bloqueada).
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para vender.';
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
      -- anulação (cancel_sale) devolver o estoque aos lotes EXATOS.
      -- v_take é bigint; a coluna quantity é INTEGER — cast explícito
      -- (mesmo padrão do process_purchase).
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

-- ---------------------------------------------------------------------------
-- cancel_sale — ANULAÇÃO de venda (nível GERENCIAL: dono ou gerente)
-- ---------------------------------------------------------------------------
-- Estorno completo em UMA transação:
--   1. Guarda `is_manager_of_store` (matriz de acesso Aug 6 — anular é
--      operação de gestão, como compras; funcionário comum não anula);
--   2. Lê a venda FOR UPDATE e garante que existe e ainda está ativa
--      (anular duas vezes é um no-op);
--   3. Devolve o estoque aos lotes EXATOS consumidos (sale_lot_consumption
--      gravado pelo process_sale) — validade e custo de cada lote são
--      preservados; o total do produto (stock_quantity) sobe junto;
--   4. Cria o ESTORNO no caixa: movimento de SAÍDA no valor da venda,
--      categoria de vendas, status pago — o par (entrada original +
--      estorno) fecha o caixa em zero;
--   5. Marca a venda como 'cancelled' com cancelled_at (permanece no
--      histórico — trilha de auditoria; sai de relatórios/KPIs via filtros
--      por status nos agregados).
--
-- Mesma mecânica de segurança dos demais RPCs: SECURITY DEFINER +
-- search_path fixo + guarda explícita (o RLS não se aplica dentro da
-- função) + escopo por loja em todos os acessos.
CREATE OR REPLACE FUNCTION public.cancel_sale(p_sale_id text, p_store_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
  -- P1 (MFA server-side): anulação mexe em caixa e estoque — escrita de
  -- dinheiro (dono/gerente com aal2 quando o tenant exigir).
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para anular vendas.';
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
  -- `stock = Σ lotes` nunca quebra. A quantidade de um lote só diminui nas
  -- baixas, então devolver nunca excede o lote.
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
  -- par (entrada original + estorno) fecha o caixa em zero. Mesma
  -- tradução do helper Dart TransactionDescriptions.saleReversal.
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

-- ---------------------------------------------------------------------------
-- close_cash_register — FECHO DE CAIXA DIÁRIO (Z-report, nível GERENCIAL)
-- ---------------------------------------------------------------------------
-- Registra (ou refaz) o fecho do dia da loja em UMA transação:
--   1. Guarda `is_manager_of_store` (matriz de acesso — fecho é operação
--      de gestão, como compras e anulação; funcionário comum não fecha);
--   2. Calcula NO SERVIDOR o ESPERADO na gaveta: Σ das vendas ATIVAS
--      pagas em DINHEIRO no dia [p_day, p_day+1) — cartão/M-Pesa/E-Mola/
--      transferência não passam pela gaveta física (o cliente NUNCA
--      envia valores calculados — o servidor é a autoridade);
--   3. Calcula o total do dia (todas as formas) e a abertura por forma
--      de pagamento (JSONB) para o relatório Z;
--   4. UPSERT em cash_closings (unicidade store_id + closing_date) —
--      refazer o fecho do mesmo dia ATUALIZA a contagem física, sem
--      duplicar;
--   5. Devolve o fecho registrado (JSONB) para a UI exibir o resultado.
--
-- Mesma mecânica de segurança dos demais RPCs: SECURITY DEFINER +
-- search_path fixo + guarda explícita + escopo por loja em todos os
-- acessos.
CREATE OR REPLACE FUNCTION public.close_cash_register(
  p_store_id TEXT,
  p_day TIMESTAMPTZ,
  p_counted_cash_cents BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
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
  -- P1 (MFA server-side): fecho grava a conferência do caixa do dia.
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para fechar o caixa.';
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

-- ---------------------------------------------------------------------------
-- get_cash_closing_summary — PRÉVIA do Z-report agregada NO SERVIDOR (H2)
-- ---------------------------------------------------------------------------
-- Mesmo critério do close_cash_register, só de LEITURA: calcula em UMA
-- chamada o resumo do dia para a pré-visualização do fecho — total de
-- vendas ATIVAS do dia (todas as formas), o ESPERADO na gaveta (só
-- vendas em DINHEIRO) e a abertura por forma de pagamento (JSONB) — além
-- do fecho JÁ REGISTRADO do dia (se houver), evitando carregar o
-- histórico inteiro de vendas no cliente (escala H2, mesmo padrão do
-- get_cash_flow/get_sales_report).
--
-- Guarda is_my_store (leitura para dono/funcionários da loja — a PRÉVIA
-- não é operação gerencial; fechar é). O dia chega como início do dia
-- LOCAL em UTC (mesma semântica do close_cash_register).
CREATE OR REPLACE FUNCTION public.get_cash_closing_summary(
  p_store_id TEXT,
  p_day TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
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

CREATE OR REPLACE FUNCTION public.register_debt(p_debt jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
  -- P1 (MFA server-side): fiado cria dívida + pendência no caixa.
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para registrar fiado.';
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

-- Quitação de fiado (baixa) — espelha a semântica do SettleDebtUseCase
-- composto, mas em UMA transação no servidor: baixa da dívida + resolução
-- da pendência vinculada (ou entrada direta no caixa para fiado antigo
-- sem pendência). Idempotente: dívida já quitada não gera nova entrada.
-- Escopo por loja + tenant (além do RLS): só a dívida do próprio usuário
-- na loja informada é alcançável.
CREATE OR REPLACE FUNCTION public.settle_debt(p_debt_id text, p_store text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_debt public.debts%ROWTYPE;
  v_lang text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para quitar o fiado.';
  END IF;
  -- P1 (MFA server-side): quitação cria entrada no caixa.
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para quitar o fiado.';
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
  --    (nunca cria duplicata no caixa) e carimba a DATA DE REALIZAÇÃO
  --    (`date = now()`) — mesma semântica do datasource SQLite local
  --    (markAsPaid): o caixa realizado reconhece o dinheiro quando ele
  --    ENTRA, não quando a pendência foi registrada (auditoria Aug 6 —
  --    alinhamento entre os modos local e SaaS).
  UPDATE public.financial_transactions
  SET status = 'paid', date = now()
  WHERE debt_id = p_debt_id AND store_id = p_store
    AND status = 'pending';

  -- 3. Fiado antigo SEM nenhuma transação vinculada (pendente ou paga):
  --    registra a entrada direto. Se já existir uma transação vinculada
  --    (mesmo paga), nada é feito — idempotente. O id usa o sufixo
  --    '_settle' para nunca colidir com a pendência do register_debt
  --    ('t' || debt_id) nem com ids do AppIds ('t<ts>_<hex>').
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

CREATE OR REPLACE FUNCTION public.process_purchase(p_purchase jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
  -- P1 (MFA server-side): compra muta estoque e caixa (nível gerencial).
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para registrar compras.';
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

-- ---------------------------------------------------------------
-- 1.12 Trilha de auditoria das decisões de admin (auditoria S4)
-- ---------------------------------------------------------------
-- Regista QUEM decidiu cada tenant/upgrade (aprovar/rejeitar) — a coluna
-- `decided_by` é carimbada com o auth.uid() do super admin no momento da
-- decisão, via trigger. O RLS já restringe o UPDATE a super admins; esta
-- coluna adiciona o ator ao histórico (antes não havia rasto).
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS decided_by UUID;
ALTER TABLE IF EXISTS public.plan_requests
  ADD COLUMN IF NOT EXISTS decided_by UUID;

CREATE OR REPLACE FUNCTION public.set_decided_by()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ---------------------------------------------------------------
-- 1.12 Conta de acesso do funcionário (RPC create_employee_account)
-- ---------------------------------------------------------------
-- O dono cadastra o funcionário (nome + e-mail + senha + loja + cargo).
-- O app NÃO usa `auth.signUp` para isso: com a confirmação de e-mail
-- ATIVA no projeto, cada signUp dispara um e-mail de confirmação — o que
-- (1) sofre rate limit do provedor (`over_email_send_rate_limit`, 429 — o
-- cadastro falhava no meio do fluxo) e (2) deixava a conta PENDENTE até o
-- funcionário clicar no link (não conseguia entrar; `email_not_confirmed`).
--
-- Esta função `SECURITY DEFINER` NÃO depende de `auth.admin_create_user`:
-- o Supabase atual REMOVEU essa função interna (a Admin API do GoTrue é
-- HTTP e ASSÍNCRONA — quebraria a atomicidade e o retorno do user_id). A
-- conta é criada por INSERÇÃO DIRETA em `auth.users` + `auth.identities`
-- com hash bcrypt (pgcrypto) — síncrona e TRANSACIONAL — e o vínculo em
-- `store_employees` é criado na MESMA transação:
--   * a conta nasce confirmada (email_confirmed_at = now()), com a senha
--     escolhida pelo dono, e NENHUM e-mail é enviado — o funcionário entra
--     direto com login/senha normais (o GoTrue verifica o hash bcrypt);
--   * se o vínculo falhar (ex.: limite de funcionários do plano — trigger
--     `enforce_employee_limit`, ou loja inválida), a conta criada aqui é
--     desfeita junto — NENHUMA conta órfã fica para trás;
--   * a sessão do dono nunca é substituída (elimina o bug S1 do signUp).
--
-- ⚠️ Trade-off documentado: inserir em `auth.users` é a ÚNICA forma
-- SÍNCRONA de criar a conta com atomicidade (conta + vínculo + retorno do
-- user_id na mesma transação). As colunas usadas são as ESTÁVEIS do GoTrue
-- (id, instance_id, aud, role, email, encrypted_password,
-- email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at,
-- updated_at + a identidade de e-mail em auth.identities); `confirmed_at`
-- é coluna GERADA pelo banco (nunca inserida).
--
-- Guardas (substituem o RLS dentro da função): apenas o DONO do tenant
-- (auth.uid() dono da loja informada); senha mínima de 8 caracteres
-- (política M7); cargo válido; e-mail duplicado vira mensagem amigável.
-- Idempotente: o id do vínculo (p_employee_id) é a chave — retry após
-- sucesso devolve o MESMO user_id sem duplicar nada.
--
-- A versão antiga (apenas conta, sem vínculo — 3 parâmetros) é removida
-- para não ficar sobrecarregada no banco.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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
SET search_path = pg_catalog, public, extensions
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

-- ----------------------------------------------------------------------------
-- Ativar/desativar funcionário (dono).
--
-- SECURITY DEFINER + guarda is_tenant_owner: apenas o DONO do tenant do
-- vínculo muda o status (a política store_employees_update já limita o
-- UPDATE ao dono, mas a guarda aqui torna a intenção explícita e resiliente
-- a mudanças futuras de política). Funcionário DESATIVADO (is_active
-- FALSE) perde o acesso imediatamente: `is_my_store`/`is_manager_of_store`
-- exigem vínculo ativo, então RLS e guardas das RPCs negam TUDO nas lojas.
--
-- Parâmetros: p_employee_id (id do vínculo), p_is_active (novo status).
-- Idempotente: atualizar com o mesmo status não falha.
CREATE OR REPLACE FUNCTION public.set_employee_active(
  p_employee_id TEXT,
  p_is_active BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ============================================================================
-- FOTOS DE PRODUTO — Supabase Storage
-- ============================================================================
-- Bucket PÚBLICO com as imagens dos produtos. O app sobe a foto com o JWT
-- do usuário (storage.objects policies abaixo) e grava a URL pública em
-- products.image_path — o banco relacional nunca guarda o blob.
--
-- ⚠️ CONVENÇÃO DE CAMINHO: `<storeId>/<productId>.jpg` — o PRIMEIRO
-- segmento É o store_id, pois as políticas de escrita validam
-- `is_my_store((storage.foldername(name))[1])`. O cliente (IProductImageStore
-- modo Supabase) obedece a esta convenção; nunca troque o primeiro segmento
-- por um prefixo fixo (ex.: `products/...`) sem ajustar as políticas abaixo.
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', TRUE)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS product_images_public_read ON storage.objects;
-- ⚠️ Leitura SEM listing (linter 0025 public_bucket_allows_listing): a
-- policy devolve TRUE só quando o NOME exato do objeto é conhecido —
-- `name = ((storage.foldername(name))[1] || '/' ||
-- (storage.foldername(name))[2])` é sempre verdadeiro para o próprio
-- path avaliado, então o efeito prático é "acesso direto a um objeto
-- conhecido, sem enumeration". O PostgREST do Storage só devolve a
-- LISTAGEM de pastas quando a policy aceita linhas que o cliente NÃO
-- nomeou (ex.: bucket_id = 'product-images' sozinho) — com a comparação
-- self-referente, LIST/`list()`/`search()` fica vazio e o GET por URL
-- pública continua funcionando (a leitura pública do CDN não passa por
-- esta policy de SQL; vale para o Storage API).
-- O app NUNCA lista o bucket (Image.network no path exato gravado em
-- products.image_path) — não há regressão funcional.
CREATE POLICY product_images_public_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'product-images'
    AND name = ((storage.foldername(name))[1] || '/' ||
                (storage.foldername(name))[2])
  );

-- Escrita SÓ na loja do usuário: o path é `<storeId>/<prod>.jpg` —
-- (foldername(name))[1] = storeId, a MESMA guarda is_my_store das RPCs
-- (o servidor é a autoridade; um cliente adulterado não sobe foto em
-- pasta de outra loja). A leitura é pública (URL pública via CDN).
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
-- PARTE 1.9 — ADD-ONS, FATURAÇÃO (billing) E MENSAGENS ADMIN [consolidada]
-- ============================================================================
-- Objetos das migrações 20260902–20260905 e 020/021/023, FUNDIDOS no schema
-- base para que uma instalação NOVA fique completa com UM ÚNICO script
-- (auditoria Set/2026 — consolidação de 13 SQL em 2). Fontes arquivadas em
-- `supabase/archived_migrations/`; bases EXISTENTES recebem os mesmos
-- objetos pela PARTE 31 do `upgrade.sql`.
--
-- Conteúdo:
--   1.9.1  tenant_addons          — add-ons contratados por tenant (020/20260902);
--   1.9.2  custom_invoices        — facturas personalizadas (20260905);
--   1.9.3  quotations             — cotações/orçamentos (20260905);
--   1.9.4  employee_mgmt          — ponto, comissões, metas (20260905);
--   1.9.5  invoices + billing     — cobrança mensal e notificações (021);
--   1.9.6  admin_messages         — mensagens do super admin (023).
--
-- Idempotente: CREATE TABLE IF NOT EXISTS, ADD COLUMN IF NOT EXISTS,
-- DROP POLICY IF EXISTS + CREATE POLICY, DROP TRIGGER IF EXISTS + CREATE
-- TRIGGER, CREATE OR REPLACE FUNCTION, Realtime com guarda
-- pg_publication_tables. Requer as funções/objetos das seções 1.x
-- (set_tenant_user_id, set_record_store_id, is_my_store, is_tenant_owner,
-- is_super_admin, store_employees.is_active) — definidas ACIMA.
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
-- ⚠️ NÃO consultar public.super_admins DIRETAMENTE dentro da policy:
-- a tabela tem REVOKE ALL de anon/authenticated (defesa anti-auto-promoção)
-- e o Postgres nega com 42501 'permission denied for table super_admins'
-- ANTES de avaliar o RLS (bug de produção Set/2026 — painel admin não
-- conseguia ativar add-on). A função SECURITY DEFINER is_super_admin()
-- lê a tabela como dono do schema — mesmo padrão das demais políticas
-- (plans/plan_requests/tenants) e RPCs administrativas.
CREATE POLICY tenant_addons_super_admin_all
  ON public.tenant_addons
  FOR ALL
  USING (
    public.is_super_admin()
  )
  WITH CHECK (
    public.is_super_admin()
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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
--                               id gerado PELO APP (AppIds.newId('att')) —
--                               TEXT PRIMARY KEY sem default: INSERT sem
--                               id falha com 23502 (null value in "id");
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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
    -- CAST OBRIGATÓRIO: SUM(bigint) devolve NUMERIC no Postgres e o
    -- RETURNS TABLE declara BIGINT — sem o cast a RPC falha com 42804
    -- "Returned type numeric does not match expected type bigint"
    -- (aba Comissões: "não foi possível carregar funcionários").
    COALESCE(SUM(s.total_amount) FILTER (
      WHERE s.status = 'active'
    ), 0)::BIGINT AS sales_cents,
    COALESCE(r.rate_bps, 0) AS rate_bps,
    (COALESCE(SUM(s.total_amount) FILTER (
      WHERE s.status = 'active'
    ), 0)::BIGINT) * COALESCE(r.rate_bps, 0) / 10000 AS commission_cents
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
SET search_path = pg_catalog, public
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
SET search_path = pg_catalog, public
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

-- ============================================================================
-- PARTE 2 — CATÁLOGO DE PLANOS DE ASSINATURA (dados reais, não demo)
-- ============================================================================
-- O ERP NÃO semeia mais dados de demonstração (produtos, vendas, clientes,
-- fiados, compras, tenant demo etc.): cada tenant começa VAZIO e registra
-- apenas dados reais criados pelo usuário (auditoria M1 — seed removido).
-- O que esta parte insere é a tabela de preços real — os MESMOS planos do
-- catálogo local (PlanCatalog no app, pl1/pl2/pl3) — sem os quais o
-- onboarding do dono não teria o que oferecer. Idempotente: ON CONFLICT
-- (id) DO NOTHING.
INSERT INTO public.plans
  (id, name, description, price_monthly, max_stores, max_employees, is_active)
VALUES
  ('pl1', 'Essencial', 'Para começar: 1 loja e até 3 funcionários.', 50000, 1, 3, TRUE),
  ('pl2', 'Profissional', 'Para crescer: 3 lojas e até 10 funcionários.', 100000, 3, 10, TRUE),
  ('pl3', 'Empresa', 'Para expandir: 10 lojas e até 50 funcionários.', 200000, 10, 50, TRUE)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- PARTE 3 — ENDURECIMENTO DE PRODUÇÃO (sem alteração da lógica funcional)
-- ============================================================================
-- Esta seção é deliberadamente aditiva e idempotente. Ela não muda fluxos,
-- cálculos, permissões de negócio ou estados aceitos pelo aplicativo; apenas
-- impede forja de escopo, melhora o plano das políticas RLS e fecha privilégios
-- excessivos típicos de instalações Supabase.

-- 3.1 Proteção de escopo em UPDATE.
-- INSERT já é protegido pelos triggers existentes; sem este guard, um cliente
-- poderia mover uma linha para outra loja/usuário através de UPDATE.
CREATE OR REPLACE FUNCTION public.prevent_scope_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_ARGV[0] = 'user_id' AND NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'user_id não pode ser alterado após a criação do registro.';
  END IF;
  IF TG_ARGV[0] = 'store_id' AND NEW.store_id IS DISTINCT FROM OLD.store_id THEN
    RAISE EXCEPTION 'store_id não pode ser alterado após a criação do registro.';
  END IF;
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'products','sales','financial_transactions','cash_closings','debts',
    'customers','purchases','stock_lots'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_scope_guard ON public.%I', v_table, v_table);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_scope_guard BEFORE UPDATE OF user_id, store_id ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.prevent_scope_change(%L)',
      v_table, v_table, 'user_id'
    );
    EXECUTE format(
      'CREATE TRIGGER trg_%I_store_scope_guard BEFORE UPDATE OF store_id ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.prevent_scope_change(%L)',
      v_table, v_table, 'store_id'
    );
  END LOOP;
END
$$;

-- Os filhos sem store_id herdam o escopo da entidade pai; estes guards
-- impedem trocar o pai/usuário depois da criação.
DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY['sale_items','sale_lot_consumption','purchase_items'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_scope_guard ON public.%I', v_table, v_table);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_scope_guard BEFORE UPDATE OF user_id ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.prevent_scope_change(%L)',
      v_table, v_table, 'user_id'
    );
  END LOOP;
END
$$;

-- 3.2 Consistência estrutural futura: constraints NOT VALID preservam dados
-- legados possivelmente inconsistentes, mas bloqueiam novas violações. A
-- validação completa pode ser executada separadamente após saneamento.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_sales_cancelled_at_consistent') THEN
    ALTER TABLE public.sales ADD CONSTRAINT ck_sales_cancelled_at_consistent
      CHECK ((status = 'cancelled' AND cancelled_at IS NOT NULL)
          OR (status = 'active' AND cancelled_at IS NULL)) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_products_nonblank_name') THEN
    ALTER TABLE public.products ADD CONSTRAINT ck_products_nonblank_name
      CHECK (btrim(name) <> '') NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_tenants_nonblank_business_name') THEN
    ALTER TABLE public.tenants ADD CONSTRAINT ck_tenants_nonblank_business_name
      CHECK (btrim(business_name) <> '') NOT VALID;
  END IF;
END
$$;

-- 3.3 Índices alinhados às predicates mais frequentes do RLS e dos RPCs.
CREATE INDEX IF NOT EXISTS idx_products_store_active
  ON public.products (store_id, is_active, id);
CREATE INDEX IF NOT EXISTS idx_sales_store_status_datetime
  ON public.sales (store_id, status, date_time DESC);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_store_status_date
  ON public.financial_transactions (store_id, status, date DESC);
CREATE INDEX IF NOT EXISTS idx_debts_store_unpaid
  ON public.debts (store_id, is_paid) WHERE is_paid = FALSE;
CREATE INDEX IF NOT EXISTS idx_stock_lots_store_product_fifo
  ON public.stock_lots (store_id, product_id, expiry_date ASC, entry_date ASC, id)
  WHERE current_quantity > 0;
CREATE INDEX IF NOT EXISTS idx_store_employees_active_store_user
  ON public.store_employees (store_id, user_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_store_employees_active_tenant
  ON public.store_employees (tenant_id) WHERE is_active = TRUE;

-- 3.4 SECURITY DEFINER: nenhum endpoint SQL fica exposto ao papel anon.
-- authenticated mantém a capacidade necessária ao PostgREST/RPC. O grant
-- condicional para service_role mantém automações administrativas compatíveis.
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role';
  END IF;
END
$$;

-- 3.5 Defaults de segurança para novos objetos criados depois desta instalação.
-- Não revoga acesso já concedido às tabelas; apenas evita que funções futuras
-- nasçam executáveis por PUBLIC por acidente.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated';
  END IF;
END
$$;

-- 3.7 Funções INTERNAS fora do PostgREST (linter 0029 — Sep 2026):
-- triggers e helpers que o app NUNCA chama via /rest/v1/rpc perdem o EXECUTE
-- de anon/authenticated (o 3.4 concede TUDO a authenticated; aqui recortamos
-- a superfície que não é API). A chamada INTERNA (trigger ou corpo de outra
-- função) NÃO depende do grant de EXECUTE do chamador — somente chamadas
-- diretas pelo PostgREST. Idempotente: revogar é no-op.
--
-- ⚠️ NÃO revogar aqui os helpers citados DENTRO de expressões de policy RLS
-- (is_my_store, is_tenant_owner, is_manager_of_store,
-- is_store_employee_active, mfa_ok) nem is_super_admin(): a policy é
-- avaliada com os privilégios do papel que CONSULTA a tabela — SECURITY
-- DEFINER muda os privilégios dentro do corpo da função, não o direito de
-- chamá-la. Sem o EXECUTE, toda leitura/escrita das tabelas protegidas por
-- esses helpers falha com 42501 "permission denied for function". O WARN
-- 0029 remanescente desses helpers é aceito (guards booleanas, sem dados).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_record_store_id() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_tenant_user_id() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_store_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_tenant_owner() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_employee_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_employee_attendance_actor() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_invoice_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_custom_invoice_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_quotation_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_decided_by() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_plan_request_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.log_audit_entry() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.prevent_scope_change() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.enforce_store_limit() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.enforce_employee_limit() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.lock_products_or_raise(jsonb, text, boolean) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_invoice_number(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_custom_invoice_number(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_quotation_number(text) FROM anon, authenticated';
    -- Helpers MFA internos: chamados dentro de mfa_ok()/update_tenant_settings
    -- (contexto SECURITY DEFINER) — não são API e não aparecem em policies.
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_enforced_for_user(uuid) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_verified_factor_count(uuid) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_satisfied(uuid) FROM anon, authenticated';
  END IF;
  -- Corretivo idempotente p/ bases onde o fix de Sep/2026 revogou os helpers
  -- de policy (o linter 0029 deixa de apontá-los, mas o app quebra com 42501
  -- "permission denied for function" em toda leitura/escrita).
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    IF to_regprocedure('public.is_my_store(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_my_store(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_tenant_owner(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_tenant_owner(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_manager_of_store(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_manager_of_store(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_store_employee_active(text, uuid)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_store_employee_active(text, uuid) TO authenticated';
    END IF;
    IF to_regprocedure('public.mfa_ok(uuid)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.mfa_ok(uuid) TO authenticated';
    END IF;
  END IF;
END
$$;
-- Nota: get_audit_log é chamada PELO APP (painel admin) e fica exposta —
-- a guarda is_super_admin() dentro dela é a autoridade.

-- 3.6 Estatísticas úteis após instalação/migração. ANALYZE não altera dados.
ANALYZE public.products;
ANALYZE public.sales;
ANALYZE public.financial_transactions;
ANALYZE public.store_employees;

COMMIT;

