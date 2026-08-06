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
    'public.create_employee_account(text,text,text,text,text,text)'
  ]) AS sig
  LOOP
    IF to_regprocedure(r.sig) IS NULL THEN
      RAISE EXCEPTION 'FAIL: RPC % ausente (rodar schema.sql)', r.sig;
    END IF;
    IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = to_regprocedure(r.sig)) THEN
      RAISE EXCEPTION 'FAIL: % nao e SECURITY DEFINER', r.sig;
    END IF;
  END LOOP;
  RAISE NOTICE 'PASS: process_sale / process_purchase / register_debt / settle_debt / create_employee_account OK';
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
    'public.lock_products_or_raise(jsonb,text,uuid,boolean)',
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
