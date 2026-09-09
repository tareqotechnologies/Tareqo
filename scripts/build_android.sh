#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────
# scripts/build_android.sh — build de PRODUÇÃO Android (flavor prod)
#
#   ./scripts/build_android.sh             # AAB prod (publicação Play) ← DEFAULT
#   ./scripts/build_android.sh --apk       # APK prod (APENAS teste manual)
#
# Requisitos:
#   - env/prod.env (SUPABASE_URL + SUPABASE_ANON_KEY + SENTRY_DSN opcional)
#   - android/key.properties (keystore de produção — o Gradle falha sem ele)
#
# O que o script faz:
#   - SEMPRE --flavor prod --release (o main.dart recusa release sem prod);
#   - SEMPRE --obfuscate --split-debug-info=build/symbols (o build local
#     guarda os símbolos de ofuscação para dessimbolizar crashes no Sentry);
#   - AAB por padrão (A3): o Play App Signing gera APKs por ABI/densidade a
#     partir do bundle — download muito menor que o APK universal de 86 MB.
#     O APK é mantido apenas para side-load/teste manual;
#   - Pós-build: verifica que a URL do Supabase de produção está EMBUTIDA
#     no binário (detecta cache/defines obsoletos — "app preso no login").
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

# ── Pós-build: o define ENTROU no binário? (fix "apk preso no login") ──
# Um build com cache/config de defines obsoleto compila SEM a URL do Supabase
# (ou com a de dev): SupabaseConfig.isConfigured fica false, o login falha
# em silêncio e o app fica preso na tela de login. O grep abaixo falha o
# script se o projeto de produção NÃO estiver dentro do artifact.
info "Verificando se a URL do Supabase de produção foi embutida no artifact..."
PROJ_REF="$(printf '%s' "$SUPABASE_URL" | sed -E 's#https://([a-z0-9]+)\.supabase\.co.*#\1#')"
if [[ -z "$PROJ_REF" ]]; then
  error "SUPABASE_URL fora do formato esperado (https://<ref>.supabase.co)."
fi

if [[ "$BUILD_TARGET" == "appbundle" ]]; then
  ARTIFACT="build/app/outputs/bundle/prodRelease/app-prod-release.aab"
else
  ARTIFACT="build/app/outputs/flutter-apk/app-prod-release.apk"
fi
if [[ ! -f "$ARTIFACT" ]]; then
  error "Artifact não encontrado: $ARTIFACT — o build falhou silenciosamente?"
fi

FOUND="$(python - "$ARTIFACT" "$PROJ_REF" <<'PYEOF'
import re, sys, zipfile
artifact, ref = sys.argv[1], sys.argv[2]
n = 0
with zipfile.ZipFile(artifact) as z:
    for name in z.namelist():
        if name.endswith('libapp.so'):
            n += len(re.findall(ref.encode(), z.read(name)))
print(n)
PYEOF
)"
if [[ "$FOUND" == "0" ]]; then
  error "O artifact NÃO contém a URL do projeto de produção ($PROJ_REF). O build usou defines obsoletos — rode 'flutter clean' e rebuild."
fi
info "OK: URL de $PROJ_REF embutida no artifact ($FOUND ocorrências)."

# ── Tamanho do artifact (A3): visibilidade do custo de download ──
SIZE_BYTES="$(wc -c <"$ARTIFACT" | tr -d '[:space:]')"
SIZE_MB="$((SIZE_BYTES / 1048576))"
info "Tamanho do $BUILD_TARGET: ${SIZE_MB} MB ($ARTIFACT)."
if [[ "$BUILD_TARGET" == "appbundle" && "$SIZE_MB" -gt 60 ]]; then
  warn "AAB acima de 60 MB — rode 'flutter build apk --analyze-size' e revise assets/libs antes de publicar."
fi

if [[ "$BUILD_TARGET" == "appbundle" ]]; then
  info "AAB pronto para o Play (fastlane/android beta ou upload manual no Console)."
  info "APKs por ABI/densidade são gerados pelo Play App Signing — não distribua o APK universal."
else
  warn "APK universal — use apenas para TESTE manual; a publicação é SEMPRE via AAB."
fi
info "Build concluído! Symbols em build/symbols (arquivar junto do release)."
