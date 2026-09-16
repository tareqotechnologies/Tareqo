-- ═══════════════════════════════════════════════════════════════════
-- FIX 2026-09-16 — Gestão de Funcionários (add-on ao_employee_mgmt)
-- ═══════════════════════════════════════════════════════════════════
-- Sintomas no app:
--   1. Aba Comissões: "não foi possível carregar funcionários"
--      → RPC get_employee_commission_summary falha com 42804
--        "Returned type numeric does not match expected type bigint in
--        column 3" — SUM(bigint) devolve NUMERIC no Postgres e o
--        RETURNS TABLE declara BIGINT. Correção: cast ::BIGINT nos
--        agregados (o cast de numeric para bigint arredonda — valores
--        de centavos são inteiros, sem perda).
--
--      (O ponto — aba Ponto — não tem bug no SQL: o INSERT sem id era
--      corrigido no app: employee_attendance.id é TEXT PRIMARY KEY sem
--      default e o datasource remoto não gerava o id. Ver o commit do
--      datasource: AppIds.newId('att') no clockIn.)
--
-- Idempotente: pode ser re-executado sem efeito colateral.
-- ═══════════════════════════════════════════════════════════════════

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
    -- "Returned type numeric does not match expected type bigint".
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

-- Re-grant pós-CREATE OR REPLACE (mantém o contrato de hardening:
-- EXECUTE para authenticated/service_role, NUNCA para anon/PUBLIC).
REVOKE EXECUTE ON FUNCTION
  public.get_employee_commission_summary(TEXT, TEXT)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION
  public.get_employee_commission_summary(TEXT, TEXT)
TO authenticated, service_role;
