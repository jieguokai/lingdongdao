#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

check_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! rg -n -F "$pattern" "$file" >/dev/null; then
    echo "FAIL: $message"
    failures=$((failures + 1))
  fi
}

check_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if rg -n -F "$pattern" "$file" >/dev/null; then
    echo "FAIL: $message"
    failures=$((failures + 1))
  fi
}

check_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" "ScrollView(.vertical, showsIndicators: true)" "最近状态列表应支持纵向滚动"
check_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".frame(maxHeight: statusService.canManuallyTransition ? 108 : 144)" "最近状态滚动区应有固定最大高度"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" "prefix(4)" "最近状态列表不应继续截断为前四条"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi

echo "Expanded history scroll checks passed."
