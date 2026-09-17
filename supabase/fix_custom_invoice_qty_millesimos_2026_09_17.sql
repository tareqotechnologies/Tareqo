-- ═════════════════════════════════════════════════════════════════════════════
-- supabase/fix_custom_invoice_qty_millesimos_2026_09_17.sql
-- ═════════════════════════════════════════════════════════════════════════════
-- NORMALIZA facturas personalizadas antigas: quantidade CRUA → MILÉSIMOS.
--
-- CONTEXTO (bug fix v2.2.0): o app guarda quantidades em MILÉSIMOS
-- (convenção W11 — 1000 = 1 unidade, suporte a venda a granel kg/g).
-- O exporter do PDF (~/ 1000), o preview textual e o card da cotação
-- seguem a convenção — mas a tela de Factura Personalizada gravava o
-- inteiro CRU do campo (qty 2 → quantity 2 em vez de 2000). Resultado:
-- o PDF exibia "0.0 un" e o subtotal saía 1000× MENOR no novo cálculo
-- (qty × preço ÷ 1000).
--
-- Fix no app: a criação multiplica por 1000 (custom_invoice_screen.dart)
-- e o use case divide o subtotal por 1000 (custom_invoice_use_cases.dart).
--
-- ESTE SCRIPT corrige as facturas JÁ GRAVADAS com a convenção antiga:
--   * items[].quantity:      qty × 1000
--   * items[].subtotalCents: quantity_nova × unitPriceCents ÷ 1000
--   * totalAmountCents:      soma dos novos subtotais − desconto + imposto
--
-- DETECÇÃO (sem coluna de versão no payload): uma factura está na
-- convenção ANTIGA quando a quantidade de algum item é "pequena demais"
-- para ser milésimos E a reconstrução crua bate com o total gravado.
-- Heurística conservadora em 2 condições (ambas obrigatórias):
--   1. quantity < 1000 em TODOS os itens  (milésimos de 1+ unidade
--      nunca são < 1000; qty crua típica é 1..999);
--   2. total reconstruído na convenção CRUA == totalAmountCents
--      (confirma que os centavos também foram gravados crus — evita
--      tocar em facturas já corretas ou parcialmente corrigidas).
--
-- IDEMPOTENTE: facturas já normalizadas (qty ≥ 1000 ou total que não
-- bate com a reconstrução crua) NUNCA são tocadas — pode reexecutar.
--
-- RODE NO SQL EDITOR do projeto de produção (supera o RLS por ser dono
-- do schema). Verifique o SELECT de auditoria antes e depois.
-- ═════════════════════════════════════════════════════════════════════════════

-- ── 0. Auditoria ANTES: facturas candidatas à normalização ──────────────────
-- Confira visualmente: cada linha deve ser uma factura com qty crua.
-- (Campos derivados no SQL: jsonb_array_elements + aritmética inteira.)
WITH candidates AS (
  SELECT
    ci.id,
    ci.invoice_number,
    ci.store_id,
    ci.payload,
    (
      SELECT bool_and(
        COALESCE((item->>'quantity')::bigint, 0) < 1000
      )
      FROM jsonb_array_elements(ci.payload->'items') AS item
      WHERE jsonb_array_length(ci.payload->'items') > 0
    ) AS all_qty_raw,
    (
      SELECT COALESCE(SUM(
        COALESCE((item->>'quantity')::bigint, 0)
        * COALESCE((item->>'unitPriceCents')::bigint, 0)
      ), 0)
      FROM jsonb_array_elements(ci.payload->'items') AS item
    ) AS raw_subtotal_sum
  FROM public.custom_invoices ci
)
SELECT
  id,
  invoice_number,
  store_id,
  raw_subtotal_sum AS total_cru_gravado,
  (payload->>'totalAmountCents')::bigint AS total_gravado,
  (payload->>'discountCents')::bigint AS desconto,
  (payload->>'taxCents')::bigint AS imposto,
  CASE
    WHEN all_qty_raw
     AND (raw_subtotal_sum
          - COALESCE((payload->>'discountCents')::bigint, 0)
          + COALESCE((payload->>'taxCents')::bigint, 0))
         = COALESCE((payload->>'totalAmountCents')::bigint, 0)
    THEN 'NORMALIZAR'
    ELSE 'já OK (não tocar)'
  END AS acao
FROM candidates
ORDER BY acao, invoice_number;

-- ── 1. UPDATE: normaliza qty, subtotais e total (só as candidatas) ──────────
WITH candidates AS (
  SELECT
    ci.id,
    ci.payload,
    (
      SELECT bool_and(
        COALESCE((item->>'quantity')::bigint, 0) < 1000
      )
      FROM jsonb_array_elements(ci.payload->'items') AS item
      WHERE jsonb_array_length(ci.payload->'items') > 0
    ) AS all_qty_raw,
    (
      SELECT COALESCE(SUM(
        COALESCE((item->>'quantity')::bigint, 0)
        * COALESCE((item->>'unitPriceCents')::bigint, 0)
      ), 0)
      FROM jsonb_array_elements(ci.payload->'items') AS item
    ) AS raw_subtotal_sum
  FROM public.custom_invoices ci
),
to_fix AS (
  SELECT id, payload
  FROM candidates
  WHERE all_qty_raw
    AND (raw_subtotal_sum
         - COALESCE((payload->>'discountCents')::bigint, 0)
         + COALESCE((payload->>'taxCents')::bigint, 0))
        = COALESCE((payload->>'totalAmountCents')::bigint, 0)
)
UPDATE public.custom_invoices ci
SET payload = (
  SELECT
    -- Itens: quantity × 1000; subtotal = nova qty × preço ÷ 1000.
    jsonb_set(
      jsonb_set(f.payload, '{items}', new_items.items, false),
      '{totalAmountCents}',
      to_jsonb(
        COALESCE((
          SELECT SUM(
            (new_item->>'quantity')::bigint
            * (new_item->>'unitPriceCents')::bigint
            / 1000
          )
          FROM jsonb_array_elements(new_items.items) AS new_item
        ), 0)
        - COALESCE((f.payload->>'discountCents')::bigint, 0)
        + COALESCE((f.payload->>'taxCents')::bigint, 0)
      ),
      false
    )
  FROM (
    SELECT jsonb_agg(
      jsonb_build_object(
        'productName',   item->>'productName',
        'quantity',      COALESCE((item->>'quantity')::bigint, 0) * 1000,
        'unitPriceCents', COALESCE((item->>'unitPriceCents')::bigint, 0),
        'subtotalCents', COALESCE((item->>'quantity')::bigint, 0) * 1000
                         * COALESCE((item->>'unitPriceCents')::bigint, 0)
                         / 1000,
        'unit',          COALESCE(item->>'unit', 'un')
      )
      ORDER BY ord.idx
    ) AS items
    FROM jsonb_array_elements(f.payload->'items')
      WITH ORDINALITY AS ord(item, idx)
  ) AS new_items
  WHERE new_items.items IS NOT NULL
)
FROM to_fix f
WHERE ci.id = f.id;

-- ── 2. Auditoria DEPOIS: nenhuma factura deve restar como NORMALIZAR ────────
-- Reexecuta o SELECT do passo 0 — esperado: todas as linhas 'já OK'.
WITH candidates AS (
  SELECT
    ci.id,
    ci.invoice_number,
    ci.payload,
    (
      SELECT bool_and(
        COALESCE((item->>'quantity')::bigint, 0) < 1000
      )
      FROM jsonb_array_elements(ci.payload->'items') AS item
      WHERE jsonb_array_length(ci.payload->'items') > 0
    ) AS all_qty_raw,
    (
      SELECT COALESCE(SUM(
        COALESCE((item->>'quantity')::bigint, 0)
        * COALESCE((item->>'unitPriceCents')::bigint, 0)
      ), 0)
      FROM jsonb_array_elements(ci.payload->'items') AS item
    ) AS raw_subtotal_sum
  FROM public.custom_invoices ci
)
SELECT
  id,
  invoice_number,
  CASE
    WHEN all_qty_raw
     AND (raw_subtotal_sum
          - COALESCE((payload->>'discountCents')::bigint, 0)
          + COALESCE((payload->>'taxCents')::bigint, 0))
         = COALESCE((payload->>'totalAmountCents')::bigint, 0)
    THEN 'AINDA CRUA (revisar)'
    ELSE 'OK'
  END AS acao
FROM candidates
ORDER BY invoice_number;

-- ── Notas ────────────────────────────────────────────────────────────────────
-- * Facturas SEM itens (payload vazio) não são candidatas (bool_and de
--   conjunto vazio = NULL → WHERE falha) — nunca tocadas.
-- * Facturas com qty mista (uma crua, outra em milésimos — improvável,
--   pois o bug era sistêmico) NÃO são normalizadas (all_qty_raw exige
--   todas < 1000) — revise manualmente pelo SELECT de auditoria.
-- * O subtotal usa divisão INTEIRA (/ 1000) — mesma semântica do use
--   case Dart (`~/ 1000`); resto < 1000 é truncado, sem centavos fantasmas.
