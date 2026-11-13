-- ============================================================================
-- product_category_2026_11.sql — CATEGORIZAÇÃO do produto (products.category)
-- ============================================================================
-- SINTOMA: a lista de produtos não oferece filtro por categoria porque o
-- catálogo não tem onde guardar a categoria.
--
-- CORREÇÃO: coluna TEXT opcional `category` (NULL = sem categoria). O app
-- grava a categoria digitada no cadastro/edição e deriva os chips do filtro
-- dos próprios produtos da loja — não há tabela auxiliar nem policy nova.
--
-- ⚠️ Rodar ANTES (ou junto) de instalar o APK novo: a versão nova do app
-- pede a coluna `category` no SELECT de produtos; sem ela o PostgREST
-- responde 400 e a lista não carrega.
--
-- IDEMPOTENTE — pode rodar quantas vezes quiser.
-- Como rodar: Supabase Dashboard → SQL Editor → colar → Run.
-- ============================================================================

BEGIN;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS category TEXT;

COMMIT;

-- ============================================================================
-- VERIFICAÇÃO (esperado: 1 linha com a coluna category)
-- ============================================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'products'
  AND column_name = 'category';
