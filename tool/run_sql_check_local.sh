#!/usr/bin/env bash
# Local validation of supabase/schema.sql + upgrade.sql + RLS via Docker
# (mirrors the CI sql-check job: postgres:16 service + scripts/sql_check.sh).
# Usage: bash tool/run_sql_check_local.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo '==> (re)criando container pg-check'
docker rm -f pg-check >/dev/null 2>&1 || true
# Caminho do repo em formato Windows (C:/...) + MSYS_NO_PATHCONV: o Git
# Bash converteria '/workspace' para 'C:/Program Files/Git/workspace' e o
# '$(pwd)' (formato /c/...) para um caminho que o Docker Desktop não
# entende. cygpath -m devolve o formato Windows portável do diretório atual.
REPO_WIN="$(cygpath -m "$(pwd)" 2>/dev/null || pwd)"
MSYS_NO_PATHCONV=1 docker run -d --name pg-check \
  -v "${REPO_WIN}:/workspace" \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=dumbhanengue \
  postgres:16 >/dev/null
echo '==> aguardando postgres pronto'
for i in $(seq 1 20); do
  if docker exec pg-check pg_isready -U postgres -q; then
    echo '==> postgres pronto'
    break
  fi
  sleep 1
done

echo '==> executando scripts/sql_check.sh dentro do container'
# Converte CRLF → LF de todos os arquivos usados pelo teste (o checkout
# Windows tem CRLF, que quebra o bash do Linux; psql tolera, mas por
# consistência convertemos tudo). As conversões ficam no /tmp do container.
docker exec pg-check bash -c "
cd /workspace && \
for f in scripts/sql_check.sh sqlcheck_stub.sql supabase/schema.sql supabase/upgrade.sql; do \
  sed 's/\r\$//' \"\$f\" > /tmp/\$(basename \"\$f\") && echo 'convertido: '\$f; \
done && \
PGPASSWORD=postgres bash /tmp/sql_check.sh localhost postgres dumbhanengue"

echo '==> conferindo o catálogo de planos (pl1/pl2/pl3)'
docker exec pg-check psql -U postgres -d dumbhanengue -tAc \
  "SELECT id || ' ' || name || ' MTn ' || price_monthly/100.0 || '/m ' || max_stores || ' lojas ' || max_employees || ' func' FROM public.plans ORDER BY id;"

echo '==> REGRESSÃO 42710 (cenário Supabase real: publicação existe e tabela JÁ é membro)'
# O sql_check.sh roda em Postgres puro (sem a publicação), então não pega o
# erro 42710 'relation is already member of publication' que o Supabase real
# dispara quando o script roda de novo com store_employees já publicada.
# O tool/regress_realtime_42710.sh simula o Supabase e reaplica o upgrade.sql
# inteiro 2x — antes do fix (Aug 8) isso falhava com 42710 no bloco da Parte 20.
docker exec pg-check bash -c "
cd /workspace && \
sed 's/\r\$//' supabase/upgrade.sql > /tmp/upgrade.sql && \
sed 's/\r\$//' tool/regress_realtime_42710.sh > /tmp/regress.sh && \
bash /tmp/regress.sh"

echo '==> conferindo de novo o catálogo (seed deve continuar)'
docker exec pg-check psql -U postgres -d dumbhanengue -tAc \
  "SELECT id || ' (' || name || ')' FROM public.plans ORDER BY id;"
