-- ============================================================================
-- Dumbhanengue ERP — Schema do banco no Supabase (PostgreSQL)
-- ============================================================================
-- Como usar:
--   1. Abra o SQL Editor do seu projeto:
--      https://supabase.com/dashboard/project/dotklbpqmlnhcdifiukd/sql/new
--   2. Cole TODO o script e execute (o comando "Run").
--   3. A Parte 1 (estrutura) é idempotente e pode ser executada a qualquer
--      momento. A Parte 2 (seed demo) insere dados para o PRIMEIRO usuário
--      encontrado em auth.users — se ainda não houver nenhum usuário, ela
--      não insere nada (basta reexecutá-la depois de se cadastrar no app).
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
  purchase_price NUMERIC(12, 2) NOT NULL CHECK (purchase_price >= 0),
  sale_price     NUMERIC(12, 2) NOT NULL CHECK (sale_price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

-- Vendas (espelha a entidade Sale) — store_id: histórico por loja.
CREATE TABLE IF NOT EXISTS public.sales (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL DEFAULT 'st1',
  total_amount   NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
  payment_method TEXT NOT NULL CHECK (payment_method IN
    ('cash', 'debitCard', 'creditCard', 'pix', 'transfer')),
  date_time      TIMESTAMPTZ NOT NULL
);

-- Itens de venda (espelha a entidade SaleItem — snapshot de nome/preço)
CREATE TABLE IF NOT EXISTS public.sale_items (
  id           BIGSERIAL PRIMARY KEY,
  sale_id      TEXT NOT NULL REFERENCES public.sales (id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id   TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity > 0),
  unit_price   NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
  UNIQUE (sale_id, product_id)
);

-- Movimentações financeiras (espelha a entidade FinancialTransaction) —
-- store_id: o caixa é por loja.
CREATE TABLE IF NOT EXISTS public.financial_transactions (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id    TEXT NOT NULL DEFAULT 'st1',
  description TEXT NOT NULL,
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  type        TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category    TEXT NOT NULL,
  date        TIMESTAMPTZ NOT NULL,
  status      TEXT NOT NULL DEFAULT 'paid' CHECK (status IN ('paid', 'pending')),
  debt_id     TEXT
);

-- Dívidas / "fiado" (espelha a entidade Debt)
-- (coluna customer_id adicionada também via ALTER para bancos já criados
--  antes do módulo de clientes — idempotente)
ALTER TABLE IF EXISTS public.debts
  ADD COLUMN IF NOT EXISTS customer_id TEXT;
CREATE TABLE IF NOT EXISTS public.debts (
  id              TEXT PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id        TEXT NOT NULL DEFAULT 'st1',
  person_name     TEXT NOT NULL,
  amount          NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
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
CREATE TABLE IF NOT EXISTS public.purchases (
  id            TEXT PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id      TEXT NOT NULL DEFAULT 'st1',
  supplier_name TEXT NOT NULL,
  total_amount  NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
  date_time     TIMESTAMPTZ NOT NULL
);

-- Itens de compra (espelha a entidade PurchaseItem — snapshot de nome/preço)
CREATE TABLE IF NOT EXISTS public.purchase_items (
  id           BIGSERIAL PRIMARY KEY,
  purchase_id  TEXT NOT NULL REFERENCES public.purchases (id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id   TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity > 0),
  unit_price   NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
  UNIQUE (purchase_id, product_id)
);

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
  price_monthly NUMERIC(10, 2) NOT NULL DEFAULT 0
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
  -- `language` ∈ ('pt', 'en') — o app só usa esses dois valores.
  currency_code    TEXT NOT NULL DEFAULT 'BRL'
                    CHECK (currency_code IN ('BRL', 'USD', 'EUR', 'MZN')),
  language         TEXT NOT NULL DEFAULT 'pt'
                    CHECK (language IN ('pt', 'en'))
);

-- Migração idempotente para bancos já criados (CREATE TABLE IF NOT EXISTS
-- não altera tabelas existentes): adiciona as colunas com defaults.
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'BRL';
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'pt';

-- Lojas de um tenant — cada loja terá seus funcionários e, na Fase 2,
-- seu próprio estoque e vendas (escopo por store_id).
CREATE TABLE IF NOT EXISTS public.stores (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL REFERENCES public.tenants (id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  address    TEXT NOT NULL DEFAULT '',
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
ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items         ENABLE ROW LEVEL SECURITY;

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
SET search_path = public
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

-- sales
DROP POLICY IF EXISTS sales_select ON public.sales;
CREATE POLICY sales_select ON public.sales
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS sales_insert ON public.sales;
CREATE POLICY sales_insert ON public.sales
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS sales_update ON public.sales;
CREATE POLICY sales_update ON public.sales
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
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
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_items_update ON public.sale_items;
CREATE POLICY sale_items_update ON public.sale_items
  FOR UPDATE USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
    )
  ) WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.sales s
      WHERE s.id = sale_items.sale_id AND public.is_my_store(s.store_id)
    )
  );
DROP POLICY IF EXISTS sale_items_delete ON public.sale_items;
-- DELETE só de registros PRÓPRIOS (o app não exclui nada).
CREATE POLICY sale_items_delete ON public.sale_items
  FOR DELETE USING (auth.uid() = user_id);

-- financial_transactions
DROP POLICY IF EXISTS financial_transactions_select ON public.financial_transactions;
CREATE POLICY financial_transactions_select ON public.financial_transactions
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS financial_transactions_insert ON public.financial_transactions;
CREATE POLICY financial_transactions_insert ON public.financial_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS financial_transactions_update ON public.financial_transactions;
CREATE POLICY financial_transactions_update ON public.financial_transactions
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS financial_transactions_delete ON public.financial_transactions;
-- DELETE só de registros PRÓPRIOS: o app não exclui nada (zero
-- impacto) e impede um cliente direto de destruir registros de
-- outro usuário da loja (endurecimento pós-auditoria C2).
CREATE POLICY financial_transactions_delete ON public.financial_transactions
  FOR DELETE USING (auth.uid() = user_id);

-- debts
DROP POLICY IF EXISTS debts_select ON public.debts;
CREATE POLICY debts_select ON public.debts
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS debts_insert ON public.debts;
CREATE POLICY debts_insert ON public.debts
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
DROP POLICY IF EXISTS debts_update ON public.debts;
CREATE POLICY debts_update ON public.debts
  FOR UPDATE USING (auth.uid() = user_id OR public.is_my_store(store_id))
  WITH CHECK (auth.uid() = user_id OR public.is_my_store(store_id));
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
DROP POLICY IF EXISTS purchases_select ON public.purchases;
CREATE POLICY purchases_select ON public.purchases
  FOR SELECT USING (auth.uid() = user_id OR public.is_my_store(store_id));
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
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_update ON public.purchases;
CREATE POLICY purchases_update ON public.purchases
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id));
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
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id
  ON public.sale_items (sale_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user_date
  ON public.financial_transactions (user_id, date);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_store
  ON public.financial_transactions (store_id);
-- Resolução de pendências vinculadas (settle_debt/register_debt).
CREATE INDEX IF NOT EXISTS idx_financial_transactions_debt
  ON public.financial_transactions (debt_id);
CREATE INDEX IF NOT EXISTS idx_debts_user_due
  ON public.debts (user_id, due_date);
CREATE INDEX IF NOT EXISTS idx_debts_store
  ON public.debts (store_id);
CREATE INDEX IF NOT EXISTS idx_customers_user_name
  ON public.customers (user_id, name);
CREATE INDEX IF NOT EXISTS idx_customers_store
  ON public.customers (store_id);
CREATE INDEX IF NOT EXISTS idx_purchases_user_datetime
  ON public.purchases (user_id, date_time DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_store
  ON public.purchases (store_id);
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
SET search_path = public
AS $$
BEGIN
  -- Só força o valor quando há sessão (JWT). No SQL Editor (sem sessão),
  -- o valor informado é preservado — permite o seed da Parte 2.
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

DROP TRIGGER IF EXISTS trg_financial_transactions_user_id
  ON public.financial_transactions;
CREATE TRIGGER trg_financial_transactions_user_id
  BEFORE INSERT ON public.financial_transactions
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
-- informado é preservado — permite o seed da Parte 2.

-- Helper: o usuário é dono do tenant [tenantId]? (definido na seção 1.2b —
-- o RLS da seção 1.7 também o usa).

CREATE OR REPLACE FUNCTION public.set_record_store_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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


-- ---------------------------------------------------------------
-- 1.7 RLS das tabelas da Camada de Contas
-- ---------------------------------------------------------------
ALTER TABLE public.plans           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_requests   ENABLE ROW LEVEL SECURITY;

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
SET search_path = public
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

-- Leitura: apenas o super admin (guarda dentro da própria RPC — o papel
-- anon/authenticated não tem permissão de tabela e o RLS não tem
-- políticas; o SECURITY DEFINER + guarda fecham a porta).
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
  total_sales   NUMERIC(14, 2),
  cash_income   NUMERIC(14, 2),
  cash_expense  NUMERIC(14, 2),
  pending_total NUMERIC(14, 2),
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
              WHERE s.store_id = p_store_id), 0),
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'income'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0),
    COALESCE((SELECT SUM(t.amount) FROM public.financial_transactions t
              WHERE t.store_id = p_store_id AND t.type = 'expense'
                AND t.status = 'paid'
                AND t.date >= p_start AND t.date <= p_end), 0),
    COALESCE((SELECT SUM(d.amount) FROM public.debts d
              WHERE d.store_id = p_store_id
                AND d.is_customer_debt = TRUE AND d.is_paid = FALSE), 0),
    COALESCE((SELECT SUM(p.stock_quantity) FROM public.products p
              WHERE p.store_id = p_store_id), 0);
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
SET search_path = public
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
SET search_path = public
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
SET search_path = public
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
SET search_path = public
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
SET search_path = public
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
SET search_path = public
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
  SELECT CASE WHEN p_lang = 'en' THEN
      CASE p_method
        WHEN 'cash' THEN 'Cash' WHEN 'debitCard' THEN 'Debit card'
        WHEN 'creditCard' THEN 'Credit card' WHEN 'pix' THEN 'Pix'
        WHEN 'transfer' THEN 'Bank transfer' ELSE p_method END
    ELSE
      CASE p_method
        WHEN 'cash' THEN 'Dinheiro' WHEN 'debitCard' THEN 'Cartão de débito'
        WHEN 'creditCard' THEN 'Cartão de crédito' WHEN 'pix' THEN 'Pix'
        WHEN 'transfer' THEN 'Transferência' ELSE p_method END
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
SET search_path = public
AS $$
DECLARE
  v_item jsonb;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    IF p_require_stock THEN
      PERFORM 1 FROM public.products
        WHERE id = (v_item->>'product_id') AND store_id = p_store
          AND stock_quantity >= (v_item->>'quantity')::int
        FOR UPDATE;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Estoque insuficiente para o produto % (loja %).',
          v_item->>'product_id', p_store;
      END IF;
    ELSE
      PERFORM 1 FROM public.products
        WHERE id = (v_item->>'product_id') AND store_id = p_store
        FOR UPDATE;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto % não existe no catálogo da loja %.',
          v_item->>'product_id', p_store;
      END IF;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_sale(p_sale jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_sale->>'store_id';
  v_total numeric := (p_sale->>'total_amount')::numeric;
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

  -- Total deve corresponder aos itens (comparação em centavos).
  IF ROUND((SELECT SUM((x->>'quantity')::numeric * (x->>'unit_price')::numeric)
            FROM jsonb_array_elements(p_items) x) * 100)
     <> ROUND(v_total * 100) THEN
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
         (x->>'quantity')::int, (x->>'unit_price')::numeric
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
  IF (p_debt->>'amount')::numeric <= 0 THEN
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
          (p_debt->>'amount')::numeric, (p_debt->>'due_date')::timestamptz,
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
          (p_debt->>'amount')::numeric,
          CASE WHEN v_customer_debt THEN 'income' ELSE 'expense' END,
          CASE WHEN v_lang = 'en' THEN 'Credit' ELSE 'Fiado' END,
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
            CASE WHEN v_lang = 'en'
                 THEN 'Credit received — ' || v_debt.person_name
                 ELSE 'Recebimento de fiado — ' || v_debt.person_name END,
            v_debt.amount, 'income',
            CASE WHEN v_lang = 'en' THEN 'Credit' ELSE 'Fiado' END,
            now(), 'paid', p_debt_id);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_purchase(p_purchase jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_purchase->>'store_id';
  v_total numeric := (p_purchase->>'total_amount')::numeric;
  v_lang text;
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

  IF ROUND((SELECT SUM((x->>'quantity')::numeric * (x->>'unit_price')::numeric)
            FROM jsonb_array_elements(p_items) x) * 100)
     <> ROUND(v_total * 100) THEN
    RAISE EXCEPTION 'O total da compra não corresponde aos itens.';
  END IF;

  -- Valida e trava a existência de TODOS os produtos ANTES de mutar
  -- (mesmo padrão do process_sale; fecha corrida com exclusão).
  PERFORM public.lock_products_or_raise(p_items, v_store, FALSE);

  -- Compra + itens.
  INSERT INTO public.purchases
    (id, user_id, store_id, supplier_name, total_amount, date_time)
  VALUES (p_purchase->>'id', v_uid, v_store, p_purchase->>'supplier_name',
          v_total, (p_purchase->>'date_time')::timestamptz);

  INSERT INTO public.purchase_items
    (purchase_id, user_id, product_id, product_name, quantity, unit_price)
  SELECT p_purchase->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::numeric
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
-- PARTE 2 — DADOS DE DEMONSTRAÇÃO (SEED)
-- ============================================================================
-- Os INSERTs abaixo usam `SELECT ... FROM auth.users u LIMIT 1` como fonte:
-- o user_id vira o do PRIMEIRO usuário da lista. Se ainda não existe nenhum
-- usuário, nenhuma linha é inserida — rode esta parte novamente depois de se
-- cadastrar no app (ou troque a subconsulta pelo seu UUID de
-- Authentication → Users).
-- As datas são relativas a now() para os períodos (Hoje/7 dias/Mês) baterem.
-- Idempotente: ON CONFLICT (id) DO NOTHING.
-- ============================================================================

-- Produtos (7 — 5 na Loja Centro st1, 2 na Loja Shopping st2 para
-- demonstrar o escopo por loja)
INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p1', u.id, 'st1', 'Caneta esferográfica', 'Azul, ponta 0.7mm', 1.0, 2.0, 100
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p2', u.id, 'st1', 'Caderno 96 folhas', 'Capa dura, pautado', 5.0, 9.9, 50
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p3', u.id, 'st1', 'Arroz 5kg', 'Tipo 1', 18.0, 24.0, 30
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p4', u.id, 'st1', 'Refrigerante 2L', 'Cola', 6.0, 8.5, 20
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p5', u.id, 'st1', 'Sabonete', 'Neutro 90g', 1.5, 3.0, 4
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p6', u.id, 'st2', 'Café torrado 500g', 'Grãos selecionados', 12.0, 19.9, 15
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.products
  (id, user_id, store_id, name, description, purchase_price, sale_price, stock_quantity)
SELECT 'p7', u.id, 'st2', 'Água mineral 1.5L', 'Garrafa', 1.5, 3.5, 24
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Vendas (4 — 3 na Loja Centro st1, 1 na Loja Shopping st2)
INSERT INTO public.sales (id, user_id, store_id, total_amount, payment_method, date_time)
SELECT 's1', u.id, 'st1', 13.9, 'pix', now() - interval '2 hours'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.sales (id, user_id, store_id, total_amount, payment_method, date_time)
SELECT 's2', u.id, 'st1', 24.0, 'cash', now() - interval '1 day'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.sales (id, user_id, store_id, total_amount, payment_method, date_time)
SELECT 's3', u.id, 'st1', 17.0, 'debitCard', now() - interval '3 days'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.sales (id, user_id, store_id, total_amount, payment_method, date_time)
SELECT 's4', u.id, 'st2', 19.9, 'pix', now() - interval '1 day'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Itens das vendas (idempotente via UNIQUE (sale_id, product_id))
INSERT INTO public.sale_items
  (sale_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 's1', u.id, 'p1', 'Caneta esferográfica', 2, 2.0
FROM auth.users u LIMIT 1
ON CONFLICT (sale_id, product_id) DO NOTHING;

INSERT INTO public.sale_items
  (sale_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 's1', u.id, 'p2', 'Caderno 96 folhas', 1, 9.9
FROM auth.users u LIMIT 1
ON CONFLICT (sale_id, product_id) DO NOTHING;

INSERT INTO public.sale_items
  (sale_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 's2', u.id, 'p3', 'Arroz 5kg', 1, 24.0
FROM auth.users u LIMIT 1
ON CONFLICT (sale_id, product_id) DO NOTHING;

INSERT INTO public.sale_items
  (sale_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 's3', u.id, 'p4', 'Refrigerante 2L', 2, 8.5
FROM auth.users u LIMIT 1
ON CONFLICT (sale_id, product_id) DO NOTHING;

INSERT INTO public.sale_items
  (sale_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 's4', u.id, 'p6', 'Café torrado 500g', 1, 19.9
FROM auth.users u LIMIT 1
ON CONFLICT (sale_id, product_id) DO NOTHING;

-- Movimentações financeiras (10 — 9 na Loja Centro st1, 1 na Shopping st2)
INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't1', u.id, 'st1', 'Venda via PIX', 13.9, 'income', 'Vendas',
       now() - interval '2 hours', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't2', u.id, 'st1', 'Energia elétrica', 180, 'expense', 'Contas',
       now() - interval '5 hours', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't3', u.id, 'st1', 'Venda em dinheiro', 24.0, 'income', 'Vendas',
       now() - interval '1 day', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Pendência de fiado vinculada à dívida d1 (a baixa marca a MESMA transação)
INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't4', u.id, 'st1', 'Venda fiado (João)', 25.0, 'income', 'Fiado',
       now() - interval '1 day', 'pending', 'd1'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't5', u.id, 'st1', 'Aluguel da loja', 900, 'expense', 'Contas',
       now() - interval '2 days', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't6', u.id, 'st1', 'Venda no débito', 17.0, 'income', 'Vendas',
       now() - interval '3 days', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't7', u.id, 'st1', 'Compra de mercadoria', 320, 'expense', 'Compras',
       now() - interval '4 days', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Saídas das compras demo (pc1 = 210, pc2 = 150)
INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't8', u.id, 'st1', 'Compra — Distribuidora Norte', 210, 'expense', 'Compras',
       now() - interval '4 days', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't9', u.id, 'st1', 'Compra — Fornecedor Central', 150, 'expense', 'Compras',
       now() - interval '8 days', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.financial_transactions
  (id, user_id, store_id, description, amount, type, category, date, status, debt_id)
SELECT 't10', u.id, 'st2', 'Venda via PIX (Shopping)', 19.9, 'income', 'Vendas',
       now() - interval '1 day', 'paid', NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Clientes (4 — todos da Loja Centro st1)
INSERT INTO public.customers (id, user_id, store_id, name, phone, email)
SELECT 'c1', u.id, 'st1', 'João da Silva', '(11) 99911-1111', 'joao@email.com'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.customers (id, user_id, store_id, name, phone, email)
SELECT 'c2', u.id, 'st1', 'Maria Souza', '(11) 98822-2222', 'maria@email.com'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.customers (id, user_id, store_id, name, phone, email)
SELECT 'c3', u.id, 'st1', 'Pedro Alves', '(11) 97733-3333', 'pedro@email.com'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.customers (id, user_id, store_id, name, phone, email)
SELECT 'c4', u.id, 'st1', 'Ana Lima', '(11) 96644-4444', 'ana@email.com'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Compras (2 — Loja Centro st1) + itens
INSERT INTO public.purchases
  (id, user_id, store_id, supplier_name, total_amount, date_time)
SELECT 'pc1', u.id, 'st1', 'Distribuidora Norte', 210, now() - interval '4 days'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.purchase_items
  (purchase_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 'pc1', u.id, 'p3', 'Arroz 5kg', 10, 18.0
FROM auth.users u LIMIT 1
ON CONFLICT (purchase_id, product_id) DO NOTHING;

INSERT INTO public.purchase_items
  (purchase_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 'pc1', u.id, 'p4', 'Refrigerante 2L', 5, 6.0
FROM auth.users u LIMIT 1
ON CONFLICT (purchase_id, product_id) DO NOTHING;

INSERT INTO public.purchases
  (id, user_id, store_id, supplier_name, total_amount, date_time)
SELECT 'pc2', u.id, 'st1', 'Fornecedor Central', 150, now() - interval '8 days'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.purchase_items
  (purchase_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 'pc2', u.id, 'p1', 'Caneta esferográfica', 50, 1.0
FROM auth.users u LIMIT 1
ON CONFLICT (purchase_id, product_id) DO NOTHING;

INSERT INTO public.purchase_items
  (purchase_id, user_id, product_id, product_name, quantity, unit_price)
SELECT 'pc2', u.id, 'p2', 'Caderno 96 folhas', 20, 5.0
FROM auth.users u LIMIT 1
ON CONFLICT (purchase_id, product_id) DO NOTHING;

-- ---------------------------------------------------------------
-- Camada de Contas: planos + tenant demo Aprovado para o primeiro usuário
-- ---------------------------------------------------------------
-- Planos (3) — os MESMOS limites do DemoSeed local (pl1/pl2/pl3).
INSERT INTO public.plans
  (id, name, description, price_monthly, max_stores, max_employees, is_active)
VALUES
  ('pl1', 'Essencial', 'Para começar: 1 loja e até 3 funcionários.', 49, 1, 3, TRUE),
  ('pl2', 'Profissional', 'Para crescer: 3 lojas e até 10 funcionários.', 99, 3, 10, TRUE),
  ('pl3', 'Empresa', 'Para expandir: 10 lojas e até 50 funcionários.', 199, 10, 50, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Tenant demo JÁ APROVADO para o primeiro usuário (dono) — assim o app
-- abre direto na área de gestão, com loja e funcionário de exemplo.
-- Para testar o fluxo de aprovação, cadastre uma NOVA conta.
INSERT INTO public.tenants
  (id, owner_user_id, business_name, plan_id, status, approved_at, created_at)
SELECT 'tn_demo', u.id, 'Comercial Dumbhanengue', 'pl2', 'approved', now(),
       now() - interval '30 days'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Lojas demo do tenant demo (st1 = Loja Centro, st2 = Loja Shopping) —
-- duas lojas para demonstrar o seletor e o escopo por store_id da Fase 2.
INSERT INTO public.stores (id, tenant_id, name, address)
SELECT 'st1', 'tn_demo', 'Loja Centro', 'Av. Principal, 100'
WHERE EXISTS (SELECT 1 FROM public.tenants WHERE id = 'tn_demo')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.stores (id, tenant_id, name, address)
SELECT 'st2', 'tn_demo', 'Loja Shopping', 'Rua das Flores, 250'
WHERE EXISTS (SELECT 1 FROM public.tenants WHERE id = 'tn_demo')
ON CONFLICT (id) DO NOTHING;

-- Funcionário demo: o próprio dono como gerente da Loja Centro.
INSERT INTO public.store_employees
  (id, tenant_id, store_id, user_id, full_name, email, role)
SELECT 'e1', 'tn_demo', 'st1', u.id,
       COALESCE(u.raw_user_meta_data->>'full_name', u.email), u.email,
       'manager'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Dívidas (5 — Loja Centro st1) — clientes vinculados via customer_id
INSERT INTO public.debts
  (id, user_id, store_id, person_name, amount, due_date, is_customer_debt, is_paid, paid_at, customer_id)
SELECT 'd1', u.id, 'st1', 'João da Silva', 25.0, now() + interval '3 days', TRUE, FALSE, NULL, 'c1'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.debts
  (id, user_id, store_id, person_name, amount, due_date, is_customer_debt, is_paid, paid_at, customer_id)
SELECT 'd2', u.id, 'st1', 'Maria Souza', 60.0, now() - interval '2 days', TRUE, FALSE, NULL, 'c2'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.debts
  (id, user_id, store_id, person_name, amount, due_date, is_customer_debt, is_paid, paid_at, customer_id)
SELECT 'd3', u.id, 'st1', 'Pedro Alves', 15.5, now() + interval '10 days', TRUE, FALSE, NULL, 'c3'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- A pagar (fornecedor) — filtrada pelos casos de uso de crédito
INSERT INTO public.debts
  (id, user_id, store_id, person_name, amount, due_date, is_customer_debt, is_paid, paid_at, customer_id)
SELECT 'd4', u.id, 'st1', 'Distribuidora Norte', 120.0, now() + interval '5 days',
       FALSE, FALSE, NULL, NULL
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- Já quitada — aparece no histórico de quitações
INSERT INTO public.debts
  (id, user_id, store_id, person_name, amount, due_date, is_customer_debt, is_paid, paid_at, customer_id)
SELECT 'd5', u.id, 'st1', 'Ana Lima', 40.0, now() - interval '20 days',
       TRUE, TRUE, now() - interval '10 days', 'c4'
FROM auth.users u LIMIT 1
ON CONFLICT (id) DO NOTHING;

COMMIT;

