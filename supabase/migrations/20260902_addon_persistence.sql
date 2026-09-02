-- Tabela de add-ons activos por tenant.
-- Cada linha representa um add-on activo (factura personalizada, cotação, etc.)
-- que o tenant contratou além do plano base.
--
-- RLS: cada tenant só vê os seus próprios add-ons (row-level security).

CREATE TABLE IF NOT EXISTS public.tenant_addons (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id     UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  add_on_id     TEXT NOT NULL,  -- ID do catálogo (ex.: ao_custom_invoice)
  activated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ,    -- NULL = sem expiração (assinatura mensal recorrente)
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Um tenant só pode ter UMA activação por add-on.
  CONSTRAINT uq_tenant_addon UNIQUE (tenant_id, add_on_id)
);

-- Índices para queries frequentes.
CREATE INDEX IF NOT EXISTS idx_tenant_addons_tenant_id
  ON public.tenant_addons (tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_addons_active
  ON public.tenant_addons (tenant_id, is_active);

-- RLS: cada tenant só vê os seus próprios add-ons.
ALTER TABLE public.tenant_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_addons_select_own"
  ON public.tenant_addons
  FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_users_id = auth.uid()
    )
  );

CREATE POLICY "tenant_addons_insert_own"
  ON public.tenant_addons
  FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_users_id = auth.uid()
    )
  );

CREATE POLICY "tenant_addons_update_own"
  ON public.tenant_addons
  FOR UPDATE
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_users_id = auth.uid()
    )
  );

CREATE POLICY "tenant_addons_delete_own"
  ON public.tenant_addons
  FOR DELETE
  USING (
    tenant_id IN (
      SELECT id FROM public.tenants
      WHERE owner_users_id = auth.uid()
    )
  );

-- Super admin pode ver e gerir todos os add-ons.
CREATE POLICY "tenant_addons_super_admin_all"
  ON public.tenant_addons
  FOR ALL
  USING (
    auth.uid() IN (SELECT user_id FROM public.super_admins)
  );
