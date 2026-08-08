#!/usr/bin/env bash
# sql_check_live.sh — Verificação READ-ONLY do schema no projeto Supabase AO VIVO.
#
# ⚠️ DIFERENTE do sql_check.sh (que DROP SCHEMA public CASCADE num Postgres
# descartável): este script NUNCA grava nada. Tudo roda dentro de uma
# transação BEGIN READ ONLY — qualquer escrita acidental falha na hora.
#
# Verifica os objetos críticos do supabase/schema.sql no banco real:
#   C3 → tabela public.super_admins (existe, RLS ON, ZERO policies) e
#        is_super_admin() SECURITY DEFINER lendo a tabela (não e-mail)
#   C4 → settle_debt(text,text) + index idx_financial_transactions_debt
#   RPCs atômicos → process_sale / process_purchase / register_debt
#   RLS → habilitado nas 14 tabelas; plans_update usa is_super_admin()
#   W4 → as 9 colunas de dinheiro em BIGINT (centavos) e NENHUM valor
#        fracionário (migração ×100 completa — upgrade.sql, Parte 7)
#   W5/H2 → get_dashboard_kpis / get_cash_flow / get_sales_report
#        presentes, SECURITY DEFINER, com retornos BIGINT (não NUMERIC
#        pré-W4)
#   Numeração → sale_number / purchase_number / debt_number (BIGINT NOT
#        NULL + índices únicos por loja + RPCs com advisory lock)
#   M-Pesa/E-Mola → CHECKs de payment_method em sales/purchases com
#        mPesa/eMola (Partes 17-18 — sem isso, QUALQUER venda/compra nova
#        viola o constraint)
#   Funcionários → store_employees.is_active + RPC set_employee_active
#        (Parte 19) e publicação Realtime de store_employees (Parte 20)
#   Migração → quantidade de super_admins registrados (informativo)
#
# Uso:
#   SUPABASE_DB_URL='postgresql://postgres.<ref>:<SENHA>@aws-0-<região>.pooler.supabase.com:6543/postgres' \
#     bash scripts/sql_check_live.sh
#   (ou passe a URL como primeiro argumento)
#
# Onde obter a URL: Supabase Dashboard → Settings → Database → Connection
# string (use a porta 6543 do pooler ou a 5432 direta; sslmode=require).
#
# Sem psql local? Rode via container (a imagem postgres:16 tem psql):
#   SUPABASE_DB_URL='...' MSYS_NO_PATHCONV=1 docker run --rm -i \
#     -e SUPABASE_DB_URL postgres:16 bash /workspace/scripts/sql_check_live.sh
#
# ⚠️ NUNCA rode o scripts/sql_check.sh contra este banco: ele apaga o
# schema public. Use SOMENTE este script (ou inspeção manual no SQL Editor).

set -u

DB_URL="${SUPABASE_DB_URL:-${1:-}}"
if [ -z "$DB_URL" ]; then
  echo "ERRO: informe SUPABASE_DB_URL (ou a connection string como 1º argumento)." >&2
  echo "  Ex.: SUPABASE_DB_URL='postgresql://...' bash scripts/sql_check_live.sh" >&2
  exit 2
fi

case "$DB_URL" in
  postgres://*|postgresql://*) ;;
  *) echo "ERRO: SUPABASE_DB_URL deve começar com postgres:// ou postgresql://" >&2; exit 2 ;;
esac

HOST=$(printf '%s' "$DB_URL" | sed -E 's#^[a-z]+://[^@]*@##; s#[:/].*##')
echo "Alvo : $HOST"
echo "Modo : SOMENTE LEITURA (transação READ ONLY — nenhuma escrita é executada)"
echo

# ── Checks SQL (read-only) ──────────────────────────────────────────────
CHECKS=$(mktemp) || exit 2
trap 'rm -f "$CHECKS"' EXIT

cat > "$CHECKS" <<'SQL'
SET statement_timeout = '30s';
SET TRANSACTION READ ONLY;

\echo '== 1. conexão e versão =='
SELECT current_database() AS db, current_user AS role;

\echo '== 2. public.super_admins: existe + RLS ON + zero policies (C3) =='
DO $$
BEGIN
  IF to_regclass('public.super_admins') IS NULL THEN
    RAISE EXCEPTION 'FAIL: tabela public.super_admins NAO existe (rodar schema.sql no SQL Editor)';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.super_admins'::regclass) THEN
    RAISE EXCEPTION 'FAIL: public.super_admins com RLS desabilitado';
  END IF;
  IF (SELECT count(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'super_admins') <> 0 THEN
    RAISE EXCEPTION 'FAIL: public.super_admins tem policies (deveria ter ZERO para impedir auto-promocao)';
  END IF;
  RAISE NOTICE 'PASS: super_admins existe, RLS ON, sem policies';
END $$;

\echo '== 3. is_super_admin(): SECURITY DEFINER lendo a tabela (C3) =='
DO $$
DECLARE
  v_oid oid := to_regprocedure('public.is_super_admin()');
  v_def text;
BEGIN
  IF v_oid IS NULL THEN RAISE EXCEPTION 'FAIL: is_super_admin() ausente'; END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = v_oid) THEN
    RAISE EXCEPTION 'FAIL: is_super_admin() nao e SECURITY DEFINER';
  END IF;
  SELECT pg_get_functiondef(v_oid) INTO v_def;
  IF position('super_admins' IN v_def) = 0 THEN
    RAISE EXCEPTION 'FAIL: is_super_admin() nao referencia super_admins (versao antiga por e-mail ainda no ar?)';
  END IF;
  RAISE NOTICE 'PASS: is_super_admin() OK (SECURITY DEFINER, DB-backed)';
END $$;

\echo '== 4. RPCs atomicos do money path: SECURITY DEFINER (1.1/1.1b/1.1c/C4 + 005) =='
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT unnest(ARRAY[
    'public.process_sale(jsonb,jsonb)',
    'public.process_purchase(jsonb,jsonb)',
    'public.register_debt(jsonb)',
    'public.settle_debt(text,text)',
    'public.create_employee_account(text,text,text,text,text,text)',
    'public.update_tenant_settings(text,text,text)'
  ]) AS sig
  LOOP
    IF to_regprocedure(r.sig) IS NULL THEN
      RAISE EXCEPTION 'FAIL: RPC % ausente (rodar schema.sql/upgrade.sql)', r.sig;
    END IF;
    IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = to_regprocedure(r.sig)) THEN
      RAISE EXCEPTION 'FAIL: % nao e SECURITY DEFINER', r.sig;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: process_sale / process_purchase / register_debt / settle_debt / create_employee_account / update_tenant_settings OK';
END $$;

\echo '== 5. index idx_financial_transactions_debt (C4) =='
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'idx_financial_transactions_debt'
  ) THEN
    RAISE EXCEPTION 'FAIL: index idx_financial_transactions_debt ausente';
  END IF;
  RAISE NOTICE 'PASS: index idx_financial_transactions_debt OK';
END $$;

\echo '== 6. funcoes de trigger e helpers =='
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT unnest(ARRAY[
    'public.set_tenant_user_id()',
    'public.enforce_store_limit()',
    'public.enforce_employee_limit()',
    'public.lock_products_or_raise(jsonb,text,boolean)',
    'public.is_tenant_owner(text)'
  ]) AS sig
  LOOP
    IF to_regprocedure(r.sig) IS NULL THEN
      RAISE EXCEPTION 'FAIL: funcao % ausente', r.sig;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: triggers/helpers presentes';
END $$;

\echo '== 7. RLS habilitado nas 14 tabelas =='
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT unnest(ARRAY[
    'products','sales','sale_items','financial_transactions','debts',
    'customers','purchases','purchase_items','plans','tenants','stores',
    'store_employees','plan_requests','super_admins'
  ]) AS t
  LOOP
    IF to_regclass('public.' || r.t) IS NULL THEN
      RAISE EXCEPTION 'FAIL: tabela public.% ausente', r.t;
    END IF;
    IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = to_regclass('public.' || r.t)) THEN
      RAISE EXCEPTION 'FAIL: RLS desabilitado em %', r.t;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: RLS ON em todas as 14 tabelas';
END $$;

\echo '== 8. policy plans_update usa is_super_admin() (C3) =='
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'plans' AND policyname = 'plans_update'
      AND (qual LIKE '%is_super_admin%' OR with_check LIKE '%is_super_admin%')
  ) THEN
    RAISE EXCEPTION 'FAIL: plans_update sem is_super_admin()';
  END IF;
  RAISE NOTICE 'PASS: plans_update usa is_super_admin()';
END $$;

\echo '== 9. migração do super admin legado (informativo) =='
SELECT count(*) AS super_admins_registrados FROM public.super_admins;

\echo '== 10. RPC read-only is_super_admin() executável (informativo) =='
SELECT public.is_super_admin() AS is_super_admin_do_role_atual;

\echo '== 11. W4: as 9 colunas de dinheiro em BIGINT (centavos) =='
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT unnest(ARRAY[
    'products.purchase_price',
    'products.sale_price',
    'sales.total_amount',
    'sale_items.unit_price',
    'financial_transactions.amount',
    'debts.amount',
    'purchases.total_amount',
    'purchase_items.unit_price',
    'plans.price_monthly'
  ]) AS col
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = split_part(r.col, '.', 1)
        AND column_name = split_part(r.col, '.', 2)
        AND data_type = 'bigint'
    ) THEN
      RAISE EXCEPTION 'FAIL: % deveria ser bigint (W4/upgrade.sql Parte 7 nao aplicado?)', r.col;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: 9 colunas de dinheiro em BIGINT (centavos)';
END $$;

\echo '== 12. W4: nenhum valor de dinheiro fracionário (migração ×100 completa) =='
DO $$
DECLARE
  r record;
  v_bad integer;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('products','purchase_price'), ('products','sale_price'),
    ('sales','total_amount'), ('sale_items','unit_price'),
    ('financial_transactions','amount'), ('debts','amount'),
    ('purchases','total_amount'), ('purchase_items','unit_price'),
    ('plans','price_monthly')
  ) AS t(tbl, col)
  LOOP
    EXECUTE format(
      'SELECT count(*) FROM public.%I WHERE %I <> floor(%I)',
      r.tbl, r.col, r.col
    ) INTO v_bad;
    IF v_bad > 0 THEN
      RAISE EXCEPTION 'FAIL: % valor(es) fracionário(s) em %.% (migração ×100 incompleta)', v_bad, r.tbl, r.col;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: todos os valores de dinheiro são inteiros (centavos)';
END $$;

\echo '== 13. W5/H2: RPCs de agregação presentes + SECURITY DEFINER =='
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT unnest(ARRAY[
    'public.get_dashboard_kpis(text,timestamptz,timestamptz)',
    'public.get_cash_flow(text,timestamptz,timestamptz)',
    'public.get_sales_report(text,timestamptz,timestamptz,int)'
  ]) AS sig
  LOOP
    IF to_regprocedure(r.sig) IS NULL THEN
      RAISE EXCEPTION 'FAIL: RPC % ausente (rodar supabase/upgrade.sql)', r.sig;
    END IF;
    IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = to_regprocedure(r.sig)) THEN
      RAISE EXCEPTION 'FAIL: % nao e SECURITY DEFINER', r.sig;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: get_dashboard_kpis / get_cash_flow / get_sales_report OK';
END $$;

\echo '== 14. W4/H2: retornos das RPCs em BIGINT (não NUMERIC pré-W4) =='
DO $$
DECLARE
  v_kpis text;
  v_cf text;
BEGIN
  SELECT pg_get_function_result(oid) INTO v_kpis
  FROM pg_proc WHERE oid = to_regprocedure('public.get_dashboard_kpis(text,timestamptz,timestamptz)');
  SELECT pg_get_function_result(oid) INTO v_cf
  FROM pg_proc WHERE oid = to_regprocedure('public.get_cash_flow(text,timestamptz,timestamptz)');
  IF lower(v_kpis) NOT LIKE '%bigint%' THEN
    RAISE EXCEPTION 'FAIL: get_dashboard_kpis nao devolve BIGINT (versao pre-W4 NUMERIC?): %', v_kpis;
  END IF;
  IF lower(v_cf) NOT LIKE '%bigint%' THEN
    RAISE EXCEPTION 'FAIL: get_cash_flow nao devolve BIGINT: %', v_cf;
  END IF;
  RAISE NOTICE 'PASS: get_dashboard_kpis e get_cash_flow com retornos BIGINT (centavos)';
END $$;

\echo '== 15. Numeração sequencial de vendas por loja (sale_number) =='
DO $$
DECLARE
  v_type text;
  v_notnull boolean;
  v_def text;
BEGIN
  -- Coluna sale_number: BIGINT, NOT NULL.
  SELECT data_type, is_nullable
  INTO v_type, v_notnull
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'sales'
    AND column_name = 'sale_number';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'FAIL: coluna sales.sale_number ausente (upgrade.sql Parte 14 nao aplicado?)';
  END IF;
  IF v_type <> 'bigint' OR v_notnull = 'YES' THEN
    RAISE EXCEPTION 'FAIL: sales.sale_number deveria ser bigint NOT NULL (atual: % not_null=%)', v_type, v_notnull;
  END IF;
  -- Índice único por loja.
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'uq_sales_store_number'
  ) THEN
    RAISE EXCEPTION 'FAIL: indice unico uq_sales_store_number ausente';
  END IF;
  -- RPC process_sale atualizada (atribui o número com advisory lock).
  SELECT pg_get_functiondef(oid) INTO v_def
  FROM pg_proc WHERE oid = to_regprocedure('public.process_sale(jsonb,jsonb)');
  IF position('pg_advisory_xact_lock' IN v_def) = 0
     OR position('sale_number' IN v_def) = 0 THEN
    RAISE EXCEPTION 'FAIL: process_sale nao atribui sale_number (versao antiga no ar?)';
  END IF;
  RAISE NOTICE 'PASS: sale_number bigint NOT NULL + uq_sales_store_number + process_sale com advisory lock';
END $$;

\echo '== 16. sale_number sem valores nulos (informativo) =='
SELECT count(*) AS vendas, count(sale_number) AS com_numero
FROM public.sales;

\echo '== 17. Numeração sequencial de compras por loja (purchase_number) =='
DO $$
DECLARE
  v_type text;
  v_notnull boolean;
  v_def text;
BEGIN
  -- Coluna purchase_number: BIGINT, NOT NULL.
  SELECT data_type, is_nullable
  INTO v_type, v_notnull
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'purchases'
    AND column_name = 'purchase_number';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'FAIL: coluna purchases.purchase_number ausente (upgrade.sql Parte 15 nao aplicado?)';
  END IF;
  IF v_type <> 'bigint' OR v_notnull = 'YES' THEN
    RAISE EXCEPTION 'FAIL: purchases.purchase_number deveria ser bigint NOT NULL (atual: % not_null=%)', v_type, v_notnull;
  END IF;
  -- Índice único por loja.
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'uq_purchases_store_number'
  ) THEN
    RAISE EXCEPTION 'FAIL: indice unico uq_purchases_store_number ausente';
  END IF;
  -- RPC process_purchase atualizada (atribui o número com advisory lock).
  SELECT pg_get_functiondef(oid) INTO v_def
  FROM pg_proc WHERE oid = to_regprocedure('public.process_purchase(jsonb,jsonb)');
  IF position('pg_advisory_xact_lock' IN v_def) = 0
     OR position('purchase_number' IN v_def) = 0 THEN
    RAISE EXCEPTION 'FAIL: process_purchase nao atribui purchase_number (versao antiga no ar?)';
  END IF;
  RAISE NOTICE 'PASS: purchase_number bigint NOT NULL + uq_purchases_store_number + process_purchase com advisory lock';
END $$;

\echo '== 18. purchase_number sem valores nulos (informativo) =='
SELECT count(*) AS compras, count(purchase_number) AS com_numero
FROM public.purchases;

\echo '== 19. Numeração sequencial de fiado por loja (debt_number) =='
DO $$
DECLARE
  v_type text;
  v_notnull boolean;
  v_def text;
BEGIN
  -- Coluna debt_number: BIGINT, NOT NULL.
  SELECT data_type, is_nullable
  INTO v_type, v_notnull
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'debts'
    AND column_name = 'debt_number';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'FAIL: coluna debts.debt_number ausente (upgrade.sql Parte 16 nao aplicado?)';
  END IF;
  IF v_type <> 'bigint' OR v_notnull = 'YES' THEN
    RAISE EXCEPTION 'FAIL: debts.debt_number deveria ser bigint NOT NULL (atual: % not_null=%)', v_type, v_notnull;
  END IF;
  -- Índice único por loja.
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'uq_debts_store_number'
  ) THEN
    RAISE EXCEPTION 'FAIL: indice unico uq_debts_store_number ausente';
  END IF;
  -- RPC register_debt atualizada (atribui o número com advisory lock).
  SELECT pg_get_functiondef(oid) INTO v_def
  FROM pg_proc WHERE oid = to_regprocedure('public.register_debt(jsonb)');
  IF position('pg_advisory_xact_lock' IN v_def) = 0
     OR position('debt_number' IN v_def) = 0 THEN
    RAISE EXCEPTION 'FAIL: register_debt nao atribui debt_number (versao antiga no ar?)';
  END IF;
  RAISE NOTICE 'PASS: debt_number bigint NOT NULL + uq_debts_store_number + register_debt com advisory lock';
END $$;

\echo '== 20. debt_number sem valores nulos (informativo) =='
SELECT count(*) AS dividas, count(debt_number) AS com_numero
FROM public.debts;

\echo '== 21. store_employees.is_active + RPC set_employee_active (Parte 19) =='
DO $$
DECLARE
  v_type text;
  v_oid oid;
BEGIN
  -- Coluna is_active (DEFAULT TRUE — funcionários existentes continuam ativos).
  SELECT data_type INTO v_type
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'store_employees'
    AND column_name = 'is_active';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'FAIL: coluna store_employees.is_active ausente (upgrade.sql Parte 19 nao aplicado?)';
  END IF;
  IF v_type <> 'boolean' THEN
    RAISE EXCEPTION 'FAIL: store_employees.is_active deveria ser boolean (atual: %)', v_type;
  END IF;
  -- RPC set_employee_active (dono ativa/desativa; SECURITY DEFINER).
  v_oid := to_regprocedure('public.set_employee_active(text,boolean)');
  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'FAIL: RPC set_employee_active ausente (upgrade.sql Parte 19.2 nao aplicado?)';
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = v_oid) THEN
    RAISE EXCEPTION 'FAIL: set_employee_active nao e SECURITY DEFINER';
  END IF;
  RAISE NOTICE 'PASS: store_employees.is_active + set_employee_active OK';
END $$;

\echo '== 22. CHECK de payment_method com M-Pesa/E-Mola (Partes 17-18) =='
DO $$
DECLARE
  v_sales text;
  v_purchases text;
BEGIN
  -- sales: o CHECK precisa aceitar mPesa/eMola (o app já envia mPesa por
  -- padrão — sem a migração, QUALQUER venda nova viola o constraint).
  SELECT pg_get_constraintdef(oid) INTO v_sales
  FROM pg_constraint
  WHERE conrelid = 'public.sales'::regclass
    AND conname = 'sales_payment_method_check';
  IF v_sales IS NULL OR position('mPesa' IN v_sales) = 0
     OR position('eMola' IN v_sales) = 0 THEN
    RAISE EXCEPTION 'FAIL: sales.payment_method sem mPesa/eMola no CHECK (upgrade.sql Parte 17 nao aplicado?): %', v_sales;
  END IF;
  -- purchases: mesmo enum de vendas (coluna + CHECK da Parte 18).
  SELECT pg_get_constraintdef(oid) INTO v_purchases
  FROM pg_constraint
  WHERE conrelid = 'public.purchases'::regclass
    AND conname = 'purchases_payment_method_check';
  IF v_purchases IS NULL OR position('mPesa' IN v_purchases) = 0
     OR position('eMola' IN v_purchases) = 0 THEN
    RAISE EXCEPTION 'FAIL: purchases.payment_method sem mPesa/eMola no CHECK (upgrade.sql Parte 18 nao aplicado?): %', v_purchases;
  END IF;
  RAISE NOTICE 'PASS: CHECK payment_method com mPesa/eMola em sales e purchases';
END $$;

\echo '== 23. purchases.payment_method: coluna existe (Parte 18) =='
DO $$
DECLARE
  v_type text;
BEGIN
  SELECT data_type INTO v_type
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'purchases'
    AND column_name = 'payment_method';
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'FAIL: coluna purchases.payment_method ausente (upgrade.sql Parte 18 nao aplicado?)';
  END IF;
  RAISE NOTICE 'PASS: purchases.payment_method OK';
END $$;

\echo '== 24. Realtime: store_employees publicada no supabase_realtime (Parte 20, informativo) =='
-- pg_publication_tables expõe as colunas pubname/schemaname/TABLENAME
-- (relname é de pg_class — fix Aug 8: o check usava o nome errado e
-- falhava com 'column relname does not exist' no banco ao vivo).
SELECT COALESCE(
  (SELECT string_agg(tablename, ', ')
   FROM pg_publication_tables
   WHERE pubname = 'supabase_realtime'
     AND schemaname = 'public' AND tablename = 'store_employees'),
  '(publicacao supabase_realtime ausente ou store_employees nao publicada — Realtime do bloqueio de funcionarios inativo)'
) AS realtime_store_employees;
SQL

# ── Executor: psql local ou container postgres:16 ───────────────────────
export PGCONNECT_TIMEOUT=15
if command -v psql >/dev/null 2>&1; then
  psql "$DB_URL" -X -q -v ON_ERROR_STOP=1 -1 -f "$CHECKS"
elif command -v docker >/dev/null 2>&1 && docker image inspect postgres:16 >/dev/null 2>&1; then
  echo "(sem psql local — usando docker postgres:16)"
  docker run --rm -i -e PGCONNECT_TIMEOUT=15 postgres:16 \
    psql "$DB_URL" -X -q -v ON_ERROR_STOP=1 -1 < "$CHECKS"
else
  echo "ERRO: psql não encontrado e docker postgres:16 indisponível." >&2
  exit 2
fi

STATUS=$?
echo
if [ $STATUS -eq 0 ]; then
  echo "✅ VERIFICAÇÃO CONCLUÍDA — todos os checks passaram (read-only)."
else
  echo "❌ FALHOU no check acima — objeto ausente/divergente no banco ao vivo." >&2
fi
exit $STATUS
