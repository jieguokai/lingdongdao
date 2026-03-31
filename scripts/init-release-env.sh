#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_PATH="$ROOT/Config/Release/release.env.example"
DEFAULT_OUTPUT_DIR="$HOME/.config/codex-lobster-island"
OUTPUT_PATH="$DEFAULT_OUTPUT_DIR/release.env"
PRIVATE_KEY_PATH=""
FORCE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --output <path>            Output env file path
                             default: $OUTPUT_PATH
  --private-key-file <path>  Pre-fill SPARKLE_PRIVATE_ED_KEY_FILE with this path
  --force                    Overwrite existing output file
  --help                     Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --private-key-file)
      PRIVATE_KEY_PATH="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
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

[[ -f "$TEMPLATE_PATH" ]] || {
  echo "Template not found: $TEMPLATE_PATH" >&2
  exit 1
}

mkdir -p "$(dirname "$OUTPUT_PATH")"

if [[ -f "$OUTPUT_PATH" && "$FORCE" != true ]]; then
  echo "Output file already exists: $OUTPUT_PATH" >&2
  echo "Use --force to overwrite it." >&2
  exit 1
fi

cp "$TEMPLATE_PATH" "$OUTPUT_PATH"

if [[ -n "$PRIVATE_KEY_PATH" ]]; then
  python3 - "$OUTPUT_PATH" "$PRIVATE_KEY_PATH" <<'PY'
import pathlib
import sys

env_path = pathlib.Path(sys.argv[1])
private_key_path = sys.argv[2]
lines = env_path.read_text().splitlines()
updated = []
replaced = False

for line in lines:
    if line.startswith("# export SPARKLE_PRIVATE_ED_KEY_FILE="):
        updated.append(f'export SPARKLE_PRIVATE_ED_KEY_FILE="{private_key_path}"')
        replaced = True
    else:
        updated.append(line)

if not replaced:
    updated.append(f'export SPARKLE_PRIVATE_ED_KEY_FILE="{private_key_path}"')

env_path.write_text("\n".join(updated) + "\n")
PY
fi

chmod 600 "$OUTPUT_PATH"

cat <<EOF
Initialized release env file:
  $OUTPUT_PATH

Next:
  1. Edit the placeholder values in that file
  2. source "$OUTPUT_PATH"
  3. Run ./scripts/release-doctor.sh
EOF
