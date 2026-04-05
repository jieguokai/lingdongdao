#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexLobsterIsland"
DIST_APP_PATH="${DIST_APP_PATH:-$ROOT/dist/${APP_NAME}.app}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
TARGET_APP_PATH="$INSTALL_DIR/${APP_NAME}.app"
OPEN_AFTER_INSTALL=true

stop_running_app_copies() {
  local pattern="/${APP_NAME}\\.app/Contents/MacOS/${APP_NAME}$"
  if pgrep -f "$pattern" >/dev/null 2>&1; then
    pkill -f "$pattern" || true
    sleep 1
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--no-open]

Builds the packaged app, installs it to a stable local path, and optionally launches it.

Defaults:
  install dir: $INSTALL_DIR
  target app:  $TARGET_APP_PATH

Environment:
  INSTALL_DIR     Override the install directory
  DIST_APP_PATH   Override the packaged app path
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-open)
      OPEN_AFTER_INSTALL=false
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

"$ROOT/scripts/package-app.sh"

[[ -d "$DIST_APP_PATH" ]] || {
  echo "Packaged app not found: $DIST_APP_PATH" >&2
  exit 1
}

mkdir -p "$INSTALL_DIR"

stop_running_app_copies

rm -rf "$TARGET_APP_PATH"
/usr/bin/ditto "$DIST_APP_PATH" "$TARGET_APP_PATH"

echo "Installed app at: $TARGET_APP_PATH"
echo "Use this path for macOS permissions: $TARGET_APP_PATH"

if [[ "$OPEN_AFTER_INSTALL" == true ]]; then
  open "$TARGET_APP_PATH"
fi
