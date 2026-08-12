-- ============================================================================
-- Dumbhanengue ERP — RESET (ZERAR) os dados operacionais de UM tenant
-- ============================================================================
-- ⚠️⚠️ DESTRUTIVO E IRREVERSÍVEL — apaga TODO o histórico operacional do
-- tenant: produtos, vendas (itens + consumo de lotes), compras (itens),
-- estoque (lotes FIFO), financeiro, fiados/dívidas, clientes e fechos de
-- caixa (Z-report). Não é possível desfazer por SQL: FAÇA BACKUP antes.
--
-- Ao final, o tenant volta ao estado "limpo" e continua OPERACIONAL:
-- as contas de login (auth.users), as lojas, os funcionários e o plano
-- permanecem intactos — ele pode recomeçar a operar imediatamente
-- (cadastrar produtos, registrar vendas, abrir o caixa... do zero).
--
-- COMO USAR (Supabase Dashboard → SQL Editor):
--   1. FAÇA BACKUP antes (Projeto → Database → Backups). ⚠️
--   2. Descubra o id do tenant alvo:
--        SELECT id, name FROM public.tenants;
--   3. Troque o valor na seção "PARÂMETRO (TENANT ALVO)" abaixo.
--   4. Execute o script INTEIRO (em uma única execução). Ele valida o
--      tenant, apaga na ordem correta das FKs e imprime a sanidade final.
--
-- O QUE É PRESERVADO (de propósito):
--   • tenants / stores / store_employees / plan_requests / plans
--   • auth.users — as contas de login de dono e funcionários seguem
--   • audit_log — a trilha de auditoria NÃO é tocada
--   • storage — as fotos ficam órfãs (seção OPCIONAL no final as apaga)
--
-- Idempotente: reexecutar não tem efeito (os DELETEs já executados
-- simplesmente não encontram linhas). Rode com o usuário dono do schema
-- (o SQL Editor do Supabase usa o papel `postgres`, que ignora o RLS).
-- ============================================================================

-- ============================ PARÂMETRO (TENANT ALVO) =======================
-- ⬇️  Troque 'SUBSTITUIR_AQUI' pelo id do tenant (ex.: 'tn_abc123').
SELECT set_config('app.reset_tenant_id', 'SUBSTITUIR_AQUI', false);
-- ============================================================================

DO $$
DECLARE
  p_tenant_id TEXT := NULLIF(current_setting('app.reset_tenant_id', true), '');
  v_store_count INT;
BEGIN
  -- 0. Validações de segurança ------------------------------------------------
  -- O marcador é montado por concatenação para que um find-and-replace
  -- global de 'SUBSTITUIR_AQUI' no SQL Editor NÃO troque também esta
  -- comparação (se trocasse, o guard bloquearia o reset para sempre).
  IF p_tenant_id IS NULL OR p_tenant_id = 'SUBSTITUIR' || '_AQUI' THEN
    RAISE EXCEPTION 'Defina o tenant alvo no parâmetro app.reset_tenant_id (seção "PARÂMETRO (TENANT ALVO)" no topo do script).';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_tenant_id) THEN
    RAISE EXCEPTION 'Tenant "%" não encontrado em public.tenants — reset abortado.', p_tenant_id;
  END IF;

  SELECT count(*) INTO v_store_count
    FROM public.stores
    WHERE tenant_id = p_tenant_id;

  RAISE NOTICE 'Reset do tenant % — % loja(s) afetada(s).', p_tenant_id, v_store_count;

  -- 1. Consumo de lotes + itens de venda (filhos de sales) -------------------
  DELETE FROM public.sale_lot_consumption
    WHERE sale_id IN (
      SELECT s.id FROM public.sales s
      JOIN public.stores st ON st.id = s.store_id
      WHERE st.tenant_id = p_tenant_id);

  DELETE FROM public.sale_items
    WHERE sale_id IN (
      SELECT s.id FROM public.sales s
      JOIN public.stores st ON st.id = s.store_id
      WHERE st.tenant_id = p_tenant_id);

  -- 2. Vendas -----------------------------------------------------------------
  DELETE FROM public.sales s
    USING public.stores st
    WHERE st.id = s.store_id AND st.tenant_id = p_tenant_id;

  -- 3. Itens de compra (filhos de purchases) ----------------------------------
  DELETE FROM public.purchase_items
    WHERE purchase_id IN (
      SELECT p.id FROM public.purchases p
      JOIN public.stores st ON st.id = p.store_id
      WHERE st.tenant_id = p_tenant_id);

  -- 4. Compras -----------------------------------------------------------------
  DELETE FROM public.purchases p
    USING public.stores st
    WHERE st.id = p.store_id AND st.tenant_id = p_tenant_id;

  -- 5. Fechos de caixa (Z-report) ----------------------------------------------
  DELETE FROM public.cash_closings c
    USING public.stores st
    WHERE st.id = c.store_id AND st.tenant_id = p_tenant_id;

  -- 6. Financeiro (caixa) -------------------------------------------------------
  DELETE FROM public.financial_transactions f
    USING public.stores st
    WHERE st.id = f.store_id AND st.tenant_id = p_tenant_id;

  -- 7. Fiados / dívidas ----------------------------------------------------------
  DELETE FROM public.debts d
    USING public.stores st
    WHERE st.id = d.store_id AND st.tenant_id = p_tenant_id;

  -- 8. Clientes -------------------------------------------------------------------
  DELETE FROM public.customers c
    USING public.stores st
    WHERE st.id = c.store_id AND st.tenant_id = p_tenant_id;

  -- 9. Lotes FIFO (estoque) ---------------------------------------------------------
  DELETE FROM public.stock_lots l
    USING public.stores st
    WHERE st.id = l.store_id AND st.tenant_id = p_tenant_id;

  -- 10. Produtos ---------------------------------------------------------------------
  DELETE FROM public.products p
    USING public.stores st
    WHERE st.id = p.store_id AND st.tenant_id = p_tenant_id;

  RAISE NOTICE 'Reset concluído para o tenant %.', p_tenant_id;
END $$;

-- ============================ SANIDADE (pós-reset) ===========================
-- O tenant continua com lojas/funcionários; os dados operacionais zerados.
SELECT
  (SELECT id FROM public.tenants
     WHERE id = current_setting('app.reset_tenant_id', true))          AS tenant,
  (SELECT count(*) FROM public.stores
     WHERE tenant_id = current_setting('app.reset_tenant_id', true))   AS lojas_preservadas,
  (SELECT count(*) FROM public.store_employees
     WHERE tenant_id = current_setting('app.reset_tenant_id', true))   AS funcionarios_preservados,
  (SELECT count(*) FROM public.products
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS produtos,
  (SELECT count(*) FROM public.sales
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS vendas,
  (SELECT count(*) FROM public.purchases
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS compras,
  (SELECT count(*) FROM public.stock_lots
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS lotes_estoque,
  (SELECT count(*) FROM public.financial_transactions
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS transacoes,
  (SELECT count(*) FROM public.debts
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS fiados,
  (SELECT count(*) FROM public.customers
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS clientes,
  (SELECT count(*) FROM public.cash_closings
     WHERE store_id IN (SELECT id FROM public.stores
       WHERE tenant_id = current_setting('app.reset_tenant_id', true))) AS fechos_caixa;

-- ===================== OPCIONAL: limpar fotos no Storage ====================
-- As fotos de produto ficam no bucket 'product-images' em pastas por loja
-- (o nome da pasta = store_id). Após o reset, elas ficam órfãs (o app não as
-- mostra, pois os produtos sumiram). Descomente para apagá-las também:
--
-- DELETE FROM storage.objects
--   WHERE bucket_id = 'product-images'
--     AND (storage.foldername(name))[1] IN (
--       SELECT id FROM public.stores
--       WHERE tenant_id = current_setting('app.reset_tenant_id', true));

-- ====================== PARA ZERAR TODOS OS TENANTS =========================
-- Se um dia precisar limpar a base inteira (sem tocar nas contas), substitua
-- os filtros `st.tenant_id = p_tenant_id` por um WHERE SEM filtro de tenant.
