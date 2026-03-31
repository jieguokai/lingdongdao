#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$ROOT/Sources/CodexLobsterIsland/Services/AppUpdateService.swift" ]]
[[ -f "$ROOT/Sources/CodexLobsterIsland/Services/SparkleAppUpdateDriver.swift" ]]

grep -q '检查更新' "$ROOT/Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift"
grep -q '自动检查更新' "$ROOT/Sources/CodexLobsterIsland/UI/Settings/SettingsView.swift"
grep -q 'Sparkle' "$ROOT/Package.swift"

echo "verify-updater-integration passed"
