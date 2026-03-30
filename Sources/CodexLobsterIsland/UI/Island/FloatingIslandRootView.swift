import SwiftUI

struct FloatingIslandRootView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    var body: some View {
        let state = statusService.currentState

        Group {
            if isExpanded {
                ExpandedIslandView(
                    statusService: statusService,
                    settingsStore: settingsStore,
                    onToggleExpanded: onToggleExpanded
                )
            } else {
                CompactIslandView(
                    statusService: statusService,
                    settingsStore: settingsStore,
                    onToggleExpanded: onToggleExpanded
                )
            }
        }
        .padding(isExpanded ? 18 : 12)
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? 28 : 26, style: .continuous)
                .fill(IslandStyle.background(for: state))
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 28 : 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: IslandStyle.glow(for: state), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.32), radius: 30, y: 16)
        .contentShape(RoundedRectangle(cornerRadius: isExpanded ? 28 : 26, style: .continuous))
    }
}
