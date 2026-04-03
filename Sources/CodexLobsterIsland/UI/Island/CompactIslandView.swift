import SwiftUI

struct CompactIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    var isExpanded: Bool = false
    let onToggleExpanded: () -> Void

    var body: some View {
        let state = statusService.currentState
        let statusScale = interactionPhase == .hovered ? 1.08 : 1.0

        Button(action: onToggleExpanded) {
            HStack(spacing: 7) {
                LobsterAvatarView(
                    state: state,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase,
                    contentPadding: 2
                )
                .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 0) {
                    Text(state.dynamicIslandTitle)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(IslandStyle.compactTitleText)
                        .lineLimit(1)
                        .animation(.spring(response: 0.22, dampingFraction: 0.80), value: interactionPhase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 7) {
                    Circle()
                        .fill(IslandStyle.statusDotFill(for: state))
                        .frame(width: 7, height: 7)
                        .scaleEffect(statusScale)
                        .shadow(color: IslandStyle.accent(for: state).opacity(0.48), radius: 5)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(IslandStyle.quaternaryText.opacity(interactionPhase == .hovered ? 0.9 : 0.72))
                }
            }
            .padding(.horizontal, 14)
            .frame(width: AppConstants.compactIslandSize.width, height: AppConstants.compactIslandSize.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
