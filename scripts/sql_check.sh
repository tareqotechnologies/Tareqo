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
#   5. o RPC create_employee_account cria a conta do funcionário E o
#      vínculo na loja em UMA transação (sem e-mail — regressão do rate
#      limit 429; sem contas órfãs se o limite do plano for atingido) e
#      rejeita e-mail duplicado e não-donos;
#   6. a desativação pelo dono (RPC set_employee_active) derruba o acesso
#      do funcionário NA HORA (is_my_store exige vínculo ativo) e a
#      reativação devolve; não-dono é rejeitado;
#   7. [1c] REGRESSÃO do 42703 (bug achado no live Aug 8): o upgrade.sql
#      aplicado numa base LEGADA sem store_employees.is_active recria a
#      coluna (Parte 3.0) ANTES das funções LANGUAGE sql que a
#      referenciam — sem isso, o CREATE das funções falha com 'column
#      e.is_active does not exist'.
#   8. [16/16] REGRESSÃO do 42710 (Supabase real — bug achado no live Aug 8):
#      com a publicação supabase_realtime criada e store_employees JÁ membro,
#      o upgrade.sql reaplica 2x SEM erro (o bloco da Parte 20 confere
#      pg_publication_tables antes do ADD TABLE) e o catálogo de planos
#      (pl1/pl2/pl3 — Parte 21, seed do onboarding do dono) permanece semeado.
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

echo "==> [1/4] Aplicando stub de auth + supabase/schema.sql + upgrade.sql"
psql -v ON_ERROR_STOP=1 -f sqlcheck_stub.sql
psql -v ON_ERROR_STOP=1 -f supabase/schema.sql

# upgrade.sql (CONSOLIDADO — substitui as antigas migrações 002..011):
# aplicado 2x SEM ERROS sobre o schema novo — prova a idempotência
# (ADD COLUMN IF NOT EXISTS / CREATE UNIQUE INDEX IF NOT EXISTS /
# CREATE OR REPLACE / DROP + CREATE) e que é seguro reexecutar à vontade.
echo "==> [1b] upgrade.sql consolidado: aplicação dupla sem erro"
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql

# Regressão do 42703 (banco LEGADO, bug achado no live Aug 8): num banco
# que ainda NÃO tem a coluna store_employees.is_active (upgrade parcial,
# apenas as Partes 1-16 aplicadas), as funções LANGUAGE sql
# is_my_store/is_manager_of_store são VALIDADAS no momento do CREATE e
# falham com 'column e.is_active does not exist' se a coluna não existir.
# O upgrade.sql precisa recriar a coluna (Parte 3.0) ANTES das funções.
# Este passo simula o cenário: dropa a coluna e reaplica o upgrade.
echo "==> [1c] upgrade.sql em base LEGADA sem is_active (regressão 42703)"
psql -v ON_ERROR_STOP=1 -c "ALTER TABLE public.store_employees DROP COLUMN is_active;"
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql
legacy_active_ok="$(psql -q -tAc "SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'store_employees' AND column_name = 'is_active';" | tail -n 1)"
[ "$legacy_active_ok" = "1" ] || {
  echo "FALHA: is_active não foi recriado pela Parte 3.0 (obtido: '$legacy_active_ok')"
  exit 1
}
echo "OK: upgrade.sql recria is_active antes das funções LANGUAGE sql"

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
-- válido (pl1 existe no catálogo da Parte 2).
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
-- ON CONFLICT: permite reexecutar o script contra o mesmo banco.
INSERT INTO public.tenants (id, business_name, plan_id, status, approved_at)
VALUES ('tn_smoke', 'Tenant do Smoke', 'pl1', 'approved', now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stores (id, name) VALUES ('st_smoke', 'Loja Smoke')
ON CONFLICT (id) DO NOTHING;
-- store_id explícito ('st_smoke' É loja do dono — o trigger anti-forja
-- preserva; sem isso o produto cairia na primeira loja do usuário).
-- W11: estoque em MILÉSIMOS (5000 = 5 unidades) + lote inicial (invariante
-- `stock = Σ lotes` — a baixa FIFO do process_sale consome os lotes).
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('smoke1', 'Produto do dono', 'st_smoke', 100, 200, 5000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_smoke1', 'st_smoke', 'smoke1', now(), NULL, 5000, 5000, 100)
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

echo "==> [3b] Ajustes do tenant (moeda/idioma): RPC do dono, RLS protege status"
# O dono altera moeda/idioma do PRÓPRIO tenant via RPC update_tenant_settings
# (SECURITY DEFINER + guarda is_tenant_owner). Sem a RPC, o UPDATE direto
# caía na política tenants_update (só super admin) e retornava 0 linhas —
# o bug real dos "ajustes que não salvam".
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.update_tenant_settings('tn_smoke', 'USD', 'en');
SQL

settings_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT currency_code || '|' || language FROM public.tenants WHERE id = 'tn_smoke';" | tail -n 1)"
[ "$settings_ok" = "USD|en" ] || {
  echo "FALHA: ajustes do dono não salvos via RPC (obtido: '$settings_ok')"
  exit 1
}

# Funcionário (não-dono) NÃO altera ajustes de outro tenant (guarda da RPC).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.update_tenant_settings('tn_smoke', 'EUR', 'pt');
    RAISE EXCEPTION 'SENTINELA: não-dono deveria ter sido bloqueado nos ajustes';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: não-dono deveria ter sido bloqueado nos ajustes' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

# Direto no PostgREST (RLS): o dono NÃO consegue mexer no status — a
# política tenants_update continua restrita ao super admin.
owner_status="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; UPDATE public.tenants SET status = 'approved' WHERE id = 'tn_smoke' RETURNING id;" | tail -n 1)"
[ -z "$owner_status" ] || {
  echo "FALHA: dono não deveria alterar o status via UPDATE direto (obtido: '$owner_status')"
  exit 1
}

EMP_UID="22222222-2222-2222-2222-222222222222"

echo "==> [4/5] Funcionário: acesso por LOJA no modo SaaS (auditoria C2)"
# Bloqueador C2 da auditoria: funcionários são OUTROS usuários (não o
# dono), então o RLS antigo (auth.uid() = user_id) os deixava sem NENHUM
# dado de negócio. O fix: políticas por loja (is_my_store) nas tabelas de
# negócio + RPCs com guarda is_my_store e filtros por store_id.

# Dono cria o vínculo de funcionário na loja do smoke (pl1 permite 3).
psql_app -v ON_ERROR_STOP=1 <<SQL
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO public.store_employees
  (id, store_id, user_id, full_name, email, role)
VALUES ('e_smoke', 'st_smoke', '22222222-2222-2222-2222-222222222222',
        'Funcionária', 'funcionario@loja.com', 'employee')
ON CONFLICT (id) DO NOTHING;
-- Produto próprio da loja para a venda do funcionário (não interfere no
-- estoque do smoke1 usado pelo passo [5/5]). W11: estoque em MILÉSIMOS
-- + lote inicial (invariante `stock = Σ lotes`).
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('smoke2', 'Produto do funcionário', 'st_smoke', 100, 200, 5000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_smoke2', 'st_smoke', 'smoke2', now(), NULL, 5000, 5000, 100)
ON CONFLICT (id) DO NOTHING;
SQL

# 4.1 RLS: o funcionário ENXERGA o produto da loja dele (do dono).
emp_sees="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.products WHERE id = 'smoke1';" | tail -n 1)"
[ "$emp_sees" = "1" ] || {
  echo "FALHA: funcionário deveria enxergar o produto da própria loja (obtido: '$emp_sees')"
  exit 1
}

# 4.2 RLS: o funcionário NÃO enxerga produtos de OUTRA loja (st1 do seed).
emp_other="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.products WHERE store_id = 'st1';" | tail -n 1)"
[ "$emp_other" = "0" ] || {
  echo "FALHA: funcionário não deveria enxergar produtos de outra loja (obtido: '$emp_other')"
  exit 1
}

# 4.3 RLS: o funcionário vê a loja dele no seletor (stores_select).
emp_stores="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.stores WHERE id = 'st_smoke';" | tail -n 1)"
[ "$emp_stores" = "1" ] || {
  echo "FALHA: funcionário deveria ver a própria loja (obtido: '$emp_stores')"
  exit 1
}

# 4.4 RPC: funcionário REGISTRA venda na loja dele (produto do dono).
psql_app -v ON_ERROR_STOP=1 <<SQL
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
SELECT public.process_sale(
  ('{"id":"s_emp","store_id":"st_smoke","total_amount":400,"payment_method":"cash","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (2000 = 2 unidades).
  '[{"product_id":"smoke2","product_name":"Produto do funcionário","quantity":2000,"unit_price":200}]'::jsonb
);
SQL

emp_sale="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_emp';" | tail -n 1)"
[ "$emp_sale" = "1" ] || {
  echo "FALHA: venda do funcionário não registrada (obtido: '$emp_sale')"
  exit 1
}

# 4.5 RPC: a venda do funcionário é visível para o DONO (is_my_store).
owner_sees_emp="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_emp';" | tail -n 1)"
[ "$owner_sees_emp" = "1" ] || {
  echo "FALHA: dono deveria enxergar a venda do funcionário (obtido: '$owner_sees_emp')"
  exit 1
}

# 4.6 RPC: funcionário NÃO consegue vender numa loja de OUTRO tenant (guarda).
psql_app -v ON_ERROR_STOP=1 <<SQL
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO \$\$
BEGIN
  BEGIN
    PERFORM public.process_sale(
      ('{"id":"s_bad2","store_id":"st1","total_amount":100,"payment_method":"cash","date_time":"' || now()::text || '"}')::jsonb,
      -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
      '[{"product_id":"p1","product_name":"X","quantity":1000,"unit_price":100}]'::jsonb
    );
    RAISE EXCEPTION 'SENTINELA: venda em loja de outro tenant deveria ter sido rejeitada';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: venda em loja de outro tenant deveria ter sido rejeitada' THEN
      RAISE;
    END IF;
  END;
END \$\$;
SQL

bad2_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_bad2';" | tail -n 1)"
[ "$bad2_ok" = "0" ] || {
  echo "FALHA: venda em loja de outro tenant não deveria existir (obtido: '$bad2_ok')"
  exit 1
}

echo "==> [5/5] RPCs atômicos do dinheiro (process_sale / register_debt / settle_debt)"
# Executa o caminho do dinheiro como app_user — exatamente o que o app faz
# no Supabase. Valida efeitos: venda+item+estoque+caixa, dívida+pendência,
# quitação da MESMA pendência, idempotência e rejeição de estoque.

# --- Venda atômica (venda + item + baixa de estoque + caixa em 1 transação)
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_sale(
  ('{"id":"s_smoke","store_id":"st_smoke","total_amount":400,"payment_method":"mPesa","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (2000 = 2 unidades).
  '[{"product_id":"smoke1","product_name":"Produto do dono","quantity":2000,"unit_price":200}]'::jsonb
);
SQL

sale_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sales WHERE id = 's_smoke' AND total_amount = 400;" | tail -n 1)"
[ "$sale_ok" = "1" ] || {
  echo "FALHA: venda process_sale não registrou a venda (obtido: '$sale_ok')"
  exit 1
}

item_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sale_items WHERE sale_id = 's_smoke' AND quantity = 2000;" | tail -n 1)"
[ "$item_ok" = "1" ] || {
  echo "FALHA: itens da venda não gravados (obtido: '$item_ok')"
  exit 1
}

# W11: estoque em MILÉSIMOS (5000-2000=3000; o lote lot_smoke1 também cai
# para 3000 — a invariante stock = Σ lotes nunca quebra).
stock_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT stock_quantity FROM public.products WHERE id = 'smoke1';" | tail -n 1)"
[ "$stock_ok" = "3000" ] || {
  echo "FALHA: estoque não baixado (5000-2000), obtido: '$stock_ok'"
  exit 1
}
stock_lot_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT current_quantity FROM public.stock_lots WHERE id = 'lot_smoke1';" | tail -n 1)"
[ "$stock_lot_ok" = "3000" ] || {
  echo "FALHA: lote não baixado junto com o produto (obtido: '$stock_lot_ok')"
  exit 1
}

cash_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.financial_transactions WHERE id = 'ts_smoke' AND amount = 400 AND type = 'income' AND status = 'paid';" | tail -n 1)"
[ "$cash_ok" = "1" ] || {
  echo "FALHA: entrada no caixa da venda ausente/incorreta (obtido: '$cash_ok')"
  exit 1
}

# --- Fiado atômico (dívida + pendência vinculada em 1 transação)
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.register_debt(
  ('{"id":"d_smoke","store_id":"st_smoke","person_name":"Fulano","amount":1000,"due_date":"' || (now() + interval '30 days')::text || '","is_customer_debt":true}')::jsonb
);
SQL

pend_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.financial_transactions WHERE id = 'td_smoke' AND amount = 1000 AND type = 'income' AND status = 'pending' AND debt_id = 'd_smoke';" | tail -n 1)"
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

# Auditoria Aug 6: a quitação carimba a DATA DE REALIZAÇÃO (date = now())
# na pendência vinculada — mesma semântica do markAsPaid local (SQLite).
# Sem isso, o fluxo de caixa do período reconheceria o recebimento na data
# do REGISTRO da pendência (modo SaaS) vs. data da QUITAÇÃO (modo local).
#
# Assertiva AIRTIGHT: `date` (realização) deve ser >= `paid_at` da dívida —
# os dois são carimbados na MESMA transação do settle_debt (now() no mesmo
# instante). Sem o fix, `date` = momento do register_debt (segundos ANTES do
# paid_at) e a assertiva falha. (Uma janela `now() - interval` não bastaria:
# o teste roda em segundos e o registro também usa now().)
settled_date_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT (ft.date >= d.paid_at) FROM public.financial_transactions ft JOIN public.debts d ON d.id = 'd_smoke' WHERE ft.id = 'td_smoke';" | tail -n 1)"
[ "$settled_date_ok" = "t" ] || {
  echo "FALHA: pendência quitada deveria ter date = now() (realização) (obtido: '$settled_date_ok')"
  exit 1
}

# --- Rejeição: estoque insuficiente (negativo) não muta nada
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.process_sale(
      ('{"id":"s_bad","store_id":"st_smoke","total_amount":9900,"payment_method":"mPesa","date_time":"' || now()::text || '"}')::jsonb,
      -- W11: 99000 milésimos = 99 unidades >> estoque (3000 restantes).
      '[{"product_id":"smoke1","product_name":"X","quantity":99000,"unit_price":100}]'::jsonb
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

echo "==> [6/6] RPC create_employee_account (conta + vínculo, SEM e-mail)"
# Regressão do rate limit 429: o app não usa mais auth.signUp para criar a
# conta do funcionário (cada tentativa enviava e-mail de confirmação). A
# RPC SECURITY DEFINER cria a conta por INSERÇÃO DIRETA em auth.users +
# auth.identities com hash bcrypt (pgcrypto) — email_confirmed_at = now()
# (conta nasce confirmada, sem e-mail, sem mexer na sessão do dono) — e
# cria TAMBÉM o vínculo em store_employees NA MESMA transação: se o vínculo
# falhar (ex.: limite do plano), a conta é desfeita junto (sem órfãs).
# (O Supabase atual removeu auth.admin_create_user; a Admin API HTTP é
# assíncrona e quebraria a atomicidade.)
#
# Usamos um tenant/loja DEDICADOS (tn_emp/st_emp, plano pl_emp máx. 2
# funcionários), criados SEM JWT (superuser): os triggers anti-forja
# preservam os valores explícitos — determinístico, sem depender de qual
# tenant o seed/trigger escolheu para as lojas dos passos anteriores.

# Tenant/loja dedicados + plano com limite de 2 funcionários.
psql -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO public.plans (id, name, max_stores, max_employees, is_active)
VALUES ('pl_emp', 'Plano Emp', 1, 2, TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.tenants (id, owner_user_id, business_name, plan_id, status, approved_at)
VALUES ('tn_emp', '11111111-1111-1111-1111-111111111111', 'Tenant Emp', 'pl_emp', 'approved', now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stores (id, tenant_id, name)
VALUES ('st_emp', 'tn_emp', 'Loja Emp')
ON CONFLICT (id) DO NOTHING;
SQL

# Dono cadastra funcionário (conta + vínculo) e recebe o id do usuário.
emp_created="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT public.create_employee_account('e_emp1', 'func-smoke@loja.com', 'senha-forte', 'Funcionária Smoke', 'st_emp', 'employee');" | tail -n 1)"
[ -n "$emp_created" ] || {
  echo "FALHA: create_employee_account não devolveu o id do usuário"
  exit 1
}

# O VÍNCULO foi criado na MESMA transação (tenant herdado da loja).
link_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.store_employees WHERE id = 'e_emp1' AND user_id = '$emp_created'::uuid AND tenant_id = 'tn_emp' AND store_id = 'st_emp';" | tail -n 1)"
[ "$link_ok" = "1" ] || {
  echo "FALHA: vínculo em store_employees não criado pela RPC (obtido: '$link_ok')"
  exit 1
}

# O usuário existe em auth.users (no Supabase real: confirmado e ativo).
# A consulta roda como superusuário: app_user não tem SELECT no schema auth
# (mesmo modelo do Supabase real — o cliente autenticado nunca lê auth.users).
emp_exists="$(psql -q -tAc "SELECT count(*) FROM auth.users WHERE id = '$emp_created'::uuid AND email = 'func-smoke@loja.com';" | tail -n 1)"
[ "$emp_exists" = "1" ] || {
  echo "FALHA: usuário criado não encontrado em auth.users (obtido: '$emp_exists')"
  exit 1
}

# Idempotência: retry com o MESMO id de vínculo devolve o mesmo user_id
# (sem duplicar conta nem vínculo).
emp_retry="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT public.create_employee_account('e_emp1', 'func-smoke@loja.com', 'senha-forte', 'Funcionária Smoke', 'st_emp', 'employee');" | tail -n 1)"
[ "$emp_retry" = "$emp_created" ] || {
  echo "FALHA: retry deveria devolver o MESMO user_id (obtido: '$emp_retry' vs '$emp_created')"
  exit 1
}

# E-mail duplicado (novo id de vínculo) → mensagem amigável, sem criar
# conta nem vínculo.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.create_employee_account('e_dup', 'func-smoke@loja.com', 'outra-senha', 'Outra', 'st_emp', 'employee');
    RAISE EXCEPTION 'SENTINELA: e-mail duplicado deveria ter sido rejeitado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: e-mail duplicado deveria ter sido rejeitado' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

# Não-dono (funcionário sem tenant próprio) é rejeitado.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.create_employee_account('e_outro', 'outro@loja.com', 'senha-forte', 'Outro', 'st_emp', 'employee');
    RAISE EXCEPTION 'SENTINELA: não-dono deveria ter sido rejeitado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: não-dono deveria ter sido rejeitado' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

# Limite do plano (pl_emp = 2): e_emp1 já existe, e_emp2 cabe (2º) e
# e_emp3 estoura — a conta criada na MESMA transação é desfeita junto
# (NENHUMA conta órfã).
emp_2="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT public.create_employee_account('e_emp2', 'func-2@loja.com', 'senha-forte', 'Segunda', 'st_emp', 'employee');" | tail -n 1)"
[ -n "$emp_2" ] || {
  echo "FALHA: 2º funcionário deveria caber no plano (obtido vazio)"
  exit 1
}

psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.create_employee_account('e_emp3', 'func-limit@loja.com', 'senha-forte', 'Terceiro', 'st_emp', 'employee');
    RAISE EXCEPTION 'SENTINELA: limite de funcionários deveria ter sido atingido';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: limite de funcionários deveria ter sido atingido' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

# A conta do 3º NÃO existe (transação desfeita — sem conta órfã).
orphan_ok="$(psql -q -tAc "SELECT count(*) FROM auth.users WHERE email = 'func-limit@loja.com';" | tail -n 1)"
[ "$orphan_ok" = "0" ] || {
  echo "FALHA: conta órfã criada mesmo com o limite do plano atingido (obtido: '$orphan_ok')"
  exit 1
}

echo "==> [6b] Ativação/desativação de funcionário (set_employee_active)"
# O dono ativa/desativa; o funcionário DESATIVADO perde o acesso NA HORA:
# is_my_store (helper de TODAS as RLS e guardas de RPC) passa a exigir
# vínculo ATIVO — a venda/leitura dele é negada mesmo com um cliente
# modificado chamando o PostgREST direto. Não-dono é rejeitado.

# Antes: o funcionário recém-criado tem acesso à loja (is_my_store TRUE).
emp_before="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${emp_created}\"}'; SELECT public.is_my_store('st_emp');" | tail -n 1)"
[ "$emp_before" = "t" ] || {
  echo "FALHA: funcionário ativo deveria ter acesso à loja (obtido: '$emp_before')"
  exit 1
}

# O DONO desativa o funcionário.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.set_employee_active('e_emp1', FALSE);
SQL

desactive_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT is_active FROM public.store_employees WHERE id = 'e_emp1';" | tail -n 1)"
[ "$desactive_ok" = "f" ] || {
  echo "FALHA: is_active deveria ser FALSE após a desativação (obtido: '$desactive_ok')"
  exit 1
}

# Depois: o funcionário DESATIVADO não tem mais acesso à loja.
emp_after="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${emp_created}\"}'; SELECT public.is_my_store('st_emp');" | tail -n 1)"
[ "$emp_after" = "f" ] || {
  echo "FALHA: funcionário desativado deveria ter perdido o acesso (obtido: '$emp_after')"
  exit 1
}

# Reativação devolve o acesso (idempotente — pode reexecutar).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.set_employee_active('e_emp1', TRUE);
SQL
emp_react="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${emp_created}\"}'; SELECT public.is_my_store('st_emp');" | tail -n 1)"
[ "$emp_react" = "t" ] || {
  echo "FALHA: reativação deveria devolver o acesso (obtido: '$emp_react')"
  exit 1
}

# Não-dono (funcionário de outro tenant) é rejeitado.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.set_employee_active('e_emp1', FALSE);
    RAISE EXCEPTION 'SENTINELA: não-dono deveria ter sido rejeitado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: não-dono deveria ter sido rejeitado' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

echo "==> [7/7] RLS sem recursão em VARREDURA COMPLETA (regressão 54001)"
# Regressão Aug 6: num Supabase com schema antigo, SELECTs sem WHERE (como
# as listagens do app: `select=*` + limit) rebentavam com 54001
# max_stack_depth em TODAS as tabelas de negócio — as políticas de
# stores/tenants/store_employees chamam is_my_store/is_tenant_owner, que
# consultam essas MESMAS tabelas (ciclo entre tabelas). Com SECURITY
# DEFINER nos helpers, o RLS interno é ignorado e a recursão vira
# impossível. Estes SELECTs SEM WHERE replicam exatamente o formato das
# consultas do app/PostgREST.

# Dono: varredura completa em todas as tabelas principais (sem erro).
full_owner_products="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.products;" | tail -n 1)"
[ "$full_owner_products" -ge 1 ] 2>/dev/null || {
  echo "FALHA: varredura completa do dono em products falhou/recursiva (obtido: '$full_owner_products')"
  exit 1
}
full_owner_stores="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.stores;" | tail -n 1)"
[ "$full_owner_stores" -ge 1 ] 2>/dev/null || {
  echo "FALHA: varredura completa do dono em stores falhou/recursiva (obtido: '$full_owner_stores')"
  exit 1
}
full_owner_emps="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.store_employees;" | tail -n 1)"
[ "$full_owner_emps" -ge 1 ] 2>/dev/null || {
  echo "FALHA: varredura completa do dono em store_employees falhou/recursiva (obtido: '$full_owner_emps')"
  exit 1
}
full_owner_tenants="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.tenants;" | tail -n 1)"
[ "$full_owner_tenants" -ge 1 ] 2>/dev/null || {
  echo "FALHA: varredura completa do dono em tenants falhou/recursiva (obtido: '$full_owner_tenants')"
  exit 1
}
full_owner_sales="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.sales;" | tail -n 1)"
[ "$full_owner_sales" -ge 1 ] 2>/dev/null || {
  echo "FALHA: varredura completa do dono em sales falhou/recursiva (obtido: '$full_owner_sales')"
  exit 1
}

# Funcionário: varredura completa vê SÓ a loja dele (smoke1 + smoke2) —
# RLS por loja ativo também sem WHERE.
full_emp_products="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.products;" | tail -n 1)"
[ "$full_emp_products" = "2" ] || {
  echo "FALHA: funcionário deveria ver exatamente 2 produtos (loja st_smoke) na varredura completa (obtido: '$full_emp_products')"
  exit 1
}

# Anon (sem JWT): varredura completa devolve VAZIO, sem erro.
full_anon_products="$(psql_app -q -tAc "SELECT count(*) FROM public.products;" | tail -n 1)"
[ "$full_anon_products" = "0" ] || {
  echo "FALHA: anon deveria ver 0 produtos (obtido: '$full_anon_products')"
  exit 1
}

MGR_UID="33333333-3333-3333-3333-333333333333"

echo "==> [8/8] Níveis de acesso: compras exigem DONO ou GERENTE (matriz de acesso)"
# Matriz de acesso (Aug 6): DONO = tudo; GERENTE = operação completa
# (inclui compras/relatórios); FUNCIONÁRIO = só operação diária (SEM
# compras, SEM relatórios, SEM gestão). O servidor é a autoridade: o
# helper is_manager_of_store + a guarda do process_purchase + o RLS de
# purchases/purchase_items negam compras de funcionários mesmo que um
# cliente modificado chame o PostgREST direto.

# Dono cria o vínculo do GERENTE na loja do smoke (cargo 'manager').
psql_app -v ON_ERROR_STOP=1 <<SQL
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO public.store_employees
  (id, store_id, user_id, full_name, email, role)
VALUES ('e_mgr_smoke', 'st_smoke', '${MGR_UID}',
        'Gerente Smoke', 'gerente@loja.com', 'manager')
ON CONFLICT (id) DO NOTHING;
SQL

# 8.1 Helper is_manager_of_store: gerente = t, funcionário = f, dono = t.
mgr_is_mgr="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${MGR_UID}\"}'; SELECT public.is_manager_of_store('st_smoke');" | tail -n 1)"
[ "$mgr_is_mgr" = "t" ] || {
  echo "FALHA: gerente deveria ser is_manager_of_store (obtido: '$mgr_is_mgr')"
  exit 1
}
emp_is_mgr="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT public.is_manager_of_store('st_smoke');" | tail -n 1)"
[ "$emp_is_mgr" = "f" ] || {
  echo "FALHA: funcionário NÃO deveria ser is_manager_of_store (obtido: '$emp_is_mgr')"
  exit 1
}
owner_is_mgr="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT public.is_manager_of_store('st_smoke');" | tail -n 1)"
[ "$owner_is_mgr" = "t" ] || {
  echo "FALHA: dono deveria ser is_manager_of_store (obtido: '$owner_is_mgr')"
  exit 1
}

# 8.2 RPC: FUNCIONÁRIO não registra compra (guarda is_manager_of_store).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM public.process_purchase(
      ('{"id":"p_emp","store_id":"st_smoke","supplier_name":"Fornecedor","total_amount":200,"date_time":"' || now()::text || '"}')::jsonb,
      -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
      '[{"product_id":"smoke2","product_name":"Produto do funcionário","quantity":1000,"unit_price":200}]'::jsonb
    );
    RAISE EXCEPTION 'SENTINELA: funcionário deveria ter sido bloqueado ao registrar compra';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: funcionário deveria ter sido bloqueado ao registrar compra' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

p_emp_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.purchases WHERE id = 'p_emp';" | tail -n 1)"
[ "$p_emp_ok" = "0" ] || {
  echo "FALHA: compra de funcionário não deveria existir (obtido: '$p_emp_ok')"
  exit 1
}

# 8.3 RLS: funcionário NÃO lê compras (SELECT = 0, mesmo na loja dele).
emp_read_purch="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.purchases;" | tail -n 1)"
[ "$emp_read_purch" = "0" ] || {
  echo "FALHA: funcionário não deveria ler compras (obtido: '$emp_read_purch')"
  exit 1
}

# 8.4 RPC: GERENTE registra compra na loja (efeitos completos).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "33333333-3333-3333-3333-333333333333"}';
SELECT public.process_purchase(      ('{"id":"p_mgr","store_id":"st_smoke","supplier_name":"Fornecedor","total_amount":200,"payment_method":"mPesa","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade) — cria lote novo.
  '[{"product_id":"smoke2","product_name":"Produto do funcionário","quantity":1000,"unit_price":200}]'::jsonb
);
SQL

mgr_purch_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.purchases WHERE id = 'p_mgr' AND supplier_name = 'Fornecedor' AND payment_method = 'mPesa';" | tail -n 1)"
[ "$mgr_purch_ok" = "1" ] || {
  echo "FALHA: compra do gerente não registrada com forma de pagamento mPesa (obtido: '$mgr_purch_ok')"
  exit 1
}
mgr_stock_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT stock_quantity FROM public.products WHERE id = 'smoke2';" | tail -n 1)"
# W11 (milésimos): smoke2 = 5000 (passo 4) - 2000 (venda do funcionário,
# passo 4.4) + 1000 (compra do gerente, passo 8.4) = 4000. A compra cria
# um lote novo (id 'lot-p_mgr-smoke2' — deriva da compra+produto): a
# invariante stock = Σ lotes vale (3000 restantes do lote original + 1000
# do lote novo = 4000). Acoplado à ordem dos passos: se reordenar,
# recalcular a derivação.
[ "$mgr_stock_ok" = "4000" ] || {
  echo "FALHA: estoque não atualizado pela compra do gerente (5000-2000+1000=4000, obtido: '$mgr_stock_ok')"
  exit 1
}
mgr_lots_ok="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT COALESCE(SUM(current_quantity), 0) FROM public.stock_lots WHERE product_id = 'smoke2' AND store_id = 'st_smoke';" | tail -n 1)"
[ "$mgr_lots_ok" = "4000" ] || {
  echo "FALHA: invariante stock = Σ lotes quebrada após a compra do gerente (obtido: '$mgr_lots_ok')"
  exit 1
}

# 8.5 RLS: gerente LÊ compras (SELECT > 0); dono também.
mgr_read_purch="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${MGR_UID}\"}'; SELECT count(*) FROM public.purchases WHERE id = 'p_mgr';" | tail -n 1)"
[ "$mgr_read_purch" = "1" ] || {
  echo "FALHA: gerente deveria ler a própria compra (obtido: '$mgr_read_purch')"
  exit 1
}
owner_read_purch="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.purchases WHERE id = 'p_mgr';" | tail -n 1)"
[ "$owner_read_purch" = "1" ] || {
  echo "FALHA: dono deveria ler a compra do gerente (obtido: '$owner_read_purch')"
  exit 1
}

echo "==> [9/9] Audit log: escrita por trigger, leitura só super admin (W9)"
# A tabela audit_log NÃO tem políticas RLS: nenhum papel a lê direto.
audit_owner_direct="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM public.audit_log;" | tail -n 1)"
[ "$audit_owner_direct" = "0" ] || {
  echo "FALHA: sem política RLS, o dono não deveria ver audit_log (obtido: '$audit_owner_direct')"
  exit 1
}

# O super admin decide um tenant (UPDATE de status) → o trigger grava.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "99999999-9999-9999-9999-999999999999"}';
UPDATE public.tenants SET status = status WHERE id = 'tn_smoke';
SQL

# RPC get_audit_log: só o super admin lê (>= 1 registo tenant_decision).
audit_admin="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${ADMIN_UID}\"}'; SELECT count(*) FROM public.get_audit_log(10) WHERE action = 'tenant_decision';" | tail -n 1)"
if ! [ "$audit_admin" -ge 1 ] 2>/dev/null; then
  echo "FALHA: super admin deveria ler o registo de auditoria (obtido: '$audit_admin')"
  exit 1
fi

# O dono NÃO lê: a RPC recusa (exceção capturada pelo DO — sentinela).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
DO $$
BEGIN
  BEGIN
    PERFORM count(*) FROM public.get_audit_log(10);
    RAISE EXCEPTION 'SENTINELA: dono deveria ser bloqueado ao ler o audit log';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: dono deveria ser bloqueado ao ler o audit log' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

echo "==> [10/10] KPIs agregadas no servidor (get_dashboard_kpis, W5)"
# Baseline das KPIs da loja do smoke ANTES de inserir os dados de teste
# (a loja já tem dados dos passos anteriores — calculamos o delta).
kpi_base="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT total_sales::text || '|' || cash_income::text || '|' || cash_expense::text || '|' || pending_total::text || '|' || stock_total::text FROM public.get_dashboard_kpis('st_smoke', now() - interval '1 day', now() + interval '1 day');" | tail -n 1)"

# Dono insere dados com totais conhecidos na loja dele (st_smoke).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('p_kpi', 'Produto KPI', 'st_smoke', 100, 200, 5000)
ON CONFLICT (id) DO NOTHING;
-- W11: lote inicial (invariante stock = Σ lotes; estoque em milésimos).
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_p_kpi', 'st_smoke', 'p_kpi', now(), NULL, 5000, 5000, 100)
ON CONFLICT (id) DO NOTHING;  -- A venda direta (fora da RPC) também precisa do sale_number NOT NULL —
  -- numeração é do servidor; aqui calcula o próximo da loja.
  INSERT INTO public.sales (id, store_id, sale_number, total_amount, payment_method, date_time)
  SELECT 's_kpi', 'st_smoke',
         (SELECT COALESCE(MAX(sale_number), 0) + 1 FROM public.sales
          WHERE store_id = 'st_smoke'),
         2550, 'cash', now() - interval '1 hour'
  ON CONFLICT (id) DO NOTHING;
INSERT INTO public.financial_transactions
  (id, store_id, description, amount, type, category, date, status)
VALUES
  ('t_kpi_inc',  'st_smoke', 'Entrada KPI',  10000, 'income',  'sales',    now(), 'paid'),
  ('t_kpi_exp',  'st_smoke', 'Saída KPI',     4000, 'expense', 'purchase', now(), 'paid'),
  ('t_kpi_pend', 'st_smoke', 'Pendente KPI',  2000, 'expense', 'purchase', now(), 'pending')
ON CONFLICT (id) DO NOTHING;
-- A numeração aqui é direta (fora da RPC) — MAX atual + ROW_NUMBER para
-- não violar o índice único uq_debts_store_number (todas as 3 na mesma
-- transação recebem números distintos, consecutivos).
INSERT INTO public.debts
  (id, store_id, debt_number, person_name, amount, due_date, is_customer_debt, is_paid)
SELECT id, store_id,
       COALESCE(mx.max_num, 0) + ROW_NUMBER() OVER (ORDER BY id) AS debt_number,
       person_name, amount, due_date, is_customer_debt, is_paid
FROM (VALUES
  ('d_kpi_1', 'st_smoke', 'Cliente KPI',    1500, now() + interval '5 days', TRUE,  FALSE),
  ('d_kpi_2', 'st_smoke', 'Quitada KPI',     500, now() - interval '2 days', TRUE,  TRUE),
  ('d_kpi_3', 'st_smoke', 'Fornecedor KPI',  800, now() + interval '3 days', FALSE, FALSE)
) AS v(id, store_id, person_name, amount, due_date, is_customer_debt, is_paid)
CROSS JOIN LATERAL (
  SELECT COALESCE(MAX(debt_number), 0) AS max_num FROM public.debts
) mx
ON CONFLICT (id) DO NOTHING;
SQL

# Delta esperado: venda +2550 | entradas +10000 | saídas +4000 (a
# pendente NÃO sai) | a receber +1500 (quitada/fornecedor fora) | stock
# +5000 (W11: p_kpi com 5000 milésimos = 5 unidades).
kpi_after="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT total_sales::text || '|' || cash_income::text || '|' || cash_expense::text || '|' || pending_total::text || '|' || stock_total::text FROM public.get_dashboard_kpis('st_smoke', now() - interval '1 day', now() + interval '1 day');" | tail -n 1)"

# Soma o delta ao baseline e compara com o after (awk puro, sem bc).
kpi_ok="$(awk -v base="$kpi_base" -v after="$kpi_after" 'BEGIN {
  split(base, b, "|"); split(after, a, "|");
  ok = (a[1] == b[1] + 2550) && (a[2] == b[2] + 10000) &&
       (a[3] == b[3] + 4000) && (a[4] == b[4] + 1500) && (a[5] == b[5] + 5000);
  print ok ? "1" : "0";
}')"
[ "$kpi_ok" = "1" ] || {
  echo "FALHA: KPIs do dono inesperadas (base='$kpi_base' after='$kpi_after')"
  exit 1
}

# Funcionário da própria loja (st_smoke) lê sem exceção (is_my_store OK).
kpi_emp="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.get_dashboard_kpis('st_smoke', now() - interval '1 day', now() + interval '1 day');" | tail -n 1)"
[ "$kpi_emp" = "1" ] || {
  echo "FALHA: funcionário deveria ler KPIs da própria loja (obtido: '$kpi_emp')"
  exit 1
}

# Funcionário NÃO lê KPIs de OUTRA loja (is_my_store falso — sentinela).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM * FROM public.get_dashboard_kpis('st_smoke' || 'x', now() - interval '1 day', now() + interval '1 day');
    RAISE EXCEPTION 'SENTINELA: funcionário deveria ser bloqueado nas KPIs de outra loja';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: funcionário deveria ser bloqueado nas KPIs de outra loja' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

echo "==> [11/11] H2: cash flow + relatório de vendas agregados no servidor"
# W4/H2: as novas RPCs agregam no Postgres em CENTAVOS inteiros (BIGINT).
# Usa os MESMOS dados da loja do smoke criados nos passos anteriores:
#   vendas s_smoke (400) + s_emp (400) + s_kpi (2550) no período de 1 dia;
#   caixa: s_smoke/s_emp/s_kpi geram entradas paid (400+400+2550);
#   KPI: t_kpi_inc 10000 (paid) e t_kpi_exp 4000 (paid) no mesmo período.

# --- get_cash_flow: entradas/saídas PAID do período (dono).
# A loja st_smoke acumulou ao longo dos passos anteriores, todos PAID no
# período de 1 dia. Entradas de CAIXA vêm das transações geradas pelos
# RPCs (process_sale cria 't' || id da venda) + a KPI t_kpi_inc + a
# quitação do fiado td_smoke:
#   entradas: ts_smoke 400 + ts_emp 400 + t_kpi_inc 10000 + quitação
#             td_smoke 1000 = 11800 (mínimo conhecido). A venda s_kpi foi
#             inserida DIRETO no passo [10/10] (não via process_sale) —
#             conta no faturamento do relatório, mas NÃO gera entrada de
#             caixa (fiel ao comportamento do get_cash_flow);
#   saídas:   t_kpi_exp 4000 + compra do gerente p_mgr 200 = 4200.
# A pendente t_kpi_pend (2000) NÃO entra. Usa >= (mínimo) para não
# acoplar à ordem exata dos passos anteriores.
cf="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT income_cents::text || '|' || expense_cents::text FROM public.get_cash_flow('st_smoke', now() - interval '1 day', now() + interval '1 day');" | tail -n 1)"
cf_ok="$(awk -v cf="$cf" 'BEGIN {
  split(cf, a, "|");
  ok = (a[1] >= 11800) && (a[2] >= 4200);
  print ok ? "1" : "0";
}')"
[ "$cf_ok" = "1" ] || {
  echo "FALHA: get_cash_flow do dono inesperado (obtido: '$cf')"
  exit 1
}

# --- get_sales_report: faturamento/lucro/mais vendidos/diário (dono).
sr="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT jsonb_pretty(public.get_sales_report('st_smoke', now() - interval '1 day', now() + interval '1 day'));" | tail -n 1)"
[ -n "$sr" ] || {
  echo "FALHA: get_sales_report não devolveu JSON (obtido: '$sr')"
  exit 1
}
sr_rev="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT (public.get_sales_report('st_smoke', now() - interval '1 day', now() + interval '1 day') ->> 'total_revenue_cents')::bigint;" | tail -n 1)"
# Faturamento >= s_smoke (400) + s_emp (400) + s_kpi (2550).
[ "$sr_rev" -ge 3350 ] 2>/dev/null || {
  echo "FALHA: faturamento do relatório inesperado (obtido: '$sr_rev')"
  exit 1
}
sr_best="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT jsonb_array_length(public.get_sales_report('st_smoke', now() - interval '1 day', now() + interval '1 day') -> 'best_sellers');" | tail -n 1)"
[ "$sr_best" -ge 1 ] 2>/dev/null || {
  echo "FALHA: relatório sem mais vendidos (obtido: '$sr_best')"
  exit 1
}

# Funcionário da própria loja lê as RPCs sem exceção (is_my_store).
cf_emp="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${EMP_UID}\"}'; SELECT count(*) FROM public.get_cash_flow('st_smoke', now() - interval '1 day', now() + interval '1 day');" | tail -n 1)"
[ "$cf_emp" = "1" ] || {
  echo "FALHA: funcionário deveria ler cash flow da própria loja (obtido: '$cf_emp')"
  exit 1
}

# Funcionário NÃO lê de OUTRA loja (is_my_store falso — sentinela).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "22222222-2222-2222-2222-222222222222"}';
DO $$
BEGIN
  BEGIN
    PERFORM * FROM public.get_cash_flow('st_smoke' || 'x', now() - interval '1 day', now() + interval '1 day');
    RAISE EXCEPTION 'SENTINELA: funcionário deveria ser bloqueado no cash flow de outra loja';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'SENTINELA: funcionário deveria ser bloqueado no cash flow de outra loja' THEN
      RAISE;
    END IF;
  END;
END $$;
SQL

echo "==> [12/12] W4: upgrade.sql migra NUMERIC → centavos em base legada"
# Simula uma base PRÉ-W4 (estado real do projeto de produção): reverte
# TODAS as colunas de dinheiro para NUMERIC(12,2) e insere um produto com
# valor em REAIS (fração). Reaplicar o upgrade.sql deve migrar ×100
# (25.50 → 2550 centavos) e recriar as RPCs — e reaplicar de novo NÃO
# pode multiplicar de novo (guarda central da Parte 7).
psql -v ON_ERROR_STOP=1 <<'SQL'
ALTER TABLE public.products
  ALTER COLUMN purchase_price TYPE NUMERIC(12,2),
  ALTER COLUMN sale_price     TYPE NUMERIC(12,2);
ALTER TABLE public.sales              ALTER COLUMN total_amount TYPE NUMERIC(12,2);
ALTER TABLE public.sale_items         ALTER COLUMN unit_price   TYPE NUMERIC(12,2);
ALTER TABLE public.financial_transactions ALTER COLUMN amount   TYPE NUMERIC(12,2);
ALTER TABLE public.debts              ALTER COLUMN amount       TYPE NUMERIC(12,2);
ALTER TABLE public.purchases          ALTER COLUMN total_amount TYPE NUMERIC(12,2);
ALTER TABLE public.purchase_items     ALTER COLUMN unit_price   TYPE NUMERIC(12,2);
ALTER TABLE public.plans              ALTER COLUMN price_monthly TYPE NUMERIC(12,2);
-- user_id explícito: sem sessão (superuser do SQL Editor/CI) o trigger
-- anti-forja preserva o valor informado, e products.user_id é NOT NULL.
INSERT INTO public.products (id, user_id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('legacy1', '11111111-1111-1111-1111-111111111111', 'Produto legado', 'st_smoke', 25.50, 39.90, 1)
ON CONFLICT (id) DO NOTHING;
SQL

psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql

legacy_type="$(psql -q -tAc "SELECT data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'purchase_price';" | tail -n 1)"
[ "$legacy_type" = "bigint" ] || {
  echo "FALHA: purchase_price não migrou para bigint (obtido: '$legacy_type')"
  exit 1
}
legacy_buy="$(psql -q -tAc "SELECT purchase_price FROM public.products WHERE id = 'legacy1';" | tail -n 1)"
[ "$legacy_buy" = "2550" ] || {
  echo "FALHA: 25.50 deveria virar 2550 centavos (obtido: '$legacy_buy')"
  exit 1
}
legacy_sell="$(psql -q -tAc "SELECT sale_price FROM public.products WHERE id = 'legacy1';" | tail -n 1)"
[ "$legacy_sell" = "3990" ] || {
  echo "FALHA: 39.90 deveria virar 3990 centavos (obtido: '$legacy_sell')"
  exit 1
}

# Idempotência da migração: reaplicar NÃO multiplica de novo.
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql
legacy_buy2="$(psql -q -tAc "SELECT purchase_price FROM public.products WHERE id = 'legacy1';" | tail -n 1)"
[ "$legacy_buy2" = "2550" ] || {
  echo "FALHA: guarda da Parte 7 não impediu dupla migração (obtido: '$legacy_buy2')"
  exit 1
}

echo "==> [13/13] Numeração SEQUENCIAL de venda por loja (sale_number)"
# O process_sale atribui S-00001, S-00002... dentro da loja (advisory lock
# por loja + MAX+1 na mesma transação). Valida: números consecutivos na
# mesma loja; loja diferente recomeça em 1; retry idempotente NÃO consome
# número.

# Produto dedicado para os testes de numeração (não interfere nas
# assertivas anteriores de estoque do smoke1/smoke2).
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('smoke3', 'Produto numeração', 'st_smoke', 50, 100, 10000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_smoke3', 'st_smoke', 'smoke3', now(), NULL, 10000, 10000, 50)
ON CONFLICT (id) DO NOTHING;
-- Produto na loja dedicada st_emp (não tem vendas — a primeira deve ser 1).
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('emp_p1', 'Produto da loja emp', 'st_emp', 50, 100, 5000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_emp_p1', 'st_emp', 'emp_p1', now(), NULL, 5000, 5000, 50)
ON CONFLICT (id) DO NOTHING;
SQL

# Duas vendas consecutivas na MESMA loja → números consecutivos.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_sale(
  ('{"id":"s_num1","store_id":"st_smoke","total_amount":100,"payment_method":"mPesa","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke3","product_name":"Produto numeração","quantity":1000,"unit_price":100}]'::jsonb
);
SELECT public.process_sale(
  ('{"id":"s_num2","store_id":"st_smoke","total_amount":100,"payment_method":"mPesa","date_time":"' || (now() + interval '1 minute')::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke3","product_name":"Produto numeração","quantity":1000,"unit_price":100}]'::jsonb
);
SQL

num1="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT sale_number FROM public.sales WHERE id = 's_num1';" | tail -n 1)"
num2="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT sale_number FROM public.sales WHERE id = 's_num2';" | tail -n 1)"
[ "$num2" = "$((num1 + 1))" ] || {
  echo "FALHA: vendas da MESMA loja deveriam ter números consecutivos (obtido: $num1, $num2)"
  exit 1
}

# Loja SEM vendas anteriores (st_emp) começa em 1 — numeração é POR LOJA.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_sale(
  ('{"id":"s_emp_num","store_id":"st_emp","total_amount":100,"payment_method":"cash","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"emp_p1","product_name":"Produto da loja emp","quantity":1000,"unit_price":100}]'::jsonb
);
SQL
emp_num="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT sale_number FROM public.sales WHERE id = 's_emp_num';" | tail -n 1)"
[ "$emp_num" = "1" ] || {
  echo "FALHA: primeira venda da loja st_emp deveria ter número 1 (obtido: '$emp_num')"
  exit 1
}

# Retry idempotente (mesmo id) NÃO consome número nem altera o existente.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_sale(
  ('{"id":"s_num1","store_id":"st_smoke","total_amount":100,"payment_method":"mPesa","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke3","product_name":"Produto numeração","quantity":1000,"unit_price":100}]'::jsonb
);
SQL
num1_retry="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT sale_number FROM public.sales WHERE id = 's_num1';" | tail -n 1)"
[ "$num1_retry" = "$num1" ] || {
  echo "FALHA: retry idempotente não deveria consumir/alterar número (obtido: $num1 -> $num1_retry)"
  exit 1
}

# Unicidade por loja: nenhum (store_id, sale_number) duplicado na loja testada.
num_dupes="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM (SELECT store_id, sale_number FROM public.sales WHERE store_id = 'st_smoke' GROUP BY 1, 2 HAVING count(*) > 1) dup;" | tail -n 1)"
[ "$num_dupes" = "0" ] || {
  echo "FALHA: números duplicados na loja (obtido: '$num_dupes' duplicados)"
  exit 1
}

echo "==> [14/15] Numeração SEQUENCIAL de compra por loja (purchase_number)"
# O process_purchase atribui C-00001, C-00002... dentro da loja (advisory
# lock por loja + MAX+1 na mesma transação). Valida: números consecutivos
# na mesma loja; loja diferente recomeça em 1; retry idempotente NÃO
# consome número.

# Produto dedicado para os testes de numeração de compra.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('smoke4', 'Produto compras', 'st_smoke', 50, 100, 10000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_smoke4', 'st_smoke', 'smoke4', now(), NULL, 10000, 10000, 50)
ON CONFLICT (id) DO NOTHING;
-- Produto na loja dedicada st_emp (não tem compras — a primeira deve ser 1).
INSERT INTO public.products (id, name, store_id, purchase_price, sale_price, stock_quantity)
VALUES ('emp_p2', 'Produto compras emp', 'st_emp', 50, 100, 5000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.stock_lots
  (id, store_id, product_id, entry_date, expiry_date, initial_quantity,
   current_quantity, cost_price)
VALUES ('lot_emp_p2', 'st_emp', 'emp_p2', now(), NULL, 5000, 5000, 50)
ON CONFLICT (id) DO NOTHING;
SQL

# Duas compras consecutivas na MESMA loja → números consecutivos.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_purchase(
  ('{"id":"pc_num1","store_id":"st_smoke","supplier_name":"Fornecedor A","total_amount":100,"payment_method":"eMola","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke4","product_name":"Produto compras","quantity":1000,"unit_price":100}]'::jsonb
);
SELECT public.process_purchase(
  ('{"id":"pc_num2","store_id":"st_smoke","supplier_name":"Fornecedor B","total_amount":100,"date_time":"' || (now() + interval '1 minute')::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke4","product_name":"Produto compras","quantity":1000,"unit_price":100}]'::jsonb
);
SQL

pc_num1="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT purchase_number FROM public.purchases WHERE id = 'pc_num1';" | tail -n 1)"
pc_num2="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT purchase_number FROM public.purchases WHERE id = 'pc_num2';" | tail -n 1)"
[ "$pc_num2" = "$((pc_num1 + 1))" ] || {
  echo "FALHA: compras da MESMA loja deveriam ter números consecutivos (obtido: $pc_num1, $pc_num2)"
  exit 1
}

# A forma de pagamento (eMola) enviada no payload foi persistida.
pc_num1_method="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT payment_method FROM public.purchases WHERE id = 'pc_num1';" | tail -n 1)"
[ "$pc_num1_method" = "eMola" ] || {
  echo "FALHA: forma de pagamento da compra não persistida (obtido: '$pc_num1_method')"
  exit 1
}

# Loja SEM compras anteriores (st_emp) começa em 1 — numeração é POR LOJA.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_purchase(
  ('{"id":"pc_emp_num","store_id":"st_emp","supplier_name":"Fornecedor C","total_amount":100,"date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"emp_p2","product_name":"Produto compras emp","quantity":1000,"unit_price":100}]'::jsonb
);
SQL
pc_emp_num="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT purchase_number FROM public.purchases WHERE id = 'pc_emp_num';" | tail -n 1)"
[ "$pc_emp_num" = "1" ] || {
  echo "FALHA: primeira compra da loja st_emp deveria ter número 1 (obtido: '$pc_emp_num')"
  exit 1
}

# Retry idempotente (mesmo id) NÃO consome número nem altera o existente.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.process_purchase(
  ('{"id":"pc_num1","store_id":"st_smoke","supplier_name":"Fornecedor A","total_amount":100,"payment_method":"eMola","date_time":"' || now()::text || '"}')::jsonb,
  -- W11: quantidade em MILÉSIMOS (1000 = 1 unidade).
  '[{"product_id":"smoke4","product_name":"Produto compras","quantity":1000,"unit_price":100}]'::jsonb
);
SQL
pc_num1_retry="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT purchase_number FROM public.purchases WHERE id = 'pc_num1';" | tail -n 1)"
[ "$pc_num1_retry" = "$pc_num1" ] || {
  echo "FALHA: retry idempotente não deveria consumir/alterar número (obtido: $pc_num1 -> $pc_num1_retry)"
  exit 1
}

# Unicidade por loja: nenhum (store_id, purchase_number) duplicado.
pc_dupes="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM (SELECT store_id, purchase_number FROM public.purchases WHERE store_id = 'st_smoke' GROUP BY 1, 2 HAVING count(*) > 1) dup;" | tail -n 1)"
[ "$pc_dupes" = "0" ] || {
  echo "FALHA: números duplicados na loja (obtido: '$pc_dupes' duplicados)"
  exit 1
}

echo "==> [15/15] Numeração SEQUENCIAL de fiado por loja (debt_number)"
# O register_debt atribui D-00001, D-00002... dentro da loja (advisory
# lock por loja + MAX+1 na mesma transação). Valida: números consecutivos
# na mesma loja; loja diferente recomeça em 1; retry idempotente NÃO
# consome número.

# Duas dívidas consecutivas na MESMA loja → números consecutivos.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.register_debt(
  ('{"id":"d_num1","store_id":"st_smoke","person_name":"Cliente A","amount":100,"due_date":"' || (now() + interval '5 days')::text || '","is_customer_debt":true}')::jsonb
);
SELECT public.register_debt(
  ('{"id":"d_num2","store_id":"st_smoke","person_name":"Cliente B","amount":200,"due_date":"' || (now() + interval '6 days')::text || '","is_customer_debt":true}')::jsonb
);
SQL

d_num1="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT debt_number FROM public.debts WHERE id = 'd_num1';" | tail -n 1)"
d_num2="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT debt_number FROM public.debts WHERE id = 'd_num2';" | tail -n 1)"
[ "$d_num2" = "$((d_num1 + 1))" ] || {
  echo "FALHA: dívidas da MESMA loja deveriam ter números consecutivos (obtido: $d_num1, $d_num2)"
  exit 1
}

# Loja SEM dívidas anteriores (st_emp) começa em 1 — numeração é POR LOJA.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.register_debt(
  ('{"id":"d_emp_num","store_id":"st_emp","person_name":"Cliente C","amount":300,"due_date":"' || (now() + interval '7 days')::text || '","is_customer_debt":true}')::jsonb
);
SQL
d_emp_num="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT debt_number FROM public.debts WHERE id = 'd_emp_num';" | tail -n 1)"
[ "$d_emp_num" = "1" ] || {
  echo "FALHA: primeira dívida da loja st_emp deveria ter número 1 (obtido: '$d_emp_num')"
  exit 1
}

# Retry idempotente (mesmo id) NÃO consome número nem altera o existente.
psql_app -v ON_ERROR_STOP=1 <<'SQL'
SET request.jwt.claims = '{"sub": "11111111-1111-1111-1111-111111111111"}';
SELECT public.register_debt(
  ('{"id":"d_num1","store_id":"st_smoke","person_name":"Cliente A","amount":100,"due_date":"' || (now() + interval '5 days')::text || '","is_customer_debt":true}')::jsonb
);
SQL
d_num1_retry="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT debt_number FROM public.debts WHERE id = 'd_num1';" | tail -n 1)"
[ "$d_num1_retry" = "$d_num1" ] || {
  echo "FALHA: retry idempotente não deveria consumir/alterar número (obtido: $d_num1 -> $d_num1_retry)"
  exit 1
}

# Unicidade por loja: nenhum (store_id, debt_number) duplicado.
d_dupes="$(psql_app -q -tAc "SET request.jwt.claims = '{\"sub\": \"${OWNER_UID}\"}'; SELECT count(*) FROM (SELECT store_id, debt_number FROM public.debts WHERE store_id = 'st_smoke' GROUP BY 1, 2 HAVING count(*) > 1) dup;" | tail -n 1)"
[ "$d_dupes" = "0" ] || {
  echo "FALHA: números duplicados na loja (obtido: '$d_dupes' duplicados)"
  exit 1
}

echo "==> [16/16] Regressão 42710: Realtime idempotente no cenário Supabase"
# O Postgres puro (sem a publicação) NÃO pega o erro 42710 'relation
# "store_employees" is already member of publication "supabase_realtime"'
# (duplicate_object) que o Supabase REAL dispara quando o upgrade.sql roda
# de novo com store_employees já publicada (bug achado no live Aug 8 — a
# Parte 20 fazia ALTER PUBLICATION ADD TABLE sem conferir
# pg_publication_tables; o sql_check.sh antigo não pegava justamente por
# rodar sem a publicação). Simulamos o Supabase aqui: cria a publicação,
# adiciona a tabela como membro e reaplica o upgrade.sql 2x — antes do fix
# isso falhava com 42710 no bloco DO da Parte 20.
psql -v ON_ERROR_STOP=1 <<'SQL'
CREATE PUBLICATION supabase_realtime;
ALTER PUBLICATION supabase_realtime ADD TABLE public.store_employees;
SQL
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql
psql -v ON_ERROR_STOP=1 -f supabase/upgrade.sql

realtime_member="$(psql -q -tAc "SELECT count(*) FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'store_employees';" | tail -n 1)"
[ "$realtime_member" = "1" ] || {
  echo "FALHA: store_employees saiu da publicação supabase_realtime (obtido: '$realtime_member')"
  exit 1
}
# O catálogo de planos (fix Aug 8 — Parte 21 do upgrade.sql) deve sobreviver
# à reaplicação no cenário Supabase (seed idempotente).
catalog_ok="$(psql -q -tAc "SELECT count(*) FROM public.plans WHERE id IN ('pl1','pl2','pl3');" | tail -n 1)"
[ "$catalog_ok" = "3" ] || {
  echo "FALHA: catálogo de planos (pl1/pl2/pl3) ausente após reaplicação (obtido: '$catalog_ok')"
  exit 1
}
echo "OK: upgrade.sql reaplicado 2x no cenário Supabase (publicação + tabela membro) SEM 42710; store_employees segue publicada; catálogo pl1/pl2/pl3 presente"

echo "OK: schema aplicado, super admin via tabela, RLS por loja (dono + funcionário C2), guardas, RPCs atômicos do dinheiro, cadastro de funcionário atômico (conta + vínculo, sem órfãs), varredura completa sem recursão 54001, níveis de acesso (compras só dono/gerente), audit log (só super admin), KPIs agregadas server-side (get_dashboard_kpis), agregações H2 (get_cash_flow / get_sales_report), upgrade.sql idempotente, migração W4 NUMERIC→centavos (×100, sem dupla aplicação), numeração sequencial por loja (vendas S-00001..., compras C-00001..., fiado D-00001...), Realtime sem 42710 no cenário Supabase e catálogo de planos pl1/pl2/pl3 presente conforme esperado."
