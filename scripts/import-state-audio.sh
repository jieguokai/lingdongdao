#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIO_DIR="$ROOT/Sources/CodexLobsterIsland/Resources/Audio"

RUNNING_SOURCE="${1:-/Users/kevin/Downloads/running.mp3}"
SUCCESS_SOURCE="${2:-/Users/kevin/Downloads/success.mp3}"
ERROR_SOURCE="${3:-/Users/kevin/Downloads/error.mp3}"

convert_to_wav() {
  local source_file="$1"
  local target_file="$2"

  if [[ ! -f "$source_file" ]]; then
    echo "Missing source audio: $source_file" >&2
    exit 1
  fi

  /usr/bin/afconvert \
    -f WAVE \
    -d LEI16 \
    "$source_file" \
    "$target_file"
}

mkdir -p "$AUDIO_DIR"

convert_to_wav "$RUNNING_SOURCE" "$AUDIO_DIR/running.wav"
convert_to_wav "$SUCCESS_SOURCE" "$AUDIO_DIR/success.wav"
convert_to_wav "$ERROR_SOURCE" "$AUDIO_DIR/error.wav"

echo "Imported state audio into $AUDIO_DIR"
