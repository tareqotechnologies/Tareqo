-- ============================================================================
-- Dumbhanengue ERP — LIMPEZA dos dados de demonstração já existentes no banco
-- ============================================================================
-- ⚠️⚠️ DESTRUTIVO — execute APENAS após backup e após confirmar que os ids
-- abaixo correspondem ao seed de demonstração (não a dados reais seus).
-- Use com o usuário dono do schema (SQL Editor do Supabase), NÃO com o
-- cliente do app.
--
-- Contexto: antes desta limpeza, o `schema.sql` (Parte 2) semeava um tenant
-- demo aprovado ('tn_demo') com lojas, funcionário, produtos, vendas,
-- clientes, fiados, compras e movimentações para o PRIMEIRO usuário
-- cadastrado. A partir de agora o schema NÃO semeia mais nada; este script
-- apaga o que já foi semeado nas bases existentes.
--
-- Ordem respeita as FKs (itens → pai → agregados → tenant). Idempotente.
-- ============================================================================

-- Itens de venda/compra do seed.
DELETE FROM public.sale_items
  WHERE sale_id IN ('s1', 's2', 's3', 's4');

DELETE FROM public.purchase_items
  WHERE purchase_id IN ('pc1', 'pc2');

-- Vendas e compras do seed.
DELETE FROM public.sales
  WHERE id IN ('s1', 's2', 's3', 's4');

DELETE FROM public.purchases
  WHERE id IN ('pc1', 'pc2');

-- Movimentações financeiras do seed (t1..t10).
DELETE FROM public.financial_transactions
  WHERE id IN ('t1', 't2', 't3', 't4', 't5', 't6', 't7', 't8', 't9', 't10');

-- Dívidas/fiados do seed (d1..d5).
DELETE FROM public.debts
  WHERE id IN ('d1', 'd2', 'd3', 'd4', 'd5');

-- Clientes do seed (c1..c4).
DELETE FROM public.customers
  WHERE id IN ('c1', 'c2', 'c3', 'c4');

-- Produtos do seed (p1..p7).
DELETE FROM public.products
  WHERE id IN ('p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7');

-- Funcionário demo do tenant demo (o dono continuará dono do tenant real
-- que ele criar pelo onboarding; nada aqui apaga contas de auth.users).
DELETE FROM public.store_employees
  WHERE id = 'e1' AND tenant_id = 'tn_demo';

-- Lojas demo (só as do tenant demo).
DELETE FROM public.stores
  WHERE id IN ('st1', 'st2') AND tenant_id = 'tn_demo';

-- Tenant demo aprovado (cascata em plan_requests).
DELETE FROM public.tenants
  WHERE id = 'tn_demo';

-- Sanidade: o banco deve ter ficado sem os registros do seed.
SELECT
  (SELECT count(*) FROM public.products)               AS products,
  (SELECT count(*) FROM public.sales)                  AS sales,
  (SELECT count(*) FROM public.financial_transactions) AS transactions,
  (SELECT count(*) FROM public.debts)                  AS debts,
  (SELECT count(*) FROM public.customers)              AS customers,
  (SELECT count(*) FROM public.purchases)              AS purchases,
  (SELECT count(*) FROM public.tenants)                AS tenants,
  (SELECT count(*) FROM public.stores)                 AS stores;
