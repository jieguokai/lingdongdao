#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexState.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexProviderKind.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Services/CodexLogEventParser.swift" \
  "$ROOT/scripts/verify-log-parser.swift" \
  -o "$TMP_DIR/verify-log-parser"

"$TMP_DIR/verify-log-parser"
