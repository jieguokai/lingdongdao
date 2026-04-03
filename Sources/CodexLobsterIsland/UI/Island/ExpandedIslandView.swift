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
        let currentSessionID = statusService.currentProviderSession?.id
        let providerSessions = Array(
            statusService.recentProviderSessions
                .filter { $0.id != currentSessionID }
                .prefix(3)
        )

        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    heroCard(accentColor: accentColor)

                    if let currentSession = statusService.currentProviderSession {
                        sessionCard(
                            title: "当前会话",
                            subtitle: statusService.providerConnectionLabel ?? "真实 Codex 会话",
                            session: currentSession,
                            accentColor: accentColor,
                            emphasize: true
                        )
                    } else {
                        providerCard(accentColor: accentColor)
                    }
                }
                .frame(width: 292, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 12) {
                    if !providerSessions.isEmpty {
                        groupedCard(title: "最近会话", subtitle: "最近 3 次桥接会话") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(providerSessions) { session in
                                    sessionRow(session: session, accentColor: accentColor)
                                }
                            }
                        }
                    }

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
                        }
                    }

                    if statusService.canManuallyTransition {
                        groupedCard(title: "调试状态", subtitle: "仅预览模式可见") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
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
                                }

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
                }
                .frame(width: 238, alignment: .topLeading)
            }
            .padding(.vertical, 2)
        }
        .frame(width: AppConstants.expandedIslandSize.width - 36, height: AppConstants.expandedIslandSize.height - 36, alignment: .topLeading)
    }

    private func heroCard(accentColor: Color) -> some View {
        let timestampOpacity = interactionPhase == .hovered ? 0.86 : 0.74

        return groupedCard(title: "Codex Lobster Island", subtitle: statusService.currentState.subtitle, accentColor: accentColor, compactHeader: true) {
            HStack(alignment: .top, spacing: 14) {
                LobsterAvatarView(
                    state: statusService.currentState,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase,
                    contentPadding: 6
                )
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        StateLabelPill(state: statusService.currentState, text: statusService.currentState.dynamicIslandTitle)
                        Spacer(minLength: 8)
                        Text(statusService.lastUpdatedAt.shortRelativeString)
                            .font(.caption2)
                            .foregroundStyle(IslandStyle.tertiaryText.opacity(timestampOpacity))
                        Button {
                            onToggleExpanded()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 20, height: 20)
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(IslandStyle.primaryText)
                        .lineLimit(2)

                    Text(statusService.currentTask.detail)
                        .font(.caption)
                        .foregroundStyle(IslandStyle.secondaryText)
                        .lineLimit(3)

                    VStack(alignment: .leading, spacing: 6) {
                        MetaChip(icon: "dot.radiowaves.left.and.right", text: statusService.providerStatusSummary, accentColor: accentColor)
                        if let connectionLabel = statusService.providerConnectionLabel {
                            MetaChip(icon: "link", text: connectionLabel, accentColor: accentColor)
                        }
                    }
                }
            }
        }
    }

    private func providerCard(accentColor: Color) -> some View {
        groupedCard(title: "状态来源", subtitle: statusService.providerStatusSummary) {
            VStack(alignment: .leading, spacing: 10) {
                providerLine(icon: "dot.radiowaves.left.and.right", title: statusService.providerStatusSummary, detail: statusService.providerStatusDetail)

                if let connectionLabel = statusService.providerConnectionLabel {
                    providerLine(icon: "link", title: connectionLabel, detail: statusService.providerConnectionDetail)
                }

                if let providerError = statusService.lastProviderError {
                    warningLine(providerError)
                }

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

    private func sessionCard(
        title: String,
        subtitle: String,
        session: CodexProviderSessionSummary,
        accentColor: Color,
        emphasize: Bool
    ) -> some View {
        groupedCard(title: title, subtitle: subtitle, accentColor: emphasize ? accentColor : nil) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    StateLabelPill(state: session.state, text: session.phaseLabel)
                    Text(session.displayCommand)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(IslandStyle.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(session.timestamp.shortRelativeString)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)
                }

                Text(session.primarySummary)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(4)

                sessionDetailGrid(session: session)

                if let errorSummary = session.errorSummary {
                    warningLine(errorSummary)
                }

                Button("复制最近会话诊断") {
                    copyToPasteboard(session.diagnosticLine)
                }
                .foregroundStyle(IslandStyle.primaryText)
                .buttonStyle(
                    InteractiveButtonStyle(
                        prominence: .subtle,
                        accentColor: accentColor,
                        cornerRadius: 12,
                        fillOpacity: 0.08,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private func sessionRow(session: CodexProviderSessionSummary, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                StateLabelPill(state: session.state, text: session.phaseLabel)
                Text(session.displayCommand)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(session.timestamp.shortRelativeString)
                    .font(.caption2)
                    .foregroundStyle(IslandStyle.tertiaryText)
            }

            Text(session.primarySummary)
                .font(.caption)
                .foregroundStyle(IslandStyle.secondaryText)
                .lineLimit(2)

            sessionDetailGrid(session: session, compact: true)

            if let errorSummary = session.errorSummary {
                warningLine(errorSummary)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(IslandStyle.cardFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(IslandStyle.cardAccentWash(for: session.state).opacity(0.45))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(IslandStyle.cardStroke, lineWidth: 0.8)
                }
        )
    }

    private func sessionDetailGrid(session: CodexProviderSessionSummary, compact: Bool = false) -> some View {
        let font = compact ? Font.caption2 : Font.caption
        let secondaryFont = compact ? Font.caption2 : Font.caption2

        return VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            detailLine(label: "线程", value: session.threadID, font: font, valueFont: .caption2.monospaced(), compact: compact)

            if let usageSummary = session.usageSummary {
                detailLine(label: "Usage", value: usageSummary, font: font, valueFont: secondaryFont, compact: compact)
            }

            if let exitCode = session.exitCode {
                detailLine(label: "退出", value: "exit \(exitCode)", font: font, valueFont: secondaryFont, compact: compact)
            }
        }
    }

    private func detailLine(label: String, value: String, font: Font, valueFont: Font, compact: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(font.weight(.semibold))
                .foregroundStyle(IslandStyle.quaternaryText)
                .frame(width: compact ? 28 : 32, alignment: .leading)
            Text(value)
                .font(valueFont)
                .foregroundStyle(IslandStyle.tertiaryText)
                .lineLimit(1)
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
