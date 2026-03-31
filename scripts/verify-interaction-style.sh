#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  "$ROOT/Sources/CodexLobsterIsland/UI/Interaction/InteractivePhase.swift" \
  "$ROOT/Sources/CodexLobsterIsland/UI/Interaction/InteractionStyle.swift" \
  "$ROOT/scripts/verify-interaction-style.swift" \
  -o "$TMP_DIR/verify-interaction-style"

"$TMP_DIR/verify-interaction-style"
