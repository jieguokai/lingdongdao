#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexState.swift" \
  "$ROOT/Sources/CodexLobsterIsland/UI/Shared/PixelLobsterShape.swift" \
  "$ROOT/scripts/verify-pixel-lobster.swift" \
  -o "$TMP_DIR/verify-pixel-lobster"

"$TMP_DIR/verify-pixel-lobster"
