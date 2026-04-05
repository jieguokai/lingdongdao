#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIO_DIR="$ROOT/Sources/CodexLobsterIsland/Resources/Audio"

python3 - <<'PY' "$AUDIO_DIR"
import sys
import wave
from pathlib import Path

audio_dir = Path(sys.argv[1])
audio_files = [
    "typing.wav",
    "running.wav",
    "awaitingReply.wav",
    "approval.wav",
    "success.wav",
    "error.wav",
]

for filename in audio_files:
    target = audio_dir / filename
    if not target.exists():
        raise SystemExit(f"Missing audio file: {filename}")

    with wave.open(str(target), "rb") as wav_file:
        rate = wav_file.getframerate()
        duration = wav_file.getnframes() / rate

    if duration <= 0:
        raise SystemExit(f"Expected {filename} to have a positive duration")
    if rate <= 0:
        raise SystemExit(f"Expected {filename} to have a positive sample rate")

print("brand audio verification passed")
PY
