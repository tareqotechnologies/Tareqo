-- ============================================================================
-- Parte 21 — Facturas de cobrança e campos de billing nos tenants
-- ============================================================================
-- Adiciona a tabela `invoices` para facturas de cobrança mensal e as colunas
-- `plan_expires_at` e `next_invoice_at` na tabela `tenants` para controlar
-- o ciclo de facturacao com trial de 14 dias.
-- Data: 2026-08-29
-- ============================================================================

-- ---------------------------------------------------------------
-- 1. Colunas de billing na tabela tenants
-- ---------------------------------------------------------------
-- `plan_expires_at`: data de expiração do plano actual (renovação mensal).
-- `next_invoice_at`: data em que a próxima factura deve ser gerada.
-- Na primeira subscricao, plan_expires_at = now + 14 dias (trial grátis).
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS plan_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS next_invoice_at TIMESTAMPTZ;

-- Comentários nas colunas (documentação)
COMMENT ON COLUMN public.tenants.plan_expires_at
  IS 'Data de expiração do plano actual (renovação mensal a partir de approved_at). Trial: 14 dias.';
COMMENT ON COLUMN public.tenants.next_invoice_at
  IS 'Data em que a próxima factura de renovação deve ser gerada (7 dias antes de plan_expires_at).';

-- ---------------------------------------------------------------
-- 2. Tabela de facturas de cobrança
-- ---------------------------------------------------------------
-- Cada factura liga-se ao tenant e ao plano contratado, registando o
-- valor a cobrar (em centavos) no momento da geração.
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

-- Comentários na tabela (documentação)
COMMENT ON TABLE public.invoices
  IS 'Facturas de cobrança geradas para renovação mensal do plano dos tenants.';
COMMENT ON COLUMN public.invoices.number
  IS 'Número sequencial da factura (INV-00001, INV-00002...)';
COMMENT ON COLUMN public.invoices.period
  IS 'Período que a factura cobre (ex.: "Janeiro 2026")';
COMMENT ON COLUMN public.invoices.amount_cents
  IS 'Valor em CENTAVOS inteiros (mesma unidade do Plan.price_monthly)';

-- ---------------------------------------------------------------
-- 3. RLS para a tabela invoices
-- ---------------------------------------------------------------
-- Facturas são geradas pelo app (GenerateInvoiceUseCase) e visualizadas
-- pelo super admin. O RLS restringe acesso ao super admin.
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Super admin: acesso total (SELECT, INSERT, UPDATE, DELETE)
-- A política permite leitura/escrita apenas para super admins.
DROP POLICY IF EXISTS invoices_super_admin_all ON public.invoices;
CREATE POLICY invoices_super_admin_all ON public.invoices
  FOR ALL USING (public.is_super_admin());

-- Dono do tenant: pode ver as suas próprias facturas (SELECT apenas)
DROP POLICY IF EXISTS invoices_tenant_owner_select ON public.invoices;
CREATE POLICY invoices_tenant_owner_select ON public.invoices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenants t
      WHERE t.id = invoices.tenant_id
        AND t.owner_user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------
-- 4. Índices para consultas frequentes
-- ---------------------------------------------------------------
-- Consulta por tenant (histórico de facturas do tenant)
CREATE INDEX IF NOT EXISTS idx_invoices_tenant
  ON public.invoices (tenant_id, created_at DESC);

-- Consulta de facturas pendentes (painel admin)
CREATE INDEX IF NOT EXISTS idx_invoices_status
  ON public.invoices (status) WHERE status = 'pending';

-- Verificação de duplicação (já existe factura pendente para o período)
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_period
  ON public.invoices (tenant_id, period, status);

-- ---------------------------------------------------------------
-- 5. Função para obter o próximo número de factura
-- ---------------------------------------------------------------
-- Atribui o próximo número sequencial de factura dentro do tenant
-- (INV-00001, INV-00002...) usando advisory lock por tenant.
CREATE OR REPLACE FUNCTION public.get_next_invoice_number(p_tenant_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  -- Advisory lock por tenant (previne condição de corrida)
  PERFORM pg_advisory_xact_lock(
    hashtext('invoice_number'),
    hashtext(p_tenant_id)
  );

  -- Próximo número sequencial
  SELECT COALESCE(MAX(number), 0) + 1
  INTO v_next
  FROM public.invoices
  WHERE tenant_id = p_tenant_id;

  RETURN v_next;
END;
$$;

-- ---------------------------------------------------------------
-- 6. Trigger para atribuir número de factura automaticamente
-- ---------------------------------------------------------------
-- Atribui o número sequencial no INSERT (antes de persistir).
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

-- ---------------------------------------------------------------
-- 7. Publicar invoices no Realtime (opcional, para notificações)
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- 8. Tabela de notificações de facturas
-- ---------------------------------------------------------------
-- Notificações in-app para o dono do tenant quando facturas são geradas,
-- pagas ou expiram. Publicada no Realtime para notificação instantânea.
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

-- Comentários na tabela (documentação)
COMMENT ON TABLE public.invoice_notifications
  IS 'Notificações in-app para o dono do tenant sobre facturas.';
COMMENT ON COLUMN public.invoice_notifications.type
  IS 'Tipo: invoiceGenerated, invoiceDueSoon, invoiceExpired, invoicePaid';

-- ---------------------------------------------------------------
-- 9. RLS para a tabela invoice_notifications
-- ---------------------------------------------------------------
ALTER TABLE public.invoice_notifications ENABLE ROW LEVEL SECURITY;

-- Super admin: acesso total
DROP POLICY IF EXISTS invoice_notifications_super_admin_all
  ON public.invoice_notifications;
CREATE POLICY invoice_notifications_super_admin_all
  ON public.invoice_notifications
  FOR ALL USING (public.is_super_admin());

-- Dono do tenant: pode ver e gerir as suas notificações
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

-- ---------------------------------------------------------------
-- 10. Índices para notificações
-- ---------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_invoice_notifications_tenant
  ON public.invoice_notifications (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_invoice_notifications_unread
  ON public.invoice_notifications (tenant_id)
  WHERE is_read = FALSE;

-- ---------------------------------------------------------------
-- 11. Publicar notificações no Realtime
-- ---------------------------------------------------------------
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
-- 12. Validação e mensagem de conclusão
-- ---------------------------------------------------------------
DO $$
BEGIN
  RAISE NOTICE 'Migration 021 concluída: tabela invoices + invoice_notifications criadas, colunas plan_expires_at/next_invoice_at adicionadas aos tenants.';
END $$;

