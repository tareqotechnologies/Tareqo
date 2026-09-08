#!/bin/bash
# ─── Android Release Build Script ─────────────────────────────────────
# Build do AAB de PRODUÇÃO localmente (assinado, ofuscado) — mesmo padrão
# do CI (fastlane deploy), para desenvolvedores que buildam fora do
# GitHub Actions.
#
# Uso:
#   ./scripts/build_android.sh              # AAB prod assinado + ofuscado
#   ./scripts/build_android.sh --apk        # APK prod (teste manual)
#
# Pré-requisitos:
#   - env/prod.env  (NUNCA versionado; modelo em env/prod.env.example) —
#     deve conter SUPABASE_URL, SUPABASE_ANON_KEY e
#     SUPABASE_CREDENTIALS_EXPLICIT=true;
#   - android/key.properties (NUNCA versionado; modelo em
#     android/key.properties.example) — keystore de upload/assinatura.
#
# Guardas (B6/A1):
#   - FALHA sem env/prod.env (credenciais explícitas obrigatórias em
#     release — a guarda do SupabaseBootstrap rejeita defaults embutidos);
#   - FALHA sem android/key.properties (nunca publicar AAB assinado com
#     keystore de debug — o Gradle também falha prodRelease sem ele);
#   - SEMPRE --obfuscate --split-debug-info=build/symbols (o build local
#     não pode ficar mais fraco que o CI).
# ────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

BUILD_TARGET="appbundle"
if [[ "${1:-}" == "--apk" ]]; then
  BUILD_TARGET="apk"
fi

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Preflight ──
if ! command -v flutter &>/dev/null; then
  error "Flutter not found. Install Flutter and add to PATH."
fi

if [[ ! -f "env/prod.env" ]]; then
  error "env/prod.env não encontrado. Copie de env/prod.env.example e preencha (projeto Supabase de PRODUÇÃO + SUPABASE_CREDENTIALS_EXPLICIT=true)."
fi

if [[ ! -f "android/key.properties" ]]; then
  error "android/key.properties não encontrado. Copie de android/key.properties.example e preencha com o keystore de produção (ver docs/13-build-e-publicacao.md)."
fi

# ── Carrega defines de produção ──
set -a
source env/prod.env
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  error "env/prod.env incompleto: SUPABASE_URL e SUPABASE_ANON_KEY são obrigatórios."
fi

if [[ "${SUPABASE_CREDENTIALS_EXPLICIT:-}" != "true" ]]; then
  warn "env/prod.env sem SUPABASE_CREDENTIALS_EXPLICIT=true — adicionando automaticamente (A1)."
  SUPABASE_CREDENTIALS_EXPLICIT=true
fi

# ── Build ──
info "Running flutter pub get..."
flutter pub get

DART_DEFINES=(
  "--dart-define=SUPABASE_URL=$SUPABASE_URL"
  "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
  "--dart-define=SUPABASE_CREDENTIALS_EXPLICIT=true"
)
if [[ -n "${SENTRY_DSN:-}" ]]; then
  DART_DEFINES+=("--dart-define=SENTRY_DSN=$SENTRY_DSN")
fi

info "Building $BUILD_TARGET (prod, release, OBFUSCADO)..."
flutter build "$BUILD_TARGET" \
  --flavor prod \
  --release \
  "${DART_DEFINES[@]}" \
  --obfuscate \
  --split-debug-info=build/symbols

info "Build concluído! Symbols em build/symbols (arquivar junto do release)."