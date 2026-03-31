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

check_count() {
  local file="$1"
  local pattern="$2"
  local expected="$3"
  local message="$4"
  local actual

  actual="$(rg -F -c "$pattern" "$file" || true)"
  if [[ -z "$actual" ]]; then
    actual="0"
  fi
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $message"
    failures=$((failures + 1))
  fi
}

check_contains "Sources/CodexLobsterIsland/Helpers/AppConstants.swift" "static let compactIslandSize = CGSize(width: 380, height: 42)" "紧凑态高度应为 42"
check_contains "Sources/CodexLobsterIsland/UI/Island/CompactIslandView.swift" ".frame(width: 34, height: 34)" "紧凑态龙虾应放大到 34x34"
check_contains "Sources/CodexLobsterIsland/UI/Island/CompactIslandView.swift" "Text(statusService.currentState.dynamicIslandTitle)" "紧凑态应显示系统式短句"
check_contains "Sources/CodexLobsterIsland/UI/Shared/StatusBadgeView.swift" "Label(state.displayName, systemImage: state.symbolName)" "右侧状态胶囊应保留图标和文字"
check_contains "Sources/CodexLobsterIsland/Domain/CodexState.swift" "var dynamicIslandTitle: String" "状态模型应提供 Dynamic Island 短句"
check_contains "Sources/CodexLobsterIsland/UI/Island/IslandStyle.swift" "AnyShapeStyle(.ultraThinMaterial)" "浮动岛主体应使用通知风格材质"
check_contains "Sources/CodexLobsterIsland/UI/Island/IslandStyle.swift" "static var edgeHighlight: LinearGradient" "浮动岛边缘应使用柔和高光描边"
check_contains "Sources/CodexLobsterIsland/Services/FloatingIslandWindowManager.swift" "panel.hasShadow = false" "浮动岛窗口应关闭原生矩形阴影"
check_contains "Sources/CodexLobsterIsland/Services/FloatingIslandWindowManager.swift" "controller.view.layer?.backgroundColor = NSColor.clear.cgColor" "宿主视图背景应显式透明"
check_contains "Sources/CodexLobsterIsland/Services/FloatingIslandWindowManager.swift" "panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor" "窗口内容视图背景应显式透明"
check_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".clipShape(islandShape)" "浮动岛根视图应裁成圆角形状"
check_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".compositingGroup()" "浮动岛阴影前应先做图层合成"
check_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".fill(.ultraThinMaterial)" "浮动岛根视图应改为毛玻璃材质"
check_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".strokeBorder(IslandStyle.edgeHighlight, lineWidth: 0.85)" "浮动岛应使用系统通知风格的柔和描边"
check_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".padding(.horizontal, 8)" "展开态内卡片应和外层边缘拉开间距"
check_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".padding(.bottom, 4)" "最近状态卡片底部应和外层边缘拉开间距"
check_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" "Rectangle().fill(IslandStyle.separator)" "展开态应使用分隔线而不是多层卡片底板"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".shadow(color: IslandStyle.glow(for: state), radius: 14, y: 4)" "浮动岛不应保留外层状态发光阴影"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".shadow(color: .black.opacity(0.32), radius: 30, y: 16)" "浮动岛不应保留底部黑色投影阴影"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".interactiveSurface(" "浮动岛根视图不应继续使用高光炫彩交互外壳"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/CompactIslandView.swift" "Text(statusService.currentTask.detail)" "紧凑态不应显示第二行详情"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/CompactIslandView.swift" "Text(statusService.currentTask.title)" "紧凑态不应继续显示真实任务标题"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/FloatingIslandRootView.swift" ".strokeBorder(.white.opacity(0.08), lineWidth: 1)" "浮动岛外层白色描边应被删除"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".buttonStyle(.borderedProminent)" "展开态不应继续使用 borderedProminent 风格"
check_not_contains "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".buttonStyle(.bordered)" "展开态不应使用带白边的 bordered 按钮样式"
check_not_contains "Sources/CodexLobsterIsland/UI/Shared/LobsterAvatarView.swift" "Circle()" "小龙虾下方不应保留单独的发光底盘"
check_not_contains "Sources/CodexLobsterIsland/UI/Shared/StatusBadgeView.swift" ".background(" "右侧状态区不应保留胶囊或色块背景"
check_count "Sources/CodexLobsterIsland/UI/Island/ExpandedIslandView.swift" ".background(IslandStyle.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))" "0" "展开态不应再保留独立卡片底板"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi

echo "Compact island layout checks passed."
