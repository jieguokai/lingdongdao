#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexLobsterIsland"
NOTARY_PROFILE="${APPLE_NOTARY_PROFILE:-codex-lobster-notary}"

FAILURES=0
WARNINGS=0

pass() {
  printf '[PASS] %s\n' "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf '[WARN] %s\n' "$1"
}

fail() {
  FAILURES=$((FAILURES + 1))
  printf '[FAIL] %s\n' "$1"
}

check_command() {
  local command_name="$1"
  local label="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

printf 'Release doctor for %s\n' "$APP_NAME"
printf 'Workspace: %s\n' "$ROOT"
printf 'Notary profile: %s\n' "$NOTARY_PROFILE"

check_command swift "swift is installed"
check_command python3 "python3 is installed"
check_command xcrun "xcrun is installed"
check_command codesign "codesign is installed"
check_command security "security is installed"
check_command iconutil "iconutil is installed"

if command -v gh >/dev/null 2>&1; then
  pass "gh is installed"
else
  warn "gh is not installed; local GitHub Release publishing will be unavailable"
fi

check_file "$ROOT/scripts/release-app.sh" "release pipeline script exists"
check_file "$ROOT/scripts/package-app.sh" "package script exists"
check_file "$ROOT/scripts/publish-github-release.sh" "GitHub release publish script exists"
check_file "$ROOT/scripts/import-developer-id-certificate.sh" "Developer ID import helper exists"
check_file "$ROOT/scripts/store-notary-profile.sh" "notary profile helper exists"
check_file "$ROOT/scripts/generate-sparkle-keys.sh" "Sparkle key generator helper exists"
check_file "$ROOT/scripts/export-release-secrets.sh" "release secret export helper exists"
check_file "$ROOT/Config/Release/DeveloperID.entitlements" "Developer ID entitlements exist"
check_file "$ROOT/.github/workflows/release.yml" "GitHub Actions release workflow exists"
check_file "$ROOT/Package.swift" "Package.swift exists"

if [[ -d "$ROOT/.build/artifacts/sparkle/Sparkle/bin" ]]; then
  if [[ -x "$ROOT/.build/artifacts/sparkle/Sparkle/bin/sign_update" ]]; then
    pass "Sparkle sign_update tool is available"
  else
    fail "Sparkle sign_update tool is missing"
  fi
else
  warn "Sparkle artifacts directory is missing; run swift build -c release once before signed feed generation"
fi

if [[ -f "$ROOT/docs/release-notes/latest.md" ]]; then
  pass "default release notes markdown exists"
else
  fail "default release notes markdown is missing"
fi

IDENTITIES_OUTPUT="$(security find-identity -v -p codesigning 2>/dev/null || true)"
if printf '%s\n' "$IDENTITIES_OUTPUT" | grep -Eq '[1-9][0-9]* valid identities found'; then
  pass "at least one code signing identity is available"
else
  fail "no code signing identities were found in the current keychain"
fi

if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
  pass "notarytool profile '$NOTARY_PROFILE' is available"
else
  fail "notarytool profile '$NOTARY_PROFILE' is missing or inaccessible"
fi

if [[ -n "${APPLE_DEVELOPER_IDENTITY:-}" ]]; then
  pass "APPLE_DEVELOPER_IDENTITY is set"
else
  warn "APPLE_DEVELOPER_IDENTITY is not set"
fi

if [[ -n "${APPLE_NOTARY_PROFILE:-}" ]]; then
  pass "APPLE_NOTARY_PROFILE is set"
else
  warn "APPLE_NOTARY_PROFILE is not set; defaulting to $NOTARY_PROFILE"
fi

if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  pass "SPARKLE_PUBLIC_ED_KEY is set"
else
  warn "SPARKLE_PUBLIC_ED_KEY is not set; in-app updater will stay disabled"
fi

if [[ -n "${SPARKLE_PRIVATE_ED_KEY_FILE:-}" ]]; then
  if [[ -f "${SPARKLE_PRIVATE_ED_KEY_FILE}" ]]; then
    pass "SPARKLE_PRIVATE_ED_KEY_FILE points to an existing file"
  else
    fail "SPARKLE_PRIVATE_ED_KEY_FILE is set but the file does not exist"
  fi
else
  warn "SPARKLE_PRIVATE_ED_KEY_FILE is not set; appcast and archive EdDSA signatures will be skipped"
fi

if [[ -n "${DOWNLOAD_BASE_URL:-}" ]]; then
  pass "DOWNLOAD_BASE_URL is set"
else
  warn "DOWNLOAD_BASE_URL is not set; feed URLs cannot be derived automatically"
fi

if [[ -n "${APPCAST_URL:-}" ]]; then
  pass "APPCAST_URL is set"
else
  warn "APPCAST_URL is not set; Sparkle feed embedding will be disabled"
fi

if [[ -n "${RELEASE_NOTES_URL:-}" ]]; then
  pass "RELEASE_NOTES_URL is set"
else
  warn "RELEASE_NOTES_URL is not set; release notes link will be derived only when DOWNLOAD_BASE_URL is available"
fi

printf 'Summary: %d failure(s), %d warning(s)\n' "$FAILURES" "$WARNINGS"

if [[ "$FAILURES" -gt 0 ]]; then
  exit 1
fi
