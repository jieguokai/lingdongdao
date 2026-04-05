#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexState.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Services/CodexDesktopConversationAnalysis.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Services/CodexDesktopStateInference.swift" \
  "$ROOT/scripts/verify-awaiting-reply-inference.swift" \
  -o "$TMP_DIR/verify-awaiting-reply-inference"

"$TMP_DIR/verify-awaiting-reply-inference"
