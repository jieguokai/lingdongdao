import AppKit
import SwiftUI

struct ExpandedIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    let onToggleExpanded: () -> Void

    @State private var approvalActionInFlightID: String?
    @State private var approvalActionError: String?

    private enum SectionEmphasis {
        case plain
        case elevated
        case accent
    }

    var body: some View {
        let currentThreadTurns = statusService.currentThreadTurns
        let displayState = statusService.effectiveDisplayState

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                summarySection
                sectionDivider

                if let currentSession = statusService.currentProviderSession {
                    sessionSection(currentSession)
                    sectionDivider
                }

                if displayState == .awaitingApproval || statusService.currentApprovalReason != nil {
                    approvalSection
                    sectionDivider
                }

                recentStatusSection(currentThreadTurns)

                if !statusService.recentThreadSessions.isEmpty {
                    sectionDivider
                    recentThreadsSection(statusService.recentThreadSessions)
                }

                sectionDivider
                statusSourceSection

                if statusService.canPreviewStates {
                    sectionDivider
                    debugControlsSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var summarySection: some View {
        return HStack(alignment: .top, spacing: 12) {
            LobsterAvatarView(
                state: statusService.effectiveDisplayState,
                animationsEnabled: settingsStore.settings.animationsEnabled,
                interactionPhase: interactionPhase,
                contentPadding: 2
            )
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 8) {
                Text(statusService.effectiveDisplayTask.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(IslandStyle.primaryText)
                    .lineLimit(2)

                Text(statusSummaryText)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(3)
            }

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
        .padding(.bottom, 14)
    }

    private func sessionSection(_ session: CodexProviderSessionSummary) -> some View {
        codexSection(title: "当前线程", subtitle: session.threadTitle ?? session.detail) {
            VStack(alignment: .leading, spacing: 10) {
                detailRow("阶段", value: session.livePhaseLabel, accent: true)
                detailRow("摘要", value: session.primarySummary, multiline: true)
                detailRow("命令", value: session.displayCommand)

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

    private var approvalSection: some View {
        codexSection(
            title: statusService.currentActionPanelTitle,
            subtitle: statusService.currentActionPanelSubtitle,
            emphasis: statusService.shouldPromoteNativeActionPanel ? .accent : .elevated
        ) {
            VStack(alignment: .leading, spacing: 10) {
                approvalSummaryBand

                if let currentSession = statusService.currentProviderSession {
                    approvalContextBlock(for: currentSession)
                }

                if let reason = statusService.currentApprovalReason {
                    detailRow("原因", value: reason, accent: true, multiline: true)
                } else {
                    detailRow("状态", value: "当前没有活动确认原因。", multiline: true)
                }

                if statusService.hasNativeApprovalActions {
                    actionButtonsSection
                } else {
                    detailRow(
                        "动作",
                        value: statusService.providerKind == .desktopThread
                            ? "当前桌面对话没有可执行的原生按钮。"
                            : "当前状态没有 bridge 提供的原生按钮。",
                        multiline: true
                    )
                }

                if !statusService.canPerformApprovalActions && statusService.hasNativeApprovalActions {
                    Text(
                        statusService.providerKind == .desktopThread
                            ? "请先把 Codex Desktop 保持在前台，并给 app 辅助功能权限。若再授权屏幕录制，原生确认识别会更稳定。"
                            : "只有从 app 内或兼容 bridge 工作流发起的实时任务，才会提供这里的原生确认按钮。"
                    )
                    .font(.caption)
                    .foregroundStyle(IslandStyle.tertiaryText)
                }

                if let approvalActionError {
                    Text(approvalActionError)
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.94))
                        .lineLimit(3)
                }
            }
        }
    }

    private var approvalSummaryBand: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(statusService.effectiveDisplayState.dynamicIslandTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.primaryText)

                riskBadge

                Spacer(minLength: 8)

                Text(statusService.effectiveDisplayUpdatedAt.shortRelativeString)
                    .font(.caption2)
                    .foregroundStyle(IslandStyle.tertiaryText)
            }

            Text(statusService.effectiveDisplayTask.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(IslandStyle.primaryText)
                .lineLimit(2)

            Text(statusSummaryText)
                .font(.caption)
                .foregroundStyle(IslandStyle.secondaryText)
                .lineLimit(3)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    statusService.shouldPromoteNativeActionPanel
                        ? IslandStyle.approvalSectionFill(for: statusService.effectiveDisplayState)
                        : Color.white.opacity(0.022)
                )
        )
    }

    private func approvalContextBlock(for session: CodexProviderSessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow("命令", value: session.displayCommand, accent: true)
            detailRow("阶段", value: session.livePhaseLabel)
            detailRow("线程", value: session.threadID)

            if let usageSummary = session.usageSummary {
                detailRow("用量", value: usageSummary)
            }

            if let errorSummary = session.errorSummary {
                detailRow("错误", value: errorSummary, multiline: true, isError: true)
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("原生按钮")
                .font(.caption2.weight(.bold))
                .foregroundStyle(IslandStyle.quaternaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(statusService.currentApprovalActions) { action in
                    approvalButton(action)
                }
            }
        }
    }

    private func recentStatusSection(_ entries: [CodexProviderTurnSummary]) -> some View {
        codexSection(title: "当前线程最近 3 轮", subtitle: "状态与摘要") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            CompactStateMark(state: entry.state, size: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.phaseLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(IslandStyle.primaryText)
                                Text(entry.primarySummary)
                                    .font(.caption2)
                                    .foregroundStyle(IslandStyle.secondaryText)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 8)

                            Text(entry.timestamp.shortRelativeString)
                                .font(.caption2)
                                .foregroundStyle(IslandStyle.tertiaryText)
                        }

                        if entry.id != entries.last?.id {
                            Rectangle()
                                .fill(IslandStyle.codexSectionSeparator)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func recentThreadsSection(_ sessions: [CodexProviderSessionSummary]) -> some View {
        codexSection(title: "最近线程", subtitle: "最近 4 个线程") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sessions.prefix(4)) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            CompactStateMark(state: session.state, size: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.threadTitle ?? session.detail)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(IslandStyle.primaryText)
                                Text(session.livePhaseLabel)
                                    .font(.caption2)
                                    .foregroundStyle(IslandStyle.secondaryText)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            Text(session.timestamp.shortRelativeString)
                                .font(.caption2)
                                .foregroundStyle(IslandStyle.tertiaryText)
                        }

                        if session.id != sessions.prefix(4).last?.id {
                            Rectangle()
                                .fill(IslandStyle.codexSectionSeparator)
                                .frame(height: 1)
                        }
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
                    detailRow("连接", value: connectionLabel, accent: statusService.isProviderConnected)
                }

                if let connectionDetail = statusService.providerConnectionDetail {
                    detailRow("说明", value: connectionDetail, multiline: true)
                }

                if let providerError = statusService.lastProviderError {
                    detailRow("诊断", value: providerError, multiline: true, isError: true)
                }

                if statusService.shouldShowBridgeQuickStart {
                    detailRow("兼容说明", value: statusService.bridgeQuickStartDescription, multiline: true)
                }

                if statusService.providerKind == .desktopThread && statusService.canManageDesktopPermissions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("权限操作")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(IslandStyle.quaternaryText)

                        HStack(spacing: 8) {
                            permissionActionButton("请求授权") {
                                statusService.requestDesktopPermissionPrompt()
                            }

                            permissionActionButton("辅助功能") {
                                openPrivacyPane(anchor: "Privacy_Accessibility")
                            }

                            permissionActionButton("重检") {
                                statusService.recheckDesktopPermissions()
                            }
                        }

                        permissionActionButton("打开屏幕录制设置") {
                            openPrivacyPane(anchor: "Privacy_ScreenCapture")
                        }
                    }
                }

                Button("复制最近会话诊断") {
                    copyToPasteboard(statusService.providerDiagnosticsText)
                }
                .foregroundStyle(IslandStyle.primaryText)
                .buttonStyle(
                    InteractiveButtonStyle(
                        prominence: .secondary,
                        accentColor: IslandStyle.accent(for: statusService.effectiveDisplayState),
                        cornerRadius: 12,
                        fillOpacity: 0.07,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private var debugControlsSection: some View {
        codexSection(
            title: "状态预览",
            subtitle: "可手动切换或恢复实时状态",
            emphasis: .elevated
        ) {
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
                            fillOpacity: 0.06,
                            animationsEnabled: settingsStore.settings.animationsEnabled
                        )
                    )
                }

                Spacer(minLength: 8)

                Button("恢复实时") {
                    statusService.clearPreviewState()
                }
                .foregroundStyle(IslandStyle.primaryText)
                .buttonStyle(
                    InteractiveButtonStyle(
                        prominence: .secondary,
                        accentColor: .white.opacity(0.9),
                        cornerRadius: 12,
                        fillOpacity: 0.08,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                )
            }
        }
    }

    private func codexSection<Content: View>(
        title: String,
        subtitle: String,
        emphasis: SectionEmphasis = .plain,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(IslandStyle.codexSectionTitleText)

                Spacer(minLength: 8)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(IslandStyle.secondaryText)
                    .lineLimit(1)
            }

            content()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, emphasis == .plain ? 0 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBackground(for: emphasis))
    }

    @ViewBuilder
    private func sectionBackground(for emphasis: SectionEmphasis) -> some View {
        switch emphasis {
        case .plain:
            EmptyView()
        case .elevated:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(statusService.effectiveDisplayState == .idle ? Color.black : Color.white.opacity(0.016))
        case .accent:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(IslandStyle.approvalSectionFill(for: statusService.effectiveDisplayState))
        }
    }

    private func detailRow(
        _ label: String,
        value: String,
        accent: Bool = false,
        multiline: Bool = false,
        isError: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(IslandStyle.quaternaryText)
                .frame(width: 34, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(multiline ? .caption : .caption2)
                    .foregroundStyle(detailColor(accent: accent, isError: isError))
                    .lineLimit(multiline ? 4 : 1)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
    }

    private func detailColor(accent: Bool, isError: Bool) -> AnyShapeStyle {
        if isError {
            return AnyShapeStyle(Color.orange.opacity(0.94))
        }
        if accent {
            return AnyShapeStyle(IslandStyle.primaryText)
        }
        return AnyShapeStyle(IslandStyle.secondaryText)
    }

    private var sectionDivider: some View {
        Color.clear
            .frame(height: 8)
    }

    private var statusSummaryText: String {
        statusService.effectiveDisplayTask.summary ?? statusService.effectiveDisplayTask.detail
    }

    private func accentColor(for action: CodexApprovalAction) -> Color {
        switch action.role {
        case .approve:
            return Color(.sRGB, red: 0.23, green: 0.77, blue: 0.55, opacity: 1)
        case .reject:
            return Color(.sRGB, red: 0.94, green: 0.42, blue: 0.35, opacity: 1)
        case .neutral:
            return IslandStyle.accent(for: statusService.effectiveDisplayState)
        }
    }

    private func prominence(for action: CodexApprovalAction) -> InteractionProminence {
        switch action.role {
        case .approve:
            return .primary
        case .reject:
            return .secondary
        case .neutral:
            return .subtle
        }
    }

    @ViewBuilder
    private func approvalButton(_ action: CodexApprovalAction) -> some View {
        let buttonStyle = InteractiveButtonStyle(
            prominence: prominence(for: action),
            accentColor: accentColor(for: action),
            cornerRadius: 12,
            fillOpacity: action.role == .approve ? 0.16 : 0.08,
            animationsEnabled: settingsStore.settings.animationsEnabled
        )

        Button(action.label) {
            triggerApprovalAction(action)
        }
        .disabled(approvalActionInFlightID != nil || !statusService.canPerformApprovalActions)
        .foregroundStyle(IslandStyle.primaryText)
        .buttonStyle(buttonStyle)
        .overlay(alignment: .trailing) {
            if approvalActionInFlightID == action.id {
                ProgressView()
                    .controlSize(.small)
                    .tint(IslandStyle.primaryText)
                    .padding(.trailing, 10)
            }
        }
    }

    private var riskBadge: some View {
        Text(statusService.effectiveRiskLevel.displayName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(riskTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(riskFillColor)
            )
    }

    private var riskFillColor: Color {
        switch statusService.effectiveRiskLevel {
        case .low:
            return Color.green.opacity(0.12)
        case .medium:
            return Color.orange.opacity(0.12)
        case .high:
            return Color.red.opacity(0.14)
        }
    }

    private var riskTextColor: Color {
        switch statusService.effectiveRiskLevel {
        case .low:
            return Color.green.opacity(0.9)
        case .medium:
            return Color.orange.opacity(0.92)
        case .high:
            return Color.red.opacity(0.92)
        }
    }

    private func triggerApprovalAction(_ action: CodexApprovalAction) {
        approvalActionInFlightID = action.id
        approvalActionError = nil

        Task {
            do {
                try await statusService.performApprovalAction(action)
                await MainActor.run {
                    approvalActionInFlightID = nil
                }
            } catch {
                await MainActor.run {
                    approvalActionInFlightID = nil
                    approvalActionError = error.localizedDescription
                }
            }
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    @ViewBuilder
    private func permissionActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(
                InteractiveButtonStyle(
                    prominence: .subtle,
                    accentColor: IslandStyle.accent(for: statusService.effectiveDisplayState),
                    cornerRadius: 12,
                    fillOpacity: 0.10,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                )
            )
    }

    private func openPrivacyPane(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
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
