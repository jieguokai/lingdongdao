#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --profile <name>      notarytool profile name (default: codex-lobster-notary)
  --apple-id <value>    Apple ID email
  --team-id <value>     Apple Developer Team ID
  --password <value>    App-specific password
  --help                Show help

Environment:
  APPLE_NOTARY_PROFILE           Default for --profile
  APPLE_NOTARY_APPLE_ID          Default for --apple-id
  APPLE_TEAM_ID                  Default for --team-id
  APPLE_APP_SPECIFIC_PASSWORD    Default for --password
EOF
}

PROFILE="${APPLE_NOTARY_PROFILE:-codex-lobster-notary}"
APPLE_ID="${APPLE_NOTARY_APPLE_ID:-}"
TEAM_ID="${APPLE_TEAM_ID:-}"
APP_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --apple-id)
      APPLE_ID="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --password)
      APP_PASSWORD="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -n "$APPLE_ID" ]] || { echo "Missing Apple ID. Pass --apple-id or set APPLE_NOTARY_APPLE_ID." >&2; exit 1; }
[[ -n "$TEAM_ID" ]] || { echo "Missing Team ID. Pass --team-id or set APPLE_TEAM_ID." >&2; exit 1; }
[[ -n "$APP_PASSWORD" ]] || { echo "Missing app-specific password. Pass --password or set APPLE_APP_SPECIFIC_PASSWORD." >&2; exit 1; }

xcrun notarytool store-credentials "$PROFILE" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD"

echo "Stored notarytool profile: $PROFILE"
