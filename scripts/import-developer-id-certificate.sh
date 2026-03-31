#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --p12 <path> --password <value> [options]

Options:
  --keychain <path>             Keychain path to import into
                                default: ~/Library/Keychains/login.keychain-db
  --keychain-password <value>   Required when importing into a custom keychain
  --help                        Show help

Environment:
  APPLE_DEVELOPER_ID_P12_PASSWORD  Default for --password
  APPLE_KEYCHAIN_PASSWORD          Default for --keychain-password
EOF
}

P12_PATH=""
P12_PASSWORD="${APPLE_DEVELOPER_ID_P12_PASSWORD:-}"
KEYCHAIN_PATH="$HOME/Library/Keychains/login.keychain-db"
KEYCHAIN_PASSWORD="${APPLE_KEYCHAIN_PASSWORD:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --p12)
      P12_PATH="$2"
      shift 2
      ;;
    --password)
      P12_PASSWORD="$2"
      shift 2
      ;;
    --keychain)
      KEYCHAIN_PATH="$2"
      shift 2
      ;;
    --keychain-password)
      KEYCHAIN_PASSWORD="$2"
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

[[ -n "$P12_PATH" ]] || { echo "Missing --p12" >&2; exit 1; }
[[ -f "$P12_PATH" ]] || { echo "P12 file not found: $P12_PATH" >&2; exit 1; }
[[ -n "$P12_PASSWORD" ]] || { echo "Missing certificate password. Pass --password or set APPLE_DEVELOPER_ID_P12_PASSWORD." >&2; exit 1; }

if [[ "$KEYCHAIN_PATH" != "$HOME/Library/Keychains/login.keychain-db" ]]; then
  [[ -n "$KEYCHAIN_PASSWORD" ]] || {
    echo "Custom keychain import requires --keychain-password or APPLE_KEYCHAIN_PASSWORD." >&2
    exit 1
  }
  if ! security show-keychain-info "$KEYCHAIN_PATH" >/dev/null 2>&1; then
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  fi
  security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security list-keychains -d user -s "$KEYCHAIN_PATH"
  security default-keychain -d user -s "$KEYCHAIN_PATH"
fi

security import "$P12_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"

if [[ -n "$KEYCHAIN_PASSWORD" ]]; then
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
fi

echo "Imported Developer ID certificate into: $KEYCHAIN_PATH"
security find-identity -v -p codesigning "$KEYCHAIN_PATH" || true
