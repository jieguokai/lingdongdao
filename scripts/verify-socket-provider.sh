#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

swiftc \
  -package-name CodexLobsterIsland \
  -framework Network \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexState.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexProviderKind.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexProviderInspectable.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexTask.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Domain/CodexStatusProviding.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Services/CodexLogEventParser.swift" \
  "$ROOT/Sources/CodexLobsterIsland/Services/SocketEventCodexProvider.swift" \
  "$ROOT/scripts/verify-socket-provider.swift" \
  -o "$TMP_DIR/verify-socket-provider"

"$TMP_DIR/verify-socket-provider"
