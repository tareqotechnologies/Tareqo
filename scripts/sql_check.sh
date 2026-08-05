#!/usr/bin/env bash
# ============================================================================
# Smoke test do schema do Supabase contra um PostgreSQL puro (sem Supabase).
#
# Preenche a lacuna 6.2 do PRODUCTION_CHECKLIST: os RPCs atômicos e o RLS
# são o caminho mais crítico do sistema e não têm teste automatizado. Este
# script valida:
#   1. `supabase/schema.sql` aplica SEM ERROS (com o stub de auth em
#      `sqlcheck_stub.sql` — funções auth.uid()/auth.jwt() + usuários demo);
#   2. o papel de super admin é resolvido pela TABELA `public.super_admins`
#      (auditoria C3 — nunca pelo e-mail do JWT);
#   3. o RLS isola por auth.uid() com os triggers anti-forja em ação;
#   4. os RPCs atômicos do dinheiro (process_sale / register_debt /
#      settle_debt) EXECUTAM de verdade como app_user — venda + fiado +
#      quitação com efeitos verificados no banco. Regressão da armadilha
#      de precedência `||`/`->>` (22P02): se um `'t' || (x->>'id')` voltar
#      a ser parseado como concatenação jsonb, este passo falha.
#
# ⚠️ As verificações de RLS rodam como um papel NÃO-superusuário
# (`app_user`), porque o superusuário do Postgres ignora o RLS — o mesmo
# modelo do Supabase, onde o PostgREST conecta como `authenticated`.
#
# Uso (com `psql` no PATH — já disponível nos runners do GitHub Actions):
#   PGPASSWORD=... bash scripts/sql_check.sh [PGHOST] [PGUSER] [PGDATABASE]
#   (padrões: localhost / postgres / dumbhanengue)
#
# ⚠️ DESTRUTIVO: o script recria o schema `public` do zero (banco de teste
# efêmero) — pode ser reexecutado à vontade contra o mesmo banco.
# ============================================================================
set -euo pipefail

PGHOST="${1:-localhost}"
PGUSER="${2:-postgres}"
PGDATABASE="${3:-dumbhanengue}"

export PGHOST PGUSER PGDATABASE

# IDs dos usuários demo do sqlcheck_stub.sql.
OWNER_UID="11111111-1111-1111-1111-111111111111"
ADMIN_UID="99999999-9999-9999-9999-999999999999"

# Papel não-superusuário para as verificações de RLS (espelha o papel
# `authenticated` do Supabase).
TEST_USER="app_user"
TEST_PASSWORD="app"

echo "==> [0/4] Recriando schema public (banco de teste efêmero)"
psql -v ON_ERROR_STOP=1 <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SQL

# O papel de teste persiste entre execuções (evita recriar a cada run).
psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;
ALTER ROLE app_user PASSWORD 'app';
SQL

echo "==> [1/4] Aplicando stub de auth + supabase/schema.sql"
psql -v ON_ERROR_STOP=1 -f sqlcheck_stub.sql
psql -v ON_ERROR_STOP=1 -f supabase/schema.sql

psql -v ON_ERROR_STOP=1 <<'SQL'
GRANT USAGE ON SCHEMA public, auth TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;
SQL

# psql como app_user (RLS aplicado) com a claim do JWT por sessão.
psql_app() {
  PGPASSWORD="$TEST_PASSWORD" psql -U "$TEST_USER" "$@"
}

echo "==> [2/4] Papel de super admin via tabela public.super_admins (C3)"
# -q silencia o command tag do SET; tail pega apenas a linha do resultado.
admin_is_admin="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${ADMIN_UID}\"}'; SELECT public.is_super_admin();" | tail -n 1)"
[ "$admin_is_admin" = "t" ] || {
  echo "FALHA: dono do e-mail legado deveria ter sido promovido à tabela (obtido: '$admin_is_admin')"
  exit 1
}

owner_is_admin="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT public.is_super_admin();" | tail -n 1)"
[ "$owner_is_admin" = "f" ] || {
  echo "FALHA: dono comum não deveria ser super admin (obtido: '$owner_is_admin')"
  exit 1
}

echo "==> [3/4] RLS + triggers anti-forja (escrita escopada pelo JWT)"
psql_app -v ON_ERROR_STOP=1 <<'SQL'
-- Sessão do dono: o trigger set_tenant_owner força owner_user_id =
-- auth.uid() e o enforce_store_limit exige tenant aprovado com plano
-- válido (pl1 existe no seed).
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
-- ON CONFLICT: permite reexecutar o script contra o mesmo banco.
INSERT INTO public.tenants (id, business_name, plan_id, status, approved_at)
VALUES ('tn_smoke', 'Tenant do Smoke', 'pl1', 'approved', now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stores (id, name) VALUES ('st_smoke', 'Loja Smoke')
ON CONFLICT (id) DO NOTHING;
-- store_id explícito ('st_smoke' É loja do dono — o trigger anti-forja
-- preserva; sem isso o produto cairia em st1, a primeira loja do seed).
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('smoke1', 'Produto do dono', 'st_smoke', 1.0, 2.0, 5)
ON CONFLICT (id) DO NOTHING;
SQL

owner_sees="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.products WHERE id = 'smoke1';" | tail -n 1)"
[ "$owner_sees" = "1" ] || {
  echo "FALHA: dono deveria enxergar o próprio produto (obtido: '$owner_sees')"
  exit 1
}

admin_sees="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${ADMIN_UID}\"}'; SELECT count(*) FROM public.products WHERE id = 'smoke1';" | tail -n 1)"
[ "$admin_sees" = "0" ] || {
  echo "FALHA: outro usuário não deveria enxergar o produto do dono (obtido: '$admin_sees')"
  exit 1
}

echo "==> [4/4] RPCs atômicos do dinheiro (process_sale / register_debt / settle_debt)"
# Executa o caminho do dinheiro como app_user — exatamente o que o app faz
# no Supabase. Valida efeitos: venda+item+estoque+caixa, dívida+pendência,
# quitação da MESMA pendência, idempotência e rejeição de estoque.

# --- Venda atômica (venda + item + baixa de estoque + caixa em 1 transação)
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_sale(
  ('{"id":"s_smoke","store_id":"st_smoke","total_amount":4,"payment_method":"pix","date_time":"' || now()::text || '"}')::jsonb,
  '[{"product_id":"smoke1","product_name":"Produto do dono","quantity":2,"unit_price":2}]'::jsonb
);
SQL

sale_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_smoke' AND total_amount = 4;" | tail -n 1)"
[ "$sale_ok" = "1" ] || {
  echo "FALHA: venda process_sale não registrou a venda (obtido: '$sale_ok')"
  exit 1
}

item_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sale_items WHERE sale_id = 's_smoke' AND quantity = 2;" | tail -n 1)"
[ "$item_ok" = "1" ] || {
  echo "FALHA: itens da venda não gravados (obtido: '$item_ok')"
  exit 1
}

stock_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT stock_quantity FROM public.products WHERE id = 'smoke1';" | tail -n 1)"
[ "$stock_ok" = "3" ] || {
  echo "FALHA: estoque não baixado (5-2), obtido: '$stock_ok'"
  exit 1
}

cash_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.financial_transactions WHERE id = 'ts_smoke' AND amount = 4 AND type = 'income' AND status = 'paid';" | tail -n 1)"
[ "$cash_ok" = "1" ] || {
  echo "FALHA: entrada no caixa da venda ausente/incorreta (obtido: '$cash_ok')"
  exit 1
}

# --- Fiado atômico (dívida + pendência vinculada em 1 transação)
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.register_debt(
  ('{"id":"d_smoke","store_id":"st_smoke","person_name":"Fulano","amount":10,"due_date":"' || (now() + interval '30 days')::text || '","is_customer_debt":true}')::jsonb
);
SQL

pend_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.financial_transactions WHERE id = 'td_smoke' AND amount = 10 AND type = 'income' AND status = 'pending' AND debt_id = 'd_smoke';" | tail -n 1)"
[ "$pend_ok" = "1" ] || {
  echo "FALHA: pendência vinculada do fiado ausente/incorreta (obtido: '$pend_ok')"
  exit 1
}

# --- Quitação (baixa + resolução da MESMA pendência, idempotente)
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.settle_debt('d_smoke', 'st_smoke');
SQL

debt_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT is_paid FROM public.debts WHERE id = 'd_smoke';" | tail -n 1)"
[ "$debt_ok" = "t" ] || {
  echo "FALHA: dívida não quitada (obtido: '$debt_ok')"
  exit 1
}

settled_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.financial_transactions WHERE debt_id = 'd_smoke' AND status = 'paid';" | tail -n 1)"
[ "$settled_ok" = "1" ] || {
  echo "FALHA: a MESMA pendência deveria ter virado paid (obtido: '$settled_ok')"
  exit 1
}

# --- Rejeição: estoque insuficiente (negativo) não muta nada
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.process_sale(
      ('{"id":"s_bad","store_id":"st_smoke","total_amount":99,"payment_method":"pix","date_time":"' || now()::text || '"}')::jsonb,
      '[{"product_id":"smoke1","product_name":"X","quantity":99,"unit_price":1}]'::jsonb
    );
    RAISE EXCEPTION 'SENTINELA: venda com estoque insuficiente deveria ter sido rejeitada';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: venda com estoque insuficiente deveria ter sido rejeitada' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

bad_stock="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_bad';" | tail -n 1)"
[ "$bad_stock" = "0" ] || {
  echo "FALHA: venda rejeitada não deveria existir (obtido: '$bad_stock')"
  exit 1
}

echo "OK: schema aplicado, super admin via tabela, RLS e RPCs atômicos do dinheiro conforme esperado."
