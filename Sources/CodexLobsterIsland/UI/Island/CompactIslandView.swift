import SwiftUI

struct CompactIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let onToggleExpanded: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            LobsterAvatarView(
                state: statusService.currentState,
                animationsEnabled: settingsStore.settings.animationsEnabled
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(statusService.currentTask.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    StatusBadgeView(state: statusService.currentState)
                }
                Text(statusService.currentTask.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: AppConstants.compactIslandSize.width - 24, height: AppConstants.compactIslandSize.height - 24)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleExpanded()
        }
    }
}
