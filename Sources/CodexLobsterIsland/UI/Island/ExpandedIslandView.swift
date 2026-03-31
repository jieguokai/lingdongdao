import SwiftUI

struct ExpandedIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    var body: some View {
        let accentColor = tintColor(for: statusService.currentState)
        let titleOffset = interactionPhase == .pressed ? 0.8 : 0.0
        let timestampOpacity = interactionPhase == .hovered ? 0.86 : 0.70
        let historyEntries = Array(statusService.history)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                LobsterAvatarView(
                    state: statusService.currentState,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase
                )
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center, spacing: 8) {
                        StatusBadgeView(
                            state: statusService.currentState,
                            compact: true,
                            interactionPhase: interactionPhase,
                            animationsEnabled: settingsStore.settings.animationsEnabled
                        )
                        Spacer()
                        TimestampLabel(date: statusService.lastUpdatedAt)
                            .foregroundStyle(.white.opacity(timestampOpacity))
                            .animation(.easeOut(duration: 0.18), value: interactionPhase)
                        Button {
                            onToggleExpanded()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                                .frame(width: 18, height: 18)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .buttonStyle(
                            InteractiveButtonStyle(
                                prominence: .subtle,
                                accentColor: .white,
                                cornerRadius: 999,
                                fillOpacity: 0.06,
                                animationsEnabled: settingsStore.settings.animationsEnabled
                            )
                        )
                    }

                    Text(statusService.currentTask.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.97))
                        .offset(y: titleOffset)
                        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: interactionPhase)

                    Text(statusService.currentTask.detail)
                        .font(.callout)
                        .foregroundStyle(IslandStyle.secondaryText)
                        .lineLimit(2)
                        .offset(y: titleOffset * 0.5)
                        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: interactionPhase)
                }
            }
            .padding(.bottom, 14)

            sectionDivider
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("状态来源")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.tertiaryText)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(IslandStyle.tertiaryText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusService.providerStatusSummary)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.92))
                        Text(statusService.providerStatusDetail)
                            .font(.caption)
                            .foregroundStyle(IslandStyle.tertiaryText)
                            .textSelection(.enabled)
                    }
                }

                if let providerError = statusService.lastProviderError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(providerError)
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.90))
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)

            sectionDivider
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("最近状态")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.tertiaryText)

                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(historyEntries.enumerated()), id: \.element.id) { index, entry in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                StatusBadgeView(state: entry.state, compact: true)
                                    .frame(minWidth: 60, alignment: .leading)
                                Text(entry.taskTitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.90))
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text(entry.timestamp.shortRelativeString)
                                    .font(.caption2)
                                    .foregroundStyle(IslandStyle.tertiaryText)
                            }

                            if index < historyEntries.count - 1 {
                                sectionDivider
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: statusService.canManuallyTransition ? 108 : 144)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .padding(.bottom, statusService.canManuallyTransition ? 8 : 0)

            if statusService.canManuallyTransition {
                sectionDivider
                    .padding(.bottom, 10)

                HStack(spacing: 8) {
                    ForEach(CodexState.allCases, id: \.self) { state in
                        Button(state.displayName) {
                            statusService.setPreviewState(state)
                        }
                        .foregroundStyle(.white.opacity(0.86))
                        .buttonStyle(
                            InteractiveButtonStyle(
                                prominence: .subtle,
                                accentColor: tintColor(for: state),
                                cornerRadius: 12,
                                fillOpacity: 0.08,
                                animationsEnabled: settingsStore.settings.animationsEnabled
                            )
                        )
                    }

                    Spacer()

                    Button("下一个") {
                        statusService.advance()
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .buttonStyle(
                        InteractiveButtonStyle(
                            prominence: .secondary,
                            accentColor: accentColor,
                            cornerRadius: 12,
                            fillOpacity: 0.10,
                            animationsEnabled: settingsStore.settings.animationsEnabled
                        )
                    )
                }
            }
        }
        .frame(width: AppConstants.expandedIslandSize.width - 36, height: AppConstants.expandedIslandSize.height - 36, alignment: .topLeading)
    }

    private func tintColor(for state: CodexState) -> Color {
        IslandStyle.accent(for: state)
    }

    private var sectionDivider: some View {
        Rectangle().fill(IslandStyle.separator)
            .frame(height: 1)
            .opacity(0.9)
    }
}
