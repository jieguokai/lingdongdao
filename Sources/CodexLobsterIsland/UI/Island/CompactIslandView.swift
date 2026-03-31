import SwiftUI

struct CompactIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    var body: some View {
        let titleOpacity = interactionPhase == .hovered ? 0.98 : 0.92
        let titleOffset = interactionPhase == .pressed ? 0.6 : 0.0
        let badgeOpacity = interactionPhase == .hovered ? 0.88 : 0.74
        let chevronOpacity = interactionPhase == .hovered ? 0.56 : 0.38

        Button(action: onToggleExpanded) {
            HStack(spacing: 10) {
                LobsterAvatarView(
                    state: statusService.currentState,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase,
                    contentPadding: 3
                )
                .frame(width: 34, height: 34)

                Text(statusService.currentState.dynamicIslandTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(titleOpacity))
                    .tracking(-0.2)
                    .lineLimit(1)
                    .offset(y: titleOffset)
                    .animation(.spring(response: 0.24, dampingFraction: 0.78), value: interactionPhase)

                Spacer(minLength: 0)

                StatusBadgeView(
                    state: statusService.currentState,
                    compact: true,
                    interactionPhase: interactionPhase,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                )
                    .opacity(badgeOpacity)
                    .animation(.easeOut(duration: 0.16), value: interactionPhase)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(chevronOpacity))
                    .animation(.easeOut(duration: 0.16), value: interactionPhase)
            }
            .frame(width: AppConstants.compactIslandSize.width - 10, height: AppConstants.compactIslandSize.height - 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
