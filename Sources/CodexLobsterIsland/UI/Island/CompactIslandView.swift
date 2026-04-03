import SwiftUI

struct CompactIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    var body: some View {
        let state = statusService.currentState
        let headlineOpacity = interactionPhase == .hovered ? 0.98 : 0.94
        let headlineOffset = interactionPhase == .pressed ? 0.35 : 0.0
        let accessoryOpacity = interactionPhase == .hovered ? 0.92 : 0.76
        let statusScale = interactionPhase == .hovered ? 1.08 : 1.0

        Button(action: onToggleExpanded) {
            HStack(spacing: 10) {
                LobsterAvatarView(
                    state: state,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase,
                    contentPadding: 4
                )
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 0) {
                    Text(state.dynamicIslandTitle)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(IslandStyle.primaryText.opacity(headlineOpacity))
                        .tracking(-0.15)
                        .lineLimit(1)
                        .offset(y: headlineOffset)
                        .animation(.spring(response: 0.22, dampingFraction: 0.80), value: interactionPhase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if let accessoryLabel {
                        Text(accessoryLabel)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(IslandStyle.secondaryText.opacity(accessoryOpacity))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(IslandStyle.microChipFill(for: state))
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(IslandStyle.microChipStroke(for: state), lineWidth: 0.8)
                                    }
                            )
                            .lineLimit(1)
                    }

                    Circle()
                        .fill(IslandStyle.statusDotFill(for: state))
                        .frame(width: 8, height: 8)
                        .scaleEffect(statusScale)
                        .shadow(color: IslandStyle.accent(for: state).opacity(0.48), radius: 5)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(IslandStyle.quaternaryText.opacity(interactionPhase == .hovered ? 0.9 : 0.72))
                }
            }
            .padding(.horizontal, 9)
            .frame(width: AppConstants.compactIslandSize.width - 8, height: AppConstants.compactIslandSize.height - 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accessoryLabel: String? {
        if let session = statusService.currentProviderSession {
            return session.displayCommand
        }

        if let connectionLabel = statusService.providerConnectionLabel {
            return connectionLabel
        }

        return nil
    }
}
