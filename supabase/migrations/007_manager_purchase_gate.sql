-- ============================================================================
-- 007 — Níveis de acesso: compras são nível GERENCIAL (matriz de acesso)
--
-- Contexto (Aug 6): o app tem três papéis — DONO (gestão total), GERENTE
-- (operação completa: vendas, produtos, financeiro, fiado, clientes, compras
-- e relatórios) e FUNCIONÁRIO (apenas operação diária: vendas, produtos,
-- financeiro, fiado e clientes — SEM compras, SEM relatórios, SEM gestão).
--
-- Esta migração reforça a regra NO SERVIDOR (a autoridade, mesmo que um
-- cliente modificado chame o PostgREST diretamente):
--   1. novo helper SECURITY DEFINER `public.is_manager_of_store(store_id)` —
--      dono do tenant OU funcionário com cargo 'manager' no vínculo;
--   2. a RPC `process_purchase` passa a exigir `is_manager_of_store`
--      (funcionário comum não registra compras);
--   3. as políticas RLS de `purchases`/`purchase_items` passam a exigir
--      `is_manager_of_store` — leitura E escrita (o app esconde na UI, o
--      banco nega por construção).
--
-- ⚠️ REEXECUTÁVEL (idempotente): pode rodar quantas vezes quiser — os
-- helpers são CREATE OR REPLACE e as políticas são DROP + CREATE.
--
-- ⚠️ Executar no SQL Editor do dashboard do projeto (supabase.com).
-- ============================================================================

-- ---------------------------------------------------------------
-- 1. Helper: usuário tem PODER DE GESTÃO na loja? (dono OU gerente)
-- ---------------------------------------------------------------
-- SECURITY DEFINER + search_path fixo: mesmo padrão de is_my_store/
-- is_tenant_owner — evita ciclo entre tabelas (regressão 54001) e só
-- devolve um BOOLEAN sobre um id explícito.
CREATE OR REPLACE FUNCTION public.is_manager_of_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = target_store_id
      AND (
        public.is_tenant_owner(s.tenant_id)
        OR EXISTS (
          SELECT 1 FROM public.store_employees e
          WHERE e.store_id = s.id AND e.user_id = auth.uid()
            AND e.role = 'manager'
        )
      )
  );
$$;

-- ---------------------------------------------------------------
-- 2. RPC process_purchase: guarda gerencial (dono ou gerente)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_purchase(p_purchase jsonb, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_store text := p_purchase->>'store_id';
  v_total numeric := (p_purchase->>'total_amount')::numeric;
  v_lang text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para registrar a compra.';
  END IF;
  -- Guarda de nível gerencial (matriz de acesso Aug 6): compras exigem
  -- DONO ou GERENTE da loja — o funcionário comum opera vendas/estoque,
  -- mas NÃO registra compras. Substitui o RLS dentro do SECURITY DEFINER.
  IF NOT public.is_manager_of_store(v_store) THEN
    RAISE EXCEPTION 'Apenas o dono ou um gerente podem registrar compras na loja %.', v_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = v_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
    v_lang := 'pt';
  END IF;
  -- Idempotência: o id da compra é a chave de idempotência.
  IF EXISTS (SELECT 1 FROM public.purchases WHERE id = p_purchase->>'id' AND store_id = v_store) THEN
    RETURN;
  END IF;
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A compra deve conter ao menos um item.';
  END IF;

  IF ROUND((SELECT SUM((x->>'quantity')::numeric * (x->>'unit_price')::numeric)
            FROM jsonb_array_elements(p_items) x) * 100)
     <> ROUND(v_total * 100) THEN
    RAISE EXCEPTION 'O total da compra não corresponde aos itens.';
  END IF;

  -- Valida e trava a existência de TODOS os produtos ANTES de mutar.
  PERFORM public.lock_products_or_raise(p_items, v_store, FALSE);

  -- Compra + itens.
  INSERT INTO public.purchases
    (id, user_id, store_id, supplier_name, total_amount, date_time)
  VALUES (p_purchase->>'id', v_uid, v_store, p_purchase->>'supplier_name',
          v_total, (p_purchase->>'date_time')::timestamptz);

  INSERT INTO public.purchase_items
    (purchase_id, user_id, product_id, product_name, quantity, unit_price)
  SELECT p_purchase->>'id', v_uid, (x->>'product_id'), (x->>'product_name'),
         (x->>'quantity')::int, (x->>'unit_price')::numeric
  FROM jsonb_array_elements(p_items) x;

  -- Entrada de estoque (produtos já validados acima).
  UPDATE public.products p
  SET stock_quantity = p.stock_quantity + (x->>'quantity')::int
  FROM jsonb_array_elements(p_items) x
  WHERE p.id = (x->>'product_id') AND p.store_id = v_store;

  -- Saída no caixa (mesma transação).
  INSERT INTO public.financial_transactions
    (id, user_id, store_id, description, amount, type, category, date, status)
  VALUES ('t' || (p_purchase->>'id'), v_uid, v_store,
          CASE WHEN v_lang = 'en'
               THEN 'Purchase — ' || (p_purchase->>'supplier_name')
               ELSE 'Compra — ' || (p_purchase->>'supplier_name') END,
          v_total, 'expense',
          CASE WHEN v_lang = 'en' THEN 'Purchases' ELSE 'Compras' END,
          (p_purchase->>'date_time')::timestamptz, 'paid');
END;
$$;

-- ---------------------------------------------------------------
-- 3. Políticas RLS de compras: nível gerencial (manager+)
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS purchases_select ON public.purchases;
CREATE POLICY purchases_select ON public.purchases
  FOR SELECT USING (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_insert ON public.purchases;
CREATE POLICY purchases_insert ON public.purchases
  FOR INSERT WITH CHECK (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_update ON public.purchases;
CREATE POLICY purchases_update ON public.purchases
  FOR UPDATE USING (public.is_manager_of_store(store_id))
  WITH CHECK (public.is_manager_of_store(store_id));
DROP POLICY IF EXISTS purchases_delete ON public.purchases;
-- DELETE gerencial (intencional): compras são nível manager+ — um gerente
-- pode remover QUALQUER compra da loja (incluindo do dono), consistente com
-- o papel gerencial. O app não exclui nada hoje; se um dia excluir, a regra
-- continua coerente com a matriz (o dono cobre tudo via is_tenant_owner).
CREATE POLICY purchases_delete ON public.purchases
  FOR DELETE USING (public.is_manager_of_store(store_id));

DROP POLICY IF EXISTS purchase_items_select ON public.purchase_items;
CREATE POLICY purchase_items_select ON public.purchase_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_insert ON public.purchase_items;
CREATE POLICY purchase_items_insert ON public.purchase_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_update ON public.purchase_items;
CREATE POLICY purchase_items_update ON public.purchase_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
DROP POLICY IF EXISTS purchase_items_delete ON public.purchase_items;
CREATE POLICY purchase_items_delete ON public.purchase_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.purchases p
      WHERE p.id = purchase_items.purchase_id
        AND public.is_manager_of_store(p.store_id)
    )
  );
