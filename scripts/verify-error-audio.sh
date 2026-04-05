#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/Sources/CodexLobsterIsland/Resources/Audio/error.wav"

INFO="$(python3 - <<'PY' "$TARGET"
import json
import sys
import wave

target = sys.argv[1]
with wave.open(target, "rb") as wav_file:
    print(json.dumps({
        "duration": wav_file.getnframes() / wav_file.getframerate(),
    }))
PY
)"

DURATION="$(python3 - <<'PY' "$INFO"
import json
import sys
print(json.loads(sys.argv[1])["duration"])
PY
)"

if ! python3 - <<'PY' "$DURATION"
import sys

duration = float(sys.argv[1])
if not (duration > 0):
    raise SystemExit(1)
PY
then
  echo "Expected error.wav to have a positive duration, got ${DURATION}s" >&2
  exit 1
fi

echo "error audio verification passed"
