#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --p12 <path>                 Path to Developer ID .p12 file
  --sparkle-private-key <path> Path to exported Sparkle private key file
  --output <path>              Optional file to write shell exports into
  --help                       Show help

This script prints values you can paste into GitHub Actions secrets.
If --output is provided, it writes export statements for local reuse.
EOF
}

P12_PATH=""
SPARKLE_PRIVATE_KEY_PATH=""
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --p12)
      P12_PATH="$2"
      shift 2
      ;;
    --sparkle-private-key)
      SPARKLE_PRIVATE_KEY_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
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

encode_base64() {
  python3 - "$1" <<'PY'
import base64
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
print(base64.b64encode(data).decode("ascii"))
PY
}

P12_BASE64=""
SPARKLE_PRIVATE_KEY_BASE64=""

if [[ -n "$P12_PATH" ]]; then
  [[ -f "$P12_PATH" ]] || { echo "P12 file not found: $P12_PATH" >&2; exit 1; }
  P12_BASE64="$(encode_base64 "$P12_PATH")"
fi

if [[ -n "$SPARKLE_PRIVATE_KEY_PATH" ]]; then
  [[ -f "$SPARKLE_PRIVATE_KEY_PATH" ]] || { echo "Sparkle private key file not found: $SPARKLE_PRIVATE_KEY_PATH" >&2; exit 1; }
  SPARKLE_PRIVATE_KEY_BASE64="$(encode_base64 "$SPARKLE_PRIVATE_KEY_PATH")"
fi

cat <<EOF
GitHub Actions secret values:
EOF

if [[ -n "$P12_BASE64" ]]; then
  cat <<EOF
APPLE_DEVELOPER_ID_P12_BASE64=$P12_BASE64
EOF
else
  echo "APPLE_DEVELOPER_ID_P12_BASE64=<provide --p12 to generate>"
fi

if [[ -n "$SPARKLE_PRIVATE_KEY_BASE64" ]]; then
  cat <<EOF
SPARKLE_PRIVATE_ED_KEY_BASE64=$SPARKLE_PRIVATE_KEY_BASE64
EOF
else
  echo "SPARKLE_PRIVATE_ED_KEY_BASE64=<provide --sparkle-private-key to generate>"
fi

if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  {
    if [[ -n "$P12_BASE64" ]]; then
      printf 'export APPLE_DEVELOPER_ID_P12_BASE64=%q\n' "$P12_BASE64"
    fi
    if [[ -n "$SPARKLE_PRIVATE_KEY_BASE64" ]]; then
      printf 'export SPARKLE_PRIVATE_ED_KEY_BASE64=%q\n' "$SPARKLE_PRIVATE_KEY_BASE64"
    fi
  } > "$OUTPUT_PATH"
  chmod 600 "$OUTPUT_PATH"
  echo
  echo "Wrote export file: $OUTPUT_PATH"
fi
