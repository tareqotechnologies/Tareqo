-- ============================================================================
-- Parte 20 — Campos de faturação na tabela stores
-- ============================================================================
-- Adiciona phone, email, nuit e city à tabela stores para suportar
-- faturação com dados completos da loja.
-- Data: 2026-08-25
-- ============================================================================

-- Adicionar colunas (idempotente: IF NOT EXISTS)
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS phone  TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS email  TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS nuit   TEXT NOT NULL DEFAULT '';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS city   TEXT NOT NULL DEFAULT '';

-- Comentários nas colunas (documentação)
COMMENT ON COLUMN public.stores.phone IS 'Telefone de contacto da loja';
COMMENT ON COLUMN public.stores.email IS 'E-mail de contacto da loja';
COMMENT ON COLUMN public.stores.nuit  IS 'Número de Identificação Única de Contribuinte (NUIT)';
COMMENT ON COLUMN public.stores.city  IS 'Cidade onde se situa a loja';

-- Garantir que o RLS continua a funcionar (não altera políticas,
-- mas valida que as colunas existem para queries futuras).
DO $$
BEGIN
  RAISE NOTICE 'Migration 020 concluída: phone, email, nuit, city adicionados à tabela stores.';
END $$;
