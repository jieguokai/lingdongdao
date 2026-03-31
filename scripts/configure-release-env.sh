#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ENV_FILE="$HOME/.config/codex-lobster-island/release.env"
ENV_FILE="$DEFAULT_ENV_FILE"
IDENTITY=""
NOTARY_PROFILE=""
SPARKLE_PUBLIC_KEY=""
DOWNLOAD_BASE_URL=""
APPCAST_URL=""
RELEASE_NOTES_URL=""
VERSION="0.1.0"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --env-file <path>          Env file to update
                             default: $DEFAULT_ENV_FILE
  --identity <value>         APPLE_DEVELOPER_IDENTITY value
                             default: first local "Developer ID Application" identity
  --notary-profile <value>   APPLE_NOTARY_PROFILE value
  --sparkle-public-key <v>   SPARKLE_PUBLIC_ED_KEY value
  --download-base-url <url>  Base download URL
  --appcast-url <url>        Explicit APPCAST_URL
  --release-notes-url <url>  Explicit RELEASE_NOTES_URL
  --version <value>          Version for derived release notes URL
                             default: $VERSION
  --help                     Show help

Notes:
  If --appcast-url is omitted and --download-base-url is set, APPCAST_URL is
  derived as <download-base-url>/appcast.xml.
  If --release-notes-url is omitted and --download-base-url is set, it is
  derived as <download-base-url>/release-notes/<version>.html.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --sparkle-public-key)
      SPARKLE_PUBLIC_KEY="$2"
      shift 2
      ;;
    --download-base-url)
      DOWNLOAD_BASE_URL="$2"
      shift 2
      ;;
    --appcast-url)
      APPCAST_URL="$2"
      shift 2
      ;;
    --release-notes-url)
      RELEASE_NOTES_URL="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
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

[[ -f "$ENV_FILE" ]] || {
  echo "Env file not found: $ENV_FILE" >&2
  echo "Run ./scripts/init-release-env.sh first." >&2
  exit 1
}

if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*"\\(Developer ID Application: [^"]*\\)".*/\\1/p' | head -n 1)"
fi

if [[ -n "$DOWNLOAD_BASE_URL" ]]; then
  if [[ -z "$APPCAST_URL" ]]; then
    APPCAST_URL="${DOWNLOAD_BASE_URL%/}/appcast.xml"
  fi
  if [[ -z "$RELEASE_NOTES_URL" ]]; then
    RELEASE_NOTES_URL="${DOWNLOAD_BASE_URL%/}/release-notes/${VERSION}.html"
  fi
fi

python3 - "$ENV_FILE" "$IDENTITY" "$NOTARY_PROFILE" "$SPARKLE_PUBLIC_KEY" "$DOWNLOAD_BASE_URL" "$APPCAST_URL" "$RELEASE_NOTES_URL" <<'PY'
import pathlib
import sys

env_path = pathlib.Path(sys.argv[1])
updates = {
    "APPLE_DEVELOPER_IDENTITY": sys.argv[2],
    "APPLE_NOTARY_PROFILE": sys.argv[3],
    "SPARKLE_PUBLIC_ED_KEY": sys.argv[4],
    "DOWNLOAD_BASE_URL": sys.argv[5],
    "APPCAST_URL": sys.argv[6],
    "RELEASE_NOTES_URL": sys.argv[7],
}

lines = env_path.read_text().splitlines()
result = []
seen = set()

for line in lines:
    stripped = line.strip()
    replaced = False
    for key, value in updates.items():
        if stripped.startswith(f"export {key}="):
            seen.add(key)
            if value:
                result.append(f'export {key}="{value}"')
            else:
                result.append(line)
            replaced = True
            break
    if not replaced:
        result.append(line)

for key, value in updates.items():
    if value and key not in seen:
        result.append(f'export {key}="{value}"')

env_path.write_text("\n".join(result) + "\n")
PY

cat <<EOF
Updated release env file:
  $ENV_FILE

Current values filled:
  APPLE_DEVELOPER_IDENTITY=${IDENTITY:-<unchanged>}
  APPLE_NOTARY_PROFILE=${NOTARY_PROFILE:-<unchanged>}
  SPARKLE_PUBLIC_ED_KEY=${SPARKLE_PUBLIC_KEY:+<filled>}
  DOWNLOAD_BASE_URL=${DOWNLOAD_BASE_URL:-<unchanged>}
  APPCAST_URL=${APPCAST_URL:-<unchanged>}
  RELEASE_NOTES_URL=${RELEASE_NOTES_URL:-<unchanged>}

Next:
  1. source "$ENV_FILE"
  2. Run ./scripts/release-doctor.sh
EOF
