-- 009 — KPIs do dashboard agregadas no servidor (W5): get_dashboard_kpis.
--
-- Reexecutável (CREATE OR REPLACE). Aplica-se a projetos que já têm o
-- schema.sql base (migrações 001..008).
--
-- Porquê: o dashboard somava client-side 4 listagens de até 1000 linhas
-- (vendas, transações, dívidas, produtos) para obter os indicadores. Esta
-- RPC devolve os 4 agregados numa única chamada — menos latência, menos
-- memória e agregação exata no Postgres (NUMERIC), sem depender do teto
-- de linhas do cliente.
--
-- Semântica (idêntica ao cálculo client-side anterior):
--   * total_sales   — vendas TOTAIS da loja (histórico completo);
--   * cash_income / cash_expense — transações PAID do período [p_start,
--     p_end] (vendas "fiadas" pendentes só contam quando recebidas);
--   * pending_total — dívidas de CLIENTES ainda não quitadas;
--   * stock_total   — soma das quantidades em estoque.
--
-- Guarda: is_my_store (dono do tenant ou funcionário vinculado à loja).

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
