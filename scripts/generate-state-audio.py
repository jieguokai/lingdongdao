#!/usr/bin/env python3
from __future__ import annotations

import math
import subprocess
import struct
import tempfile
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
MAX_AMPLITUDE = 0.55


def pulse_wave(phase: float, duty_cycle: float = 0.24) -> float:
    return 1.0 if phase < duty_cycle else -1.0


def triangle_wave(phase: float) -> float:
    return 1.0 - 4.0 * abs(phase - 0.5)


def envelope(position: int, total: int, attack: float = 0.08, release: float = 0.18) -> float:
    if total <= 1:
        return 1.0

    progress = position / max(total - 1, 1)
    if progress < attack:
        return progress / attack
    if progress > 1.0 - release:
        return max(0.0, (1.0 - progress) / release)
    return 1.0


def synth_tone(
    frequency: float,
    duration: float,
    *,
    volume: float = 1.0,
    duty_cycle: float = 0.24,
    vibrato_rate: float = 0.0,
    vibrato_depth: float = 0.0,
) -> list[float]:
    sample_count = max(1, int(duration * SAMPLE_RATE))
    samples: list[float] = []
    phase = 0.0
    triangle_phase = 0.0

    for index in range(sample_count):
        time = index / SAMPLE_RATE
        modulation = 1.0 + (math.sin(time * math.tau * vibrato_rate) * vibrato_depth if vibrato_rate else 0.0)
        step = (frequency * modulation) / SAMPLE_RATE
        phase = (phase + step) % 1.0
        triangle_phase = (triangle_phase + step) % 1.0
        shape = (pulse_wave(phase, duty_cycle) * 0.78) + (triangle_wave(triangle_phase) * 0.22)
        samples.append(shape * envelope(index, sample_count) * volume)

    return samples


def synth_rest(duration: float) -> list[float]:
    return [0.0] * max(1, int(duration * SAMPLE_RATE))


def write_wave(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
        temp_path = Path(temp_file.name)

    with wave.open(str(temp_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample * MAX_AMPLITUDE))
            frames.extend(struct.pack("<h", int(clamped * 32767)))
        wav_file.writeframes(frames)

    try:
        subprocess.run(
            [
                "/usr/bin/afconvert",
                "-f",
                "WAVE",
                "-d",
                "LEI16@44100",
                "-c",
                "1",
                str(temp_path),
                str(path),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        temp_path.replace(path)
    else:
        temp_path.unlink(missing_ok=True)


def build_sequence(segments: list[dict[str, float | bool]]) -> list[float]:
    output: list[float] = []
    for segment in segments:
        if segment.get("rest"):
            output.extend(synth_rest(float(segment["duration"])))
            continue

        output.extend(
            synth_tone(
                float(segment["frequency"]),
                float(segment["duration"]),
                volume=float(segment.get("volume", 1.0)),
                duty_cycle=float(segment.get("duty_cycle", 0.24)),
                vibrato_rate=float(segment.get("vibrato_rate", 0.0)),
                vibrato_depth=float(segment.get("vibrato_depth", 0.0)),
            )
        )
    return output


SOUNDS = {
    "typing.wav": [
        {"frequency": 1318.51, "duration": 0.055, "volume": 0.85},
        {"rest": True, "duration": 0.01},
        {"frequency": 1567.98, "duration": 0.045, "volume": 0.7},
    ],
    "running.wav": [
        {"frequency": 659.25, "duration": 0.085, "volume": 0.72},
        {"rest": True, "duration": 0.03},
        {"frequency": 783.99, "duration": 0.12, "volume": 0.9},
    ],
    "awaitingReply.wav": [
        {"frequency": 587.33, "duration": 0.08, "volume": 0.68},
        {"rest": True, "duration": 0.025},
        {"frequency": 783.99, "duration": 0.11, "volume": 0.82},
        {"rest": True, "duration": 0.025},
        {"frequency": 987.77, "duration": 0.12, "volume": 0.88, "vibrato_rate": 6.0, "vibrato_depth": 0.012},
    ],
    "approval.wav": [
        {"frequency": 783.99, "duration": 0.07, "volume": 0.76},
        {"rest": True, "duration": 0.03},
        {"frequency": 1046.50, "duration": 0.09, "volume": 0.88},
        {"rest": True, "duration": 0.03},
        {"frequency": 1318.51, "duration": 0.13, "volume": 0.98},
    ],
    "success.wav": [
        {"frequency": 523.25, "duration": 0.10, "volume": 0.65},
        {"rest": True, "duration": 0.02},
        {"frequency": 659.25, "duration": 0.11, "volume": 0.78},
        {"rest": True, "duration": 0.02},
        {"frequency": 783.99, "duration": 0.12, "volume": 0.9},
        {"rest": True, "duration": 0.02},
        {"frequency": 1046.50, "duration": 0.24, "volume": 1.0, "vibrato_rate": 7.0, "vibrato_depth": 0.014},
    ],
    "error.wav": [
        {"frequency": 622.25, "duration": 0.08, "volume": 0.8},
        {"rest": True, "duration": 0.025},
        {"frequency": 466.16, "duration": 0.10, "volume": 0.9},
        {"rest": True, "duration": 0.02},
        {"frequency": 349.23, "duration": 0.18, "volume": 0.95, "vibrato_rate": 5.0, "vibrato_depth": 0.02},
    ],
}


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    output_dir = root / "Sources" / "CodexLobsterIsland" / "Resources" / "Audio"

    for filename, sequence in SOUNDS.items():
        write_wave(output_dir / filename, build_sequence(sequence))
        print(f"generated {filename}")


if __name__ == "__main__":
    main()
