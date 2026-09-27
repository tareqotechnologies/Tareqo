-- =====================================================================
-- Fase 1 — Tipo do produto (products.type)
-- Data: 2026-09-27 · App: TAREQO v2.4.0+ (enum ProductType)
-- =====================================================================
-- Objetivo: distinguir o papel estrutural do produto na operação real
-- (pastelaria/produção):
--   rawMaterial   — matéria-prima (farinha, açúcar, ovos, carne...)
--   resale        — produto comprado pronto para revenda (água, refrigerante)
--   manufactured  — produto produzido internamente (pão, bolo, hambúrguer)
--   composite     — produto composto/montado (hambúrguer completo, menu)
--   packaging     — embalagem e material de consumo (saco, copo, guardanapo)
--
-- Compatibilidade: DEFAULT 'resale' — produtos existentes já eram
-- compráveis e vendáveis e CONTINUAM funcionando exatamente igual.
-- Nenhum dado é apagado nem reclassificado automaticamente; o dono
-- reclassifica produto a produto na UI (ou por UPDATE explícito).
--
-- Idempotente: roda em qualquer banco (guarda por presença da coluna).
-- O app lê o campo pelo NOME do enum (PostgREST devolve text; linha sem
-- a coluna/valor desconhecido cai no default 'resale' no cliente).
-- =====================================================================

-- SEM CHECK de enum — mesma decisão do SQLite (ver upgrade.sql, PARTE 34):
-- valores futuros do enum não podem ficar bloqueados pela restrição antiga;
-- a validação vive no datasource (valor desconhecido → 'resale').
ALTER TABLE IF EXISTS public.products
  ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'resale';

-- Limpa o CHECK caso uma versão anterior deste script o tenha criado.
ALTER TABLE IF EXISTS public.products
  DROP CONSTRAINT IF EXISTS products_type_check;

COMMENT ON COLUMN public.products.type
  IS 'Tipo estrutural do produto (enum ProductType): rawMaterial, resale (default/legado), manufactured, composite, packaging.';

-- Consulta por tipo fica constante na listagem/filtro do catálogo.
CREATE INDEX IF NOT EXISTS idx_products_store_type
  ON public.products (store_id, type);

ANALYZE public.products;
