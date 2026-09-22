BEGIN;

-- Sem LOCK TABLE: a troca é só de TEXTO das mensagens — CREATE OR REPLACE
-- FUNCTION é atômico e chamadas em voo terminam com a definição antiga.
-- Vendas/compras/fiado seguem fluindo durante o patch.
DO $do$
DECLARE
  r     record;
  v_def text;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure::text AS sig,
           pg_get_functiondef(p.oid)  AS def
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN ('process_sale', 'register_debt', 'settle_debt', 'process_purchase', 'adjust_product_stock', 'lock_products_or_raise', 'enforce_store_limit')
  LOOP
    v_def := r.def;
    v_def := replace(v_def, 'Estoque insuficiente para o produto % (loja %).', 'Stock insuficiente para o produto % (loja %).');
    v_def := replace(v_def, 'Sessão necessária para ajustar o estoque.', 'Sessão necessária para ajustar o stock.');
    v_def := replace(v_def, 'MFA exigido: conclua a verificação em dois fatores para ajustar o estoque.', 'MFA exigido: conclua a verificação em dois fatores para ajustar o stock.');
    v_def := replace(v_def, 'Apenas o dono ou um gerente podem ajustar o estoque na loja %.', 'Apenas o dono ou um gerente podem ajustar o stock na loja %.');
    v_def := replace(v_def, 'O estoque não pode ficar negativo.', 'O stock não pode ficar negativo.');
    v_def := replace(v_def, 'Estoque insuficiente para ajustar o produto % (loja %).', 'Stock insuficiente para ajustar o produto % (loja %).');
    v_def := replace(v_def, 'Sessão necessária para registrar a venda.', 'Sessão necessária para registar a venda.');
    v_def := replace(v_def, 'A loja % não pertence ao usuário logado.', 'A loja % não pertence ao utilizador autenticado.');
    v_def := replace(v_def, 'Sessão necessária para registrar o fiado.', 'Sessão necessária para registar o fiado.');
    v_def := replace(v_def, 'MFA exigido: conclua a verificação em dois fatores para registrar fiado.', 'MFA exigido: conclua a verificação em dois fatores para registar fiado.');
    v_def := replace(v_def, 'Sessão necessária para registrar a compra.', 'Sessão necessária para registar a compra.');
    v_def := replace(v_def, 'MFA exigido: conclua a verificação em dois fatores para registrar compras.', 'MFA exigido: conclua a verificação em dois fatores para registar compras.');
    v_def := replace(v_def, 'Apenas o dono ou um gerente podem registrar compras na loja %.', 'Apenas o dono ou um gerente podem registar compras na loja %.');
    v_def := replace(v_def, 'Tenant do usuário não encontrado.', 'Tenant do utilizador não encontrado.');
    IF v_def IS DISTINCT FROM r.def THEN
      EXECUTE v_def;  -- def começa com CREATE OR REPLACE FUNCTION ...
      RAISE NOTICE 'Parte 24: % atualizada', r.sig;
    ELSE
      RAISE NOTICE 'Parte 24: % sem mensagens-alvo (no-op)', r.sig;
    END IF;
  END LOOP;
END
$do$;

-- Verificação (gate): nenhuma mensagem pt-BR pode sobrar nas funções tocadas.
DO $do$
DECLARE
  v_left int;
BEGIN
  SELECT count(*) INTO v_left
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.proname IN ('process_sale', 'register_debt', 'settle_debt', 'process_purchase', 'adjust_product_stock', 'lock_products_or_raise', 'enforce_store_limit')
     AND (pg_get_functiondef(p.oid) LIKE '%Estoque insuficiente para o produto % (loja %).%'
        OR pg_get_functiondef(p.oid) LIKE '%Sessão necessária para ajustar o estoque.%'
        OR pg_get_functiondef(p.oid) LIKE '%MFA exigido: conclua a verificação em dois fatores para ajustar o estoque.%'
        OR pg_get_functiondef(p.oid) LIKE '%Apenas o dono ou um gerente podem ajustar o estoque na loja %.%'
        OR pg_get_functiondef(p.oid) LIKE '%O estoque não pode ficar negativo.%'
        OR pg_get_functiondef(p.oid) LIKE '%Estoque insuficiente para ajustar o produto % (loja %).%'
        OR pg_get_functiondef(p.oid) LIKE '%Sessão necessária para registrar a venda.%'
        OR pg_get_functiondef(p.oid) LIKE '%A loja % não pertence ao usuário logado.%'
        OR pg_get_functiondef(p.oid) LIKE '%Sessão necessária para registrar o fiado.%'
        OR pg_get_functiondef(p.oid) LIKE '%MFA exigido: conclua a verificação em dois fatores para registrar fiado.%'
        OR pg_get_functiondef(p.oid) LIKE '%Sessão necessária para registrar a compra.%'
        OR pg_get_functiondef(p.oid) LIKE '%MFA exigido: conclua a verificação em dois fatores para registrar compras.%'
        OR pg_get_functiondef(p.oid) LIKE '%Apenas o dono ou um gerente podem registrar compras na loja %.%'
        OR pg_get_functiondef(p.oid) LIKE '%Tenant do usuário não encontrado.%');
  IF v_left > 0 THEN
    RAISE EXCEPTION 'FAIL Parte 24: % mensagens pt-BR restantes', v_left;
  END IF;
  RAISE NOTICE 'PASS Parte 24: mensagens pt-MZ aplicadas';
END
$do$;

COMMIT;
