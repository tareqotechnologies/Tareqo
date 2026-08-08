#!/usr/bin/env bash
# ============================================================================
# Regressão do erro 42710 do Supabase real:
#   "relation \"store_employees\" is already member of publication
#    \"supabase_realtime\"" (duplicate_object)
# O sql_check.sh roda em Postgres PURO (sem a publicação), então nunca pega
# esse erro. Este script simula o Supabase: cria a publicação e ADICIONA a
# tabela ANTES de reaplicar o upgrade.sql — exatamente o que acontece quando
# o script roda de novo num banco onde o bloco da Parte 20 já rodou.
#
# ANTES do fix (Aug 8): a reaplicação falhava com 42710 no bloco DO $$
# (que fazia ALTER PUBLICATION ADD TABLE sem checar pg_publication_tables).
# DEPOIS do fix: o bloco verifica a associação e pula o ADD TABLE.
#
# Espera o upgrade.sql já convertido para LF em /tmp/upgrade.sql (o runner
# converte; checkout Windows tem CRLF que quebra o bash do Linux).
set -euo pipefail

echo '==> [R1] Garantindo publicação supabase_realtime + store_employees como membro'
# Idempotente: o sql_check.sh (passo [16/16]) pode já ter criado a publicação
# e adicionado a tabela — CREATE/ALTER diretos falhariam (42710/duplicate).
psql -U postgres -d dumbhanengue -v ON_ERROR_STOP=1 -q <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END
$$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'store_employees'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.store_employees;
  END IF;
END
$$;
SQL

member_count() {
  psql -U postgres -d dumbhanengue -tAc \
    "SELECT count(*) FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename = 'store_employees';" | tr -d '[:space:]'
}

echo '==> [R2] Verificando estado pré-teste (tabela deve ser membro)'
[ "$(member_count)" = "1" ] || {
  echo 'FALHA: store_employees não está na publicação antes do teste'
  exit 1
}
echo 'OK: estado pré-teste = publicação com store_employees membro (cenário 42710)'

echo '==> [R3] Reaplicando upgrade.sql 2x (antes do fix: 42710 no DO da Parte 20)'
psql -U postgres -d dumbhanengue -v ON_ERROR_STOP=1 -q -f /tmp/upgrade.sql
psql -U postgres -d dumbhanengue -v ON_ERROR_STOP=1 -q -f /tmp/upgrade.sql

echo '==> [R4] Verificando pós-teste'
[ "$(member_count)" = "1" ] || {
  echo 'FALHA: store_employees saiu da publicação supabase_realtime'
  exit 1
}
[ "$(psql -U postgres -d dumbhanengue -tAc \
      "SELECT count(*) FROM public.plans WHERE id IN ('pl1','pl2','pl3');" | tr -d '[:space:]')" = "3" ] || {
  echo 'FALHA: catálogo de planos (pl1/pl2/pl3) ausente após reaplicação'
  exit 1
}
echo 'OK: upgrade.sql reaplicado 2x SEM 42710; tabela continua membro; plans pl1/pl2/pl3 presentes'
