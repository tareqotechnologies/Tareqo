-- =====================================================================
-- Fase 2 — Ficha técnica + produção (recibos/ordens de produção)
-- Data: 2026-09-27 · App: TAREQO v2.4.0+ (Fase 2 — pastelaria/produção)
-- =====================================================================
-- Script ISOLADO (equivale à PARTE 35 do upgrade.sql consolidado): aplica
-- apenas esta migração num banco que já recebeu as partes anteriores.
--
-- Objetivo: dar suporte à FICHA TÉCNICA (receita/BOM) e às ORDENS de
-- produção. Uma ordem de produção, executada pela RPC process_production,
-- baixa os componentes em ordem FIFO (validade mais próxima primeiro; sem
-- validade por entrada) e cria o LOTE do produto acabado com o custo
-- unitário calculado a partir do preço de compra ATUAL dos componentes —
-- tudo em UMA transação.
--
-- Produção é nível GERENCIAL (dono/gerente), como compras: o RLS nega o
-- funcionário comum e o INSERT/UPDATE exige mfa_ok.
--
-- Idempotente: pode rodar mais de uma vez sem efeito (CREATE TABLE/INDEX/
-- OR REPLACE + DROP POLICY IF EXISTS + GRANT).
-- Espelha supabase/schema.sql (a instalação nova já nasce com tudo).
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.recipes (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL DEFAULT 'st1',
  product_id     TEXT NOT NULL,
  yield_quantity BIGINT NOT NULL CHECK (yield_quantity > 0),
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ,
  UNIQUE (store_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.recipe_items (
  id         BIGSERIAL PRIMARY KEY,
  recipe_id  TEXT NOT NULL REFERENCES public.recipes (id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  quantity   BIGINT NOT NULL CHECK (quantity > 0),
  UNIQUE (recipe_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.production_orders (
  id           TEXT PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id     TEXT NOT NULL DEFAULT 'st1',
  product_id   TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity     BIGINT NOT NULL CHECK (quantity > 0),
  recipe_id    TEXT,
  cost_price   BIGINT NOT NULL CHECK (cost_price >= 0),
  total_cost   BIGINT NOT NULL CHECK (total_cost >= 0),
  date_time    TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS public.production_order_items (
  id            BIGSERIAL PRIMARY KEY,
  production_id TEXT NOT NULL REFERENCES public.production_orders (id)
                ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  product_id    TEXT NOT NULL,
  product_name  TEXT NOT NULL,
  quantity      BIGINT NOT NULL CHECK (quantity > 0),
  unit_cost     BIGINT NOT NULL CHECK (unit_cost >= 0),
  UNIQUE (production_id, product_id)
);

ALTER TABLE IF EXISTS public.recipes                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recipe_items           ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.production_orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.production_order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS recipes_select ON public.recipes;
CREATE POLICY recipes_select ON public.recipes
  FOR SELECT USING (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS recipes_insert ON public.recipes;
CREATE POLICY recipes_insert ON public.recipes
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id)
                         AND public.mfa_ok());
DROP POLICY IF EXISTS recipes_update ON public.recipes;
CREATE POLICY recipes_update ON public.recipes
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id) AND public.mfa_ok());
DROP POLICY IF EXISTS recipes_delete ON public.recipes;
CREATE POLICY recipes_delete ON public.recipes
  FOR DELETE USING (public.is_manager_of_store(store_id));

DROP POLICY IF EXISTS recipe_items_select ON public.recipe_items;
CREATE POLICY recipe_items_select ON public.recipe_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id
        AND public.is_manager_of_store(r.store_id)
    )
  );
DROP POLICY IF EXISTS recipe_items_insert ON public.recipe_items;
CREATE POLICY recipe_items_insert ON public.recipe_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id
        AND public.is_manager_of_store(r.store_id)
        AND public.mfa_ok()
    )
  );
DROP POLICY IF EXISTS recipe_items_update ON public.recipe_items;
CREATE POLICY recipe_items_update ON public.recipe_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id
        AND public.is_manager_of_store(r.store_id)
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id
        AND public.is_manager_of_store(r.store_id)
        AND public.mfa_ok()
    )
  );
DROP POLICY IF EXISTS recipe_items_delete ON public.recipe_items;
CREATE POLICY recipe_items_delete ON public.recipe_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id
        AND public.is_manager_of_store(r.store_id)
    )
  );

DROP POLICY IF EXISTS production_orders_select ON public.production_orders;
CREATE POLICY production_orders_select ON public.production_orders
  FOR SELECT USING (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS production_orders_insert ON public.production_orders;
CREATE POLICY production_orders_insert ON public.production_orders
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id)
                         AND public.mfa_ok());
DROP POLICY IF EXISTS production_orders_update ON public.production_orders;
CREATE POLICY production_orders_update ON public.production_orders
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id) AND public.mfa_ok());
DROP POLICY IF EXISTS production_orders_delete ON public.production_orders;
CREATE POLICY production_orders_delete ON public.production_orders
  FOR DELETE USING (public.is_manager_of_store(store_id));

DROP POLICY IF EXISTS production_order_items_select
  ON public.production_order_items;
CREATE POLICY production_order_items_select ON public.production_order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.production_orders o
      WHERE o.id = production_order_items.production_id
        AND public.is_manager_of_store(o.store_id)
    )
  );
DROP POLICY IF EXISTS production_order_items_insert
  ON public.production_order_items;
CREATE POLICY production_order_items_insert ON public.production_order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.production_orders o
      WHERE o.id = production_order_items.production_id
        AND public.is_manager_of_store(o.store_id)
        AND public.mfa_ok()
    )
  );
DROP POLICY IF EXISTS production_order_items_update
  ON public.production_order_items;
CREATE POLICY production_order_items_update ON public.production_order_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.production_orders o
      WHERE o.id = production_order_items.production_id
        AND public.is_manager_of_store(o.store_id)
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.production_orders o
      WHERE o.id = production_order_items.production_id
        AND public.is_manager_of_store(o.store_id)
        AND public.mfa_ok()
    )
  );
DROP POLICY IF EXISTS production_order_items_delete
  ON public.production_order_items;
CREATE POLICY production_order_items_delete ON public.production_order_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.production_orders o
      WHERE o.id = production_order_items.production_id
        AND public.is_manager_of_store(o.store_id)
    )
  );

CREATE INDEX IF NOT EXISTS idx_recipes_store
  ON public.recipes (store_id);
CREATE INDEX IF NOT EXISTS idx_recipe_items_recipe
  ON public.recipe_items (recipe_id);
CREATE INDEX IF NOT EXISTS idx_production_orders_store
  ON public.production_orders (store_id, date_time DESC);
CREATE INDEX IF NOT EXISTS idx_production_order_items_order
  ON public.production_order_items (production_id);

-- RPC atômica: baixa FIFO dos componentes + lote do produto acabado.
CREATE OR REPLACE FUNCTION public.process_production(
  p_order jsonb,
  p_items jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_order->>'store_id';
  v_product text := p_order->>'product_id';
  v_qty bigint := (p_order->>'quantity')::bigint;
  v_recipe text := NULLIF(p_order->>'recipe_id', '');
  v_item jsonb;
  v_remaining bigint;
  v_lot record;
  v_take bigint;
  v_total_cost bigint := 0;
  v_cost_price bigint;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registar a produção.';
  END IF;
  IF NOT public.mfa_ok(v_uid) THEN
    RAISE EXCEPTION 'MFA exigido: conclua a verificação em dois fatores para registar produção.';
  END IF;
  IF NOT public.is_manager_of_store(v_store) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem registar produção na loja %.', v_store;
  END IF;
  IF EXISTS (SELECT 1 FROM public.production_orders
             WHERE id = p_order->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A produção deve consumir ao menos um componente.';
  END IF;
  IF v_qty <= 0 THEN
    RAISE EXCEPTION 'A quantidade produzida deve ser maior que zero.';
  END IF;

  PERFORM 1 FROM public.products
    WHERE id = v_product AND store_id = v_store AND is_active
    FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'O produto acabado % não existe ou está desativado na loja %.',
      v_product, v_store;
  END IF;

  PERFORM public.lock_products_or_raise(p_items, v_store, TRUE);

  SELECT COALESCE(SUM((x->>'quantity')::bigint * pr.purchase_price / 1000), 0)
    INTO v_total_cost
  FROM jsonb_array_elements(p_items) x
  JOIN public.products pr
    ON pr.id = (x->>'product_id') AND pr.store_id = v_store;

  v_cost_price := v_total_cost * 1000 / v_qty;

  INSERT INTO public.production_orders
    (id, user_id, store_id, product_id, product_name, quantity, recipe_id,
     cost_price, total_cost, date_time)
  VALUES (p_order->>'id', v_uid, v_store, v_product, p_order->>'product_name',
          v_qty, v_recipe, v_cost_price, v_total_cost,
          (p_order->>'date_time')::timestamptz);

  INSERT INTO public.production_order_items
    (production_id, user_id, product_id, product_name, quantity, unit_cost)
  SELECT p_order->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::bigint, pr.purchase_price
  FROM jsonb_array_elements(p_items) x
  JOIN public.products pr
    ON pr.id = (x->>'product_id') AND pr.store_id = v_store;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_remaining := (v_item->>'quantity')::bigint;
    FOR v_lot IN
      SELECT l.id, l.current_quantity
      FROM public.stock_lots l
      WHERE l.product_id = (v_item->>'product_id') AND l.store_id = v_store
        AND l.current_quantity > 0
      ORDER BY l.expiry_date ASC NULLS LAST, l.entry_date ASC, l.id ASC
      FOR UPDATE
    LOOP
      IF v_remaining <= 0 THEN EXIT; END IF;
      v_take := LEAST(v_lot.current_quantity, v_remaining);
      UPDATE public.stock_lots
        SET current_quantity = current_quantity - v_take
        WHERE id = v_lot.id AND store_id = v_store;
      v_remaining := v_remaining - v_take;
    END LOOP;
    IF v_remaining > 0 THEN
      RAISE EXCEPTION 'Stock insuficiente para o componente % (loja %).',
        v_item->>'product_id', v_store;
    END IF;
    UPDATE public.products
      SET stock_quantity = stock_quantity - (v_item->>'quantity')::bigint
      WHERE id = (v_item->>'product_id') AND store_id = v_store;
  END LOOP;

  INSERT INTO public.stock_lots
    (id, user_id, store_id, product_id, entry_date, expiry_date,
     initial_quantity, current_quantity, cost_price)
  VALUES ('lot-production-' || (p_order->>'id'), v_uid, v_store, v_product,
          (p_order->>'date_time')::timestamptz, NULL, v_qty, v_qty,
          v_cost_price);

  UPDATE public.products
    SET stock_quantity = stock_quantity + v_qty
    WHERE id = v_product AND store_id = v_store;
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_production(jsonb, jsonb)
  TO authenticated;

ANALYZE public.recipes;
ANALYZE public.production_orders;
