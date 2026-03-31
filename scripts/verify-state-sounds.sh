#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexState.swift" \
  "$ROOT/scripts/verify-state-sounds.swift" \
  -o "$TMP_DIR/verify-state-sounds"

"$TMP_DIR/verify-state-sounds"
