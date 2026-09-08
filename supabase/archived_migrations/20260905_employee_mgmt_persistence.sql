-- Gestão de funcionários (add-on `ao_employee_mgmt`).
--
-- Três tabelas por loja + UMA RPC de agregação:
--   employee_attendance       — ponto: UMA linha por funcionário por dia
--                               (entrada insere, saída atualiza a MESMA
--                               linha; clock_out NULL = presente);
--   employee_commission_rates — taxa de comissão por funcionário em
--                               PONTOS BASE (500 = 5%) — inteiro, sem
--                               floats na aritmética de dinheiro;
--   employee_targets          — meta mensal de vendas por funcionário
--                               (month = 'YYYY-MM').
--
-- COMISSÕES NUNCA SÃO ARMAZENADAS: a RPC get_employee_commission_summary
-- calcula a partir das VENDAS REAIS da loja (sales.user_id = caixa,
-- status 'active', mês do date_time) × taxa cadastrada — o mesmo padrão
-- H2/W5 das demais agregações (get_cash_flow / get_sales_report).
--
-- RLS: dono + funcionários da loja leem/escrevem via `is_my_store`;
-- INSERT/UPDATE validam que o user_id alvo é funcionário ATIVO da loja
-- (`is_store_employee_active`) — o dono registra ponto/metas de
-- funcionários da PRÓPRIA loja, nunca de outros tenants.

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

-- ── Ponto ──────────────────────────────────────────────────────────────
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
  -- Uma entrada por funcionário por dia (a saída atualiza a mesma linha).
  CONSTRAINT uq_employee_attendance_day
    UNIQUE (store_id, user_id, work_date)
);

CREATE INDEX IF NOT EXISTS idx_employee_attendance_store
  ON public.employee_attendance (store_id, work_date DESC);

-- recorded_by = usuário logado (ACTOR) — reforço anti-forja. Atenção:
-- NÃO usa set_tenant_user_id (que forçaria user_id = auth.uid() e
-- apagaria o SUJEITO — o funcionário registado pelo dono). Função própria
-- que só carimba o actor.
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

-- store_id = loja do usuário (se o valor enviado não for da loja dele,
-- cai para a primeira loja acessível — função do schema base).
DROP TRIGGER IF EXISTS trg_employee_attendance_store_id
  ON public.employee_attendance;
CREATE TRIGGER trg_employee_attendance_store_id
  BEFORE INSERT ON public.employee_attendance
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- ── Taxas de comissão ─────────────────────────────────────────────────
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

-- ── Metas ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.employee_targets (
  id           TEXT PRIMARY KEY,
  store_id     TEXT NOT NULL,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- Mês da meta 'YYYY-MM' — uma meta por funcionário por mês.
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

-- ── RLS ────────────────────────────────────────────────────────────────
ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_commission_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_targets ENABLE ROW LEVEL SECURITY;

-- Ponto: dono + funcionários da loja leem e registam; user_id alvo
-- (SUJEITO) precisa ser funcionário ATIVO da loja (não se registra ponto
-- de gente de fora).
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

-- Taxas: mesmo modelo.
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

-- Metas: mesmo modelo.
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

-- ── RPC: resumo de comissões CALCULADO das vendas reais ───────────────
-- Por funcionário ATIVO da loja: vendas ativas no mês × taxa cadastrada
-- (0 bps = sem taxa → comissão 0). SECURITY DEFINER com guarda
-- is_my_store (mesmo padrão get_cash_flow/get_sales_report).
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

-- Publica no Realtime? NÃO — o resumo é calculado sob demanda; a UI
-- re-consulta ao entrar na aba. (Realtime deixaria a tabela de ponto
-- exposta sem ganho para este módulo.)