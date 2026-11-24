-- ============================================================================
-- MÚLTIPLOS CÓDIGOS DE BARRAS / EMBALAGENS POR PRODUTO
-- Data: 2026-11-24 · App: TAREQO
-- ============================================================================
-- Aditivo: NÃO altera products.stock_quantity, sales, sale_items,
-- stock_lots nem sale_lot_consumption. O código principal em
-- products.barcode continua a existir como espelho/fallback.
--
-- qty_factor é guardado em UNIDADES da embalagem:
--   1 = unidade · 30 = caixa · 180 = fardo
-- O POS converte para milésimos (qty_factor × 1000) antes de criar o
-- SaleItem. O servidor continua a receber a quantidade na menor unidade.
--
-- Rodar numa janela de baixa utilização. Idempotente.
-- ============================================================================

BEGIN;

-- Pré-voo: barcode legado repetido na mesma loja tornaria a unicidade
-- ambígua. Aborta com a lista para resolução manual.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT store_id,
           btrim(barcode) AS barcode,
           count(*) AS quantidade,
           string_agg(name, ' | ' ORDER BY name) AS produtos
    FROM public.products
    WHERE barcode IS NOT NULL
      AND btrim(barcode) <> ''
    GROUP BY store_id, btrim(barcode)
    HAVING count(*) > 1
  LOOP
    RAISE EXCEPTION
      'Barcode % repetido na loja %: %',
      r.barcode, r.store_id, r.produtos;
  END LOOP;
END $$;

-- Índice necessário para a FK composta (id já é PK; o par é único).
CREATE UNIQUE INDEX IF NOT EXISTS uq_products_id_store
  ON public.products (id, store_id);

CREATE TABLE IF NOT EXISTS public.product_barcodes (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id    TEXT NOT NULL DEFAULT 'st1',
  product_id  TEXT NOT NULL,
  barcode     TEXT NOT NULL,
  qty_factor  INTEGER NOT NULL DEFAULT 1,
  description TEXT NOT NULL DEFAULT '',
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ,

  CONSTRAINT product_barcodes_factor_ck
    CHECK (qty_factor > 0 AND qty_factor <= 1000000),
  CONSTRAINT product_barcodes_barcode_ck
    CHECK (length(btrim(barcode)) BETWEEN 1 AND 512)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'product_barcodes_product_fk'
      AND conrelid = 'public.product_barcodes'::regclass
  ) THEN
    ALTER TABLE public.product_barcodes
      ADD CONSTRAINT product_barcodes_product_fk
      FOREIGN KEY (product_id, store_id)
      REFERENCES public.products (id, store_id)
      ON DELETE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_product_barcodes_store_barcode
  ON public.product_barcodes (store_id, barcode);

CREATE INDEX IF NOT EXISTS idx_product_barcodes_product
  ON public.product_barcodes (store_id, product_id);

ALTER TABLE public.product_barcodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS product_barcodes_select ON public.product_barcodes;
CREATE POLICY product_barcodes_select ON public.product_barcodes
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS product_barcodes_insert ON public.product_barcodes;
CREATE POLICY product_barcodes_insert ON public.product_barcodes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS product_barcodes_update ON public.product_barcodes;
CREATE POLICY product_barcodes_update ON public.product_barcodes
  FOR UPDATE USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  ) WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS product_barcodes_delete ON public.product_barcodes;
CREATE POLICY product_barcodes_delete ON public.product_barcodes
  FOR DELETE USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS trg_product_barcodes_user_id
  ON public.product_barcodes;
CREATE TRIGGER trg_product_barcodes_user_id
  BEFORE INSERT ON public.product_barcodes
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

DROP TRIGGER IF EXISTS trg_product_barcodes_store_id
  ON public.product_barcodes;
CREATE TRIGGER trg_product_barcodes_store_id
  BEFORE INSERT ON public.product_barcodes
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- Backfill do código principal legado como fator 1. O hash determinístico
-- torna a reexecução idempotente.
INSERT INTO public.product_barcodes (
  id, user_id, store_id, product_id, barcode,
  qty_factor, description, is_active, created_at
)
SELECT
  'pb_' || md5(p.store_id || ':' || btrim(p.barcode)),
  p.user_id,
  p.store_id,
  p.id,
  btrim(p.barcode),
  1,
  'Código principal (legado)',
  p.is_active,
  now()
FROM public.products p
WHERE p.barcode IS NOT NULL
  AND btrim(p.barcode) <> ''
ON CONFLICT (store_id, barcode) DO NOTHING;

DO $$
DECLARE
  v_faltando integer;
BEGIN
  SELECT count(*) INTO v_faltando
  FROM public.products p
  WHERE p.barcode IS NOT NULL
    AND btrim(p.barcode) <> ''
    AND NOT EXISTS (
      SELECT 1
      FROM public.product_barcodes b
      WHERE b.store_id = p.store_id
        AND b.barcode = btrim(p.barcode)
    );

  IF v_faltando > 0 THEN
    RAISE EXCEPTION
      'Backfill incompleto: % produto(s) sem barcode na tabela nova.',
      v_faltando;
  END IF;
END $$;

COMMIT;
