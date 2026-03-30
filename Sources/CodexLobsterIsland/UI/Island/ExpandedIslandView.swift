import SwiftUI

struct ExpandedIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let onToggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                LobsterAvatarView(
                    state: statusService.currentState,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                )
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadgeView(state: statusService.currentState)
                        Spacer()
                        Button {
                            onToggleExpanded()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(8)
                                .background(.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(statusService.currentTask.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(statusService.currentTask.detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))

                    TimestampLabel(date: statusService.lastUpdatedAt)
                }
            }

            if statusService.canManuallyTransition {
                HStack(spacing: 8) {
                    ForEach(CodexState.allCases, id: \.self) { state in
                        Button(state.displayName) {
                            statusService.setPreviewState(state)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(tintColor(for: state))
                        .controlSize(.small)
                    }

                    Spacer()

                    Button("Next") {
                        statusService.advance()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Source")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusService.providerStatusSummary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(statusService.providerStatusDetail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                            .textSelection(.enabled)
                    }
                }

                if let providerError = statusService.lastProviderError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(providerError)
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.92))
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(12)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent States")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                ForEach(statusService.history.prefix(4)) { entry in
                    HStack {
                        StatusBadgeView(state: entry.state, compact: true)
                        Text(entry.taskTitle)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(entry.timestamp.shortRelativeString)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
            }
            .padding(12)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .frame(width: AppConstants.expandedIslandSize.width - 36, height: AppConstants.expandedIslandSize.height - 36, alignment: .topLeading)
    }

    private func tintColor(for state: CodexState) -> Color {
        switch state {
        case .idle:
            .blue
        case .running:
            .teal
        case .success:
            .green
        case .error:
            .red
        }
    }
}
