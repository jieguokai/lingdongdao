#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPARKLE_BIN_DIR="$ROOT/.build/artifacts/sparkle/Sparkle/bin"
GENERATE_KEYS="$SPARKLE_BIN_DIR/generate_keys"
ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-codex-lobster-island}"
EXPORT_PRIVATE=false
PRIVATE_KEY_FILE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --account <name>         Keychain account name for Sparkle keys
                           default: $ACCOUNT
  --private-key-out <path> Export the private key to a file after ensuring it exists
  --help                   Show help

Environment:
  SPARKLE_KEYCHAIN_ACCOUNT Default for --account
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      ACCOUNT="$2"
      shift 2
      ;;
    --private-key-out)
      EXPORT_PRIVATE=true
      PRIVATE_KEY_FILE="$2"
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

[[ -x "$GENERATE_KEYS" ]] || {
  echo "Sparkle generate_keys tool not found at: $GENERATE_KEYS" >&2
  echo "Run 'swift build -c release' first to fetch Sparkle artifacts." >&2
  exit 1
}

echo "Ensuring Sparkle keypair exists for account: $ACCOUNT"
"$GENERATE_KEYS" --account "$ACCOUNT"

echo
echo "Sparkle public key:"
"$GENERATE_KEYS" --account "$ACCOUNT" -p

if [[ "$EXPORT_PRIVATE" == true ]]; then
  [[ -n "$PRIVATE_KEY_FILE" ]] || {
    echo "Missing --private-key-out path" >&2
    exit 1
  }
  mkdir -p "$(dirname "$PRIVATE_KEY_FILE")"
  "$GENERATE_KEYS" --account "$ACCOUNT" -x "$PRIVATE_KEY_FILE"
  chmod 600 "$PRIVATE_KEY_FILE"
  echo
  echo "Exported Sparkle private key to: $PRIVATE_KEY_FILE"
fi
