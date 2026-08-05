-- ============================================================================
-- 002_tenant_preferences.sql
-- ----------------------------------------------------------------------------
-- Moeda e idioma por tenant — escolha do dono no onboarding e em
-- Lojas → Ajustes (colunas `currency_code` e `language` em `public.tenants`).
--
-- PARA O PROJETO EXISTENTE (ex.: dotklbpqmlnhcdifiukd):
-- rode este script no SQL Editor do Supabase. Para instalações novas, o
-- `supabase/schema.sql` já contém as colunas — este arquivo é idempotente
-- e pode ser rodado à vontade.
-- ============================================================================

ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'BRL',
  ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'pt';

-- CHECKs idempotentes: só criam a constraint se ela ainda não existir.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'tenants_currency_code_check'
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_currency_code_check
      CHECK (currency_code IN ('BRL', 'USD', 'EUR', 'MZN'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'tenants_language_check'
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_language_check
      CHECK (language IN ('pt', 'en'));
  END IF;
END $$;
