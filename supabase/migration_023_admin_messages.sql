-- Migration 023: Tabela de mensagens do super admin para tenants.
-- O super admin pode emitir cotações, notificar alterações de validade,
-- ou enviar mensagens gerais para o dono do tenant.

CREATE TABLE IF NOT EXISTS public.admin_messages (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN ('billingQuote', 'planExpiryChange', 'planExpiringSoon', 'general')),
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at    TIMESTAMPTZ
);

-- Índices para consultas rápidas por tenant.
CREATE INDEX IF NOT EXISTS idx_admin_messages_tenant
  ON public.admin_messages (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_messages_unread
  ON public.admin_messages (tenant_id, is_read)
  WHERE is_read = false;

-- RLS: super admin tem acesso total; dono do tenant lê apenas as suas.
ALTER TABLE public.admin_messages ENABLE ROW LEVEL SECURITY;

-- Super admin pode tudo (SELECT, INSERT, UPDATE, DELETE).
CREATE POLICY admin_messages_super_admin_all
  ON public.admin_messages
  FOR ALL
  USING (public.is_super_admin());

-- Dono do tenant pode ler suas próprias mensagens.
CREATE POLICY admin_messages_owner_read
  ON public.admin_messages
  FOR SELECT
  USING (public.is_tenant_owner(tenant_id));

-- Dono do tenant pode marcar como lida (UPDATE de is_read/read_at).
CREATE POLICY admin_messages_owner_update
  ON public.admin_messages
  FOR UPDATE
  USING (public.is_tenant_owner(tenant_id))
  WITH CHECK (public.is_tenant_owner(tenant_id));

-- Habilitar Realtime para notificação instantânea.
ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_messages;
