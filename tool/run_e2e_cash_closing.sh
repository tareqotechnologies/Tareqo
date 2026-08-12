#!/usr/bin/env bash
# E2E real da RPC get_cash_closing_summary contra o Supabase (chrome + chromedriver :4444).
# Uso: bash tool/run_e2e_cash_closing.sh <email> <senha>
# --no-dds é o workaround documentado para o bug AppConnectionException do dwds
# no Windows (checklist 6.4). Porta web explícita evita conflito.
set -uo pipefail

EMAIL="${1:?use: bash tool/run_e2e_cash_closing.sh <email> <senha>}"
PASS="${2:?use: bash tool/run_e2e_cash_closing.sh <email> <senha>}"

flutter drive \
  --no-dds \
  --web-port=7357 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/cash_closing_summary_live_test.dart \
  -d chrome \
  --dart-define-from-file=env/dev.env \
  --dart-define=TEST_OWNER_EMAIL="$EMAIL" \
  --dart-define=TEST_OWNER_PASSWORD="$PASS"
