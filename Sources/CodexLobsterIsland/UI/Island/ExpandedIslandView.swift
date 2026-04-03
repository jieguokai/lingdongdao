import SwiftUI

struct ExpandedIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    var body: some View {
        let historyEntries = Array(statusService.history.prefix(6))

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                summarySection
                sectionDivider

                if let currentSession = statusService.currentProviderSession {
                    sessionSection(currentSession)
                    sectionDivider
                }

                recentStatusSection(historyEntries)
                sectionDivider
                statusSourceSection

                if statusService.canManuallyTransition {
                    sectionDivider
                    debugControlsSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var summarySection: some View {
        HStack(alignment: .top, spacing: 12) {
            LobsterAvatarView(
                state: statusService.currentState,
                animationsEnabled: settingsStore.settings.animationsEnabled,
                interactionPhase: interactionPhase,
                contentPadding: 5
            )
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(statusService.currentState.dynamicIslandTitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(IslandStyle.codexHeaderText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(IslandStyle.microChipFill(for: statusService.currentState))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(IslandStyle.microChipStroke(for: statusService.currentState), lineWidth: 0.8)
                                }
                        )

                    Text(realtimeHint)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(statusService.lastUpdatedAt.shortRelativeString)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)

                    Button {
                        onToggleExpanded()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IslandStyle.secondaryText)
                }

                Text(statusService.currentTask.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(IslandStyle.primaryText)
                    .lineLimit(2)

                Text(statusService.currentTask.detail)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(3)
            }
        }
    }

    private func sessionSection(_ session: CodexProviderSessionSummary) -> some View {
        codexSection(title: "当前会话", subtitle: session.displayCommand) {
            VStack(alignment: .leading, spacing: 10) {
                detailRow("阶段", value: session.phaseLabel, accent: true)
                detailRow("摘要", value: session.primarySummary, multiline: true)

                if let usageSummary = session.usageSummary {
                    detailRow("用量", value: usageSummary)
                }

                detailRow("线程", value: session.threadID)

                if let errorSummary = session.errorSummary {
                    detailRow("错误", value: errorSummary, multiline: true, isError: true)
                }
            }
        }
    }

    private func recentStatusSection(_ entries: [StatusHistoryEntry]) -> some View {
        codexSection(title: "最近状态", subtitle: "状态流转记录") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entries) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        CompactStateMark(state: entry.state, size: 8)

                        VStack(alignment: .leading, spacing: 2) {
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
    }

    private var statusSourceSection: some View {
        codexSection(title: "状态来源", subtitle: statusService.providerStatusSummary) {
            VStack(alignment: .leading, spacing: 10) {
                detailRow("来源", value: statusService.providerStatusDetail, multiline: true)

                if let connectionLabel = statusService.providerConnectionLabel {
                    detailRow("连接", value: connectionLabel)
                }

                if let connectionDetail = statusService.providerConnectionDetail {
                    detailRow("说明", value: connectionDetail, multiline: true)
                }

                if let providerError = statusService.lastProviderError {
                    detailRow("诊断", value: providerError, multiline: true, isError: true)
                }

                Button("复制最近会话诊断") {
                    copyToPasteboard(statusService.providerDiagnosticsText)
                }
                .foregroundStyle(IslandStyle.primaryText)
                .buttonStyle(
                    InteractiveButtonStyle(
                        prominence: .secondary,
                        accentColor: IslandStyle.accent(for: statusService.currentState),
                        cornerRadius: 12,
                        fillOpacity: 0.08,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private var debugControlsSection: some View {
        codexSection(title: "调试状态", subtitle: "仅预览模式可见") {
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
                            fillOpacity: 0.07,
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
                        accentColor: IslandStyle.accent(for: statusService.currentState),
                        cornerRadius: 12,
                        fillOpacity: 0.10,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private func codexSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(IslandStyle.quaternaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(1)
            }

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(IslandStyle.codexSectionFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(IslandStyle.codexSectionStroke, lineWidth: 0.75)
                }
        )
    }

    private func detailRow(
        _ label: String,
        value: String,
        accent: Bool = false,
        multiline: Bool = false,
        isError: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(IslandStyle.quaternaryText)
                .frame(width: 30, alignment: .leading)

            Text(value)
                .font(multiline ? .caption : .caption2)
                .foregroundStyle(detailColor(accent: accent, isError: isError))
                .lineLimit(multiline ? 4 : 1)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    private func detailColor(accent: Bool, isError: Bool) -> some ShapeStyle {
        if isError {
            return AnyShapeStyle(Color.orange.opacity(0.94))
        }
        if accent {
            return AnyShapeStyle(IslandStyle.primaryText)
        }
        return AnyShapeStyle(IslandStyle.secondaryText)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(IslandStyle.codexSectionSeparator)
            .frame(height: 1)
    }

    private var realtimeHint: String {
        if statusService.providerKind == .codexCLI {
            return statusService.isProviderConnected ? "bridge 实时同步中" : "等待 bridge 事件"
        }
        return "当前来源不是实时 bridge"
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
