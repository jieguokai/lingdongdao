import SwiftUI

struct ExpandedIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    var body: some View {
        let state = statusService.currentState
        let accentColor = IslandStyle.accent(for: state)
        let historyEntries = Array(statusService.history.prefix(5))
        let rowHeight: CGFloat = statusService.canManuallyTransition ? 208 : 244

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    currentStatusCard(accentColor: accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    statusSourceCard(accentColor: accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    recentStatusCard(historyEntries: historyEntries)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(height: rowHeight)

                if statusService.canManuallyTransition {
                    debugControlsCard(accentColor: accentColor)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(width: AppConstants.expandedIslandSize.width - 36, height: AppConstants.expandedIslandSize.height - 36, alignment: .topLeading)
    }

    private func currentStatusCard(accentColor: Color) -> some View {
        let timestampOpacity = interactionPhase == .hovered ? 0.86 : 0.74

        return groupedCard(title: "当前状态", subtitle: statusService.currentState.subtitle, accentColor: accentColor, compactHeader: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    LobsterAvatarView(
                        state: statusService.currentState,
                        animationsEnabled: settingsStore.settings.animationsEnabled,
                        interactionPhase: interactionPhase,
                        contentPadding: 5
                    )
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .center, spacing: 6) {
                            StateLabelPill(state: statusService.currentState, text: statusService.currentState.dynamicIslandTitle)
                            Spacer(minLength: 4)
                            Text(statusService.lastUpdatedAt.shortRelativeString)
                                .font(.caption2)
                                .foregroundStyle(IslandStyle.tertiaryText.opacity(timestampOpacity))
                            Button {
                                onToggleExpanded()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 18, height: 18)
                            }
                            .foregroundStyle(IslandStyle.secondaryText)
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
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(IslandStyle.primaryText)
                            .lineLimit(2)
                    }
                }

                Text(statusService.currentTask.detail)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(2)

                if let currentSession = statusService.currentProviderSession {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("当前会话")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(IslandStyle.quaternaryText)
                            .tracking(0.5)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            StateLabelPill(state: currentSession.state, text: currentSession.phaseLabel)
                            Text(currentSession.displayCommand)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(IslandStyle.primaryText)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                        }

                        Text(currentSession.primarySummary)
                            .font(.caption2)
                            .foregroundStyle(IslandStyle.secondaryText)
                            .lineLimit(3)

                        if let usageSummary = currentSession.usageSummary {
                            Text(usageSummary)
                                .font(.caption2)
                                .foregroundStyle(IslandStyle.tertiaryText)
                                .lineLimit(1)
                        }

                        if let errorSummary = currentSession.errorSummary {
                            warningLine(errorSummary)
                        }
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    MetaChip(icon: "dot.radiowaves.left.and.right", text: statusService.providerStatusSummary, accentColor: accentColor)
                    if let connectionLabel = statusService.providerConnectionLabel {
                        MetaChip(icon: "link", text: connectionLabel, accentColor: accentColor)
                    }
                }
            }
        }
    }

    private func statusSourceCard(accentColor: Color) -> some View {
        groupedCard(title: "状态来源", subtitle: statusService.providerStatusSummary) {
            VStack(alignment: .leading, spacing: 10) {
                providerLine(icon: "dot.radiowaves.left.and.right", title: statusService.providerStatusSummary, detail: statusService.providerStatusDetail)

                if let connectionLabel = statusService.providerConnectionLabel {
                    providerLine(icon: "link", title: connectionLabel, detail: statusService.providerConnectionDetail)
                }

                if let providerError = statusService.lastProviderError {
                    warningLine(providerError)
                }

                Spacer(minLength: 0)

                Button("复制最近会话诊断") {
                    copyToPasteboard(statusService.providerDiagnosticsText)
                }
                .foregroundStyle(IslandStyle.primaryText)
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

    private func recentStatusCard(historyEntries: [StatusHistoryEntry]) -> some View {
        groupedCard(title: "最近状态", subtitle: "状态流转记录") {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(historyEntries) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        CompactStateMark(state: entry.state, size: 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.state.dynamicIslandTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(IslandStyle.primaryText)
                            Text(entry.taskTitle)
                                .font(.caption2)
                                .foregroundStyle(IslandStyle.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        Text(entry.timestamp.shortRelativeString)
                            .font(.caption2)
                            .foregroundStyle(IslandStyle.tertiaryText)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func debugControlsCard(accentColor: Color) -> some View {
        groupedCard(title: "调试状态", subtitle: "仅预览模式可见") {
            HStack(spacing: 8) {
                ForEach(CodexState.allCases, id: \.self) { manualState in
                    Button(manualState.displayName) {
                        statusService.setPreviewState(manualState)
                    }
                    .foregroundStyle(IslandStyle.primaryText)
                    .buttonStyle(
                        InteractiveButtonStyle(
                            prominence: .subtle,
                            accentColor: IslandStyle.accent(for: manualState),
                            cornerRadius: 12,
                            fillOpacity: 0.08,
                            animationsEnabled: settingsStore.settings.animationsEnabled
                        )
                    )
                }

                Spacer(minLength: 8)

                Button("下一个状态") {
                    statusService.advance()
                }
                .foregroundStyle(IslandStyle.primaryText)
                .buttonStyle(
                    InteractiveButtonStyle(
                        prominence: .secondary,
                        accentColor: accentColor,
                        cornerRadius: 12,
                        fillOpacity: 0.12,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private func providerLine(icon: String, title: String, detail: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(IslandStyle.tertiaryText)
                .frame(width: 12, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.primaryText)
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.secondaryText)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func warningLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.orange.opacity(0.92))
                .lineLimit(3)
                .textSelection(.enabled)
        }
    }

    private func groupedCard<Content: View>(
        title: String,
        subtitle: String,
        accentColor: Color? = nil,
        compactHeader: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: compactHeader ? 12 : 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(IslandStyle.quaternaryText)
                    .tracking(0.8)
                Text(subtitle)
                    .font(compactHeader ? .caption.weight(.semibold) : .caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(compactHeader ? 2 : 2)
            }

            content()
        }
        .padding(compactHeader ? 14 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: compactHeader ? 24 : 20, style: .continuous)
                .fill(IslandStyle.cardFill)
                .overlay {
                    RoundedRectangle(cornerRadius: compactHeader ? 24 : 20, style: .continuous)
                        .fill(IslandStyle.cardAccentWash(for: statusService.currentState).opacity(accentColor == nil ? 0.18 : 0.34))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: compactHeader ? 24 : 20, style: .continuous)
                        .strokeBorder(IslandStyle.cardStroke, lineWidth: 0.9)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: compactHeader ? 24 : 20, style: .continuous)
                        .strokeBorder(IslandStyle.cardInnerStroke, lineWidth: 0.6)
                        .padding(1.4)
                }
        )
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

private struct CompactStateMark: View {
    let state: CodexState
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(IslandStyle.statusDotFill(for: state))
            .frame(width: size, height: size)
            .shadow(color: IslandStyle.accent(for: state).opacity(0.45), radius: 4)
    }
}

private struct StateLabelPill: View {
    let state: CodexState
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            CompactStateMark(state: state, size: 8)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(IslandStyle.primaryText)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(IslandStyle.microChipFill(for: state))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(IslandStyle.microChipStroke(for: state), lineWidth: 0.8)
                }
        )
    }
}

private struct MetaChip: View {
    let icon: String
    let text: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(IslandStyle.secondaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(accentColor.opacity(0.10))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(accentColor.opacity(0.18), lineWidth: 0.75)
                }
        )
    }
}
