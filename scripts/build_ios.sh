#!/bin/bash
# ─── iOS Build Script ─────────────────────────────────────────────────
# Build IPA for TestFlight/App Store from a Mac with Xcode installed.
#
# Usage:
#   ./scripts/build_ios.sh              # Build IPA only (local)
#   ./scripts/build_ios.sh --upload     # Build + upload to TestFlight
#
# Required env vars (set in .env/ios.env or export):
#   SUPABASE_URL          — Supabase project URL (production)
#   SUPABASE_ANON_KEY     — Supabase anon key (production)
#   APPLE_ISSUER_ID       — App Store Connect API issuer ID
#   APPLE_KEY_ID          — App Store Connect API key ID
#   APPLE_KEY_CONTENT     — Base64-encoded .p8 key file
#   APPLE_TEAM_ID         — Apple Developer team ID
#
# Optional:
#   SENTRY_DSN            — Sentry DSN for crash reporting
#
# ────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

UPLOAD=false
if [[ "${1:-}" == "--upload" ]]; then
  UPLOAD=true
fi

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Preflight checks ──
if ! command -v flutter &>/dev/null; then
  error "Flutter not found. Install Flutter and add to PATH."
fi

if ! command -v xcodebuild &>/dev/null; then
  error "Xcode not found. Install Xcode from the Mac App Store."
fi

if [[ ! -f "env/ios.env" ]]; then
  warn "env/ios.env not found. Using environment variables."
fi

# Load env file if present
if [[ -f "env/ios.env" ]]; then
  info "Loading env/ios.env..."
  set -a
  source env/ios.env
  set +a
fi

# ── Validate required vars ──
REQUIRED_VARS=(
  "SUPABASE_URL"
  "SUPABASE_ANON_KEY"
  "APPLE_ISSUER_ID"
  "APPLE_KEY_ID"
  "APPLE_KEY_CONTENT"
  "APPLE_TEAM_ID"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    error "Missing required env var: $var"
  fi
done

info "All required environment variables present."

# ── Build ──
info "Running flutter pub get..."
flutter pub get

info "Building iOS (no codesign)..."
DART_DEFINES=(
  "--dart-define=SUPABASE_URL=$SUPABASE_URL"
  "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
)
if [[ -n "${SENTRY_DSN:-}" ]]; then
  DART_DEFINES+=("--dart-define=SENTRY_DSN=$SENTRY_DSN")
fi

flutter build ios --release "${DART_DEFINES[@]}" --no-codesign

if [[ "$UPLOAD" == "true" ]]; then
  info "Building signed IPA..."
  cd ios
  bundle install
  bundle exec fastlane ios beta
  cd ..
  info "IPA uploaded to TestFlight!"
else
  info "Build complete. IPA ready in build/ios/iphoneos/"
  info "To upload to TestFlight: ./scripts/build_ios.sh --upload"
  info "Or: cd ios && bundle exec fastlane ios beta"
fi

info "Done!"
