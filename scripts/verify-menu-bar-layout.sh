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

check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" ".frame(width: 248)" "菜单栏弹层宽度应收窄到 248"
check_contains "Sources/CodexLobsterIsland/App/CodexLobsterIslandApp.swift" ".menuBarExtraStyle(.window)" "菜单栏弹层应使用 window 风格以避免点击后自动消失"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" ".lineLimit(1)" "菜单栏摘要应压成单行截断"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "Divider()" "菜单栏分组应改用分隔线而不是层层卡片"
check_contains "Sources/CodexLobsterIsland/UI/Interaction/InteractiveFeedbackRow.swift" "var isCompact = false" "交互反馈行应支持紧凑模式"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "isCompact: true" "菜单栏里的交互行应启用紧凑模式"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "@State private var isProviderListExpanded = false" "菜单栏应使用本地展开状态管理来源列表"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "ForEach(CodexProviderKind.allCases)" "菜单栏应直接渲染可点击的来源选项列表"
check_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "providerKind = kind" "来源选项点击后应直接更新设置"
check_not_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "Text(statusService.currentTask.detail)" "菜单栏主区域不应直接显示完整任务详情"
check_not_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "Text(statusService.providerStatusDetail)" "菜单栏主区域不应直接显示完整来源详情"
check_not_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" ".background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 18, style: .continuous))" "菜单栏不应继续使用大块头部卡片背景"
check_not_contains "Sources/CodexLobsterIsland/UI/MenuBar/MenuBarStatusView.swift" "Menu {" "状态来源不应继续使用嵌套 Menu"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi

echo "Menu bar layout checks passed."
