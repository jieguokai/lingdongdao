#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/Sources/CodexLobsterIsland/Resources/Audio/success.wav"

INFO="$(python3 - <<'PY' "$TARGET"
import json
import sys
import wave

target = sys.argv[1]
with wave.open(target, "rb") as wav_file:
    print(json.dumps({
        "channels": wav_file.getnchannels(),
        "rate": wav_file.getframerate(),
        "width": wav_file.getsampwidth(),
        "duration": wav_file.getnframes() / wav_file.getframerate(),
    }))
PY
)"

CHANNELS="$(python3 - <<'PY' "$INFO"
import json
import sys
print(json.loads(sys.argv[1])["channels"])
PY
)"

RATE="$(python3 - <<'PY' "$INFO"
import json
import sys
print(json.loads(sys.argv[1])["rate"])
PY
)"

DURATION="$(python3 - <<'PY' "$INFO"
import json
import sys
print(json.loads(sys.argv[1])["duration"])
PY
)"

[ "$CHANNELS" = "1" ] || {
  echo "Expected success.wav to remain mono, got ${CHANNELS} channels" >&2
  exit 1
}

[ "$RATE" = "44100" ] || {
  echo "Expected success.wav to remain 44100 Hz, got ${RATE} Hz" >&2
  exit 1
}

if ! python3 - <<'PY' "$DURATION"
import sys

duration = float(sys.argv[1])
if not (3.0 <= duration <= 3.8):
    raise SystemExit(1)
PY
then
  echo "Expected success.wav duration to match the new success clip (3.0s - 3.8s), got ${DURATION}s" >&2
  exit 1
fi

echo "success audio verification passed"
