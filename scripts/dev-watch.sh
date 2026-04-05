#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexLobsterIsland"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
TARGET_APP_PATH="$INSTALL_DIR/${APP_NAME}.app"
TARGET_BINARY="$TARGET_APP_PATH/Contents/MacOS/$APP_NAME"
INTERVAL="${DEV_WATCH_INTERVAL:-0.8}"
DEBOUNCE="${DEV_WATCH_DEBOUNCE:-0.6}"
NO_OPEN_INITIAL=false

WATCH_PATHS=(
  "$ROOT/Sources"
  "$ROOT/Package.swift"
  "$ROOT/Config"
  "$ROOT/scripts/package-app.sh"
  "$ROOT/scripts/install-app.sh"
  "$ROOT/scripts/dev-watch.sh"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [--interval <seconds>] [--debounce <seconds>] [--no-open-initial]

Watches local source files and resources. On save, rebuilds the app, reinstalls it to:
  $TARGET_APP_PATH
and relaunches the installed copy.

Options:
  --interval <seconds>    Poll interval between scans (default: $INTERVAL)
  --debounce <seconds>    Wait after first change before rebuilding (default: $DEBOUNCE)
  --no-open-initial       Do not auto-open the app when the watcher starts

Environment:
  INSTALL_DIR             Override the install directory
  DEV_WATCH_INTERVAL      Default poll interval
  DEV_WATCH_DEBOUNCE      Default debounce time
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      INTERVAL="${2:?missing value for --interval}"
      shift 2
      ;;
    --debounce)
      DEBOUNCE="${2:?missing value for --debounce}"
      shift 2
      ;;
    --no-open-initial)
      NO_OPEN_INITIAL=true
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

log() {
  printf '[dev-watch] %s\n' "$1"
}

is_app_running() {
  pgrep -fx "$TARGET_BINARY" >/dev/null 2>&1
}

open_installed_app() {
  open "$TARGET_APP_PATH"
}

fingerprint() {
  python3 - "${WATCH_PATHS[@]}" <<'PY'
import os
import sys

ignored = {".build", "build", "dist"}
latest = 0

for path in sys.argv[1:]:
    if not os.path.exists(path):
        continue

    if os.path.isfile(path):
        try:
            latest = max(latest, os.stat(path).st_mtime_ns)
        except FileNotFoundError:
            pass
        continue

    for dirpath, dirnames, filenames in os.walk(path):
        dirnames[:] = [name for name in dirnames if name not in ignored]
        for filename in filenames:
            full_path = os.path.join(dirpath, filename)
            try:
                latest = max(latest, os.stat(full_path).st_mtime_ns)
            except FileNotFoundError:
                pass

print(latest)
PY
}

install_and_refresh() {
  if "$ROOT/scripts/install-app.sh" --no-open; then
    log "Build installed. Launching app."
    open_installed_app
  else
    log "Build failed. Waiting for the next save."
    return 1
  fi
}

ensure_initial_install() {
  if [[ ! -d "$TARGET_APP_PATH" ]]; then
    log "No installed app found. Installing to $TARGET_APP_PATH"
  else
    log "Syncing the installed app to the latest local code."
  fi

  if ! "$ROOT/scripts/install-app.sh" --no-open; then
    log "Initial install failed. Fix the build and save again."
    return 1
  fi

  if [[ "$NO_OPEN_INITIAL" == false ]]; then
    log "Launching installed app."
    open_installed_app
  fi
}

trap 'log "Stopped."; exit 0' INT TERM

ensure_initial_install || true
last_fingerprint="$(fingerprint)"
log "Watching for changes..."

while true; do
  sleep "$INTERVAL"
  current_fingerprint="$(fingerprint)"
  if [[ "$current_fingerprint" == "$last_fingerprint" ]]; then
    continue
  fi

  log "Change detected. Waiting ${DEBOUNCE}s for saves to settle."
  sleep "$DEBOUNCE"

  settled_fingerprint="$(fingerprint)"
  while [[ "$settled_fingerprint" != "$current_fingerprint" ]]; do
    current_fingerprint="$settled_fingerprint"
    sleep "$DEBOUNCE"
    settled_fingerprint="$(fingerprint)"
  done

  last_fingerprint="$settled_fingerprint"
  install_and_refresh || true
  last_fingerprint="$(fingerprint)"
done
