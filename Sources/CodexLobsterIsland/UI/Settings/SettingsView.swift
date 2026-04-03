import AppKit
import SwiftUI

struct SettingsView: View {
    let statusService: CodexStatusService
    let appUpdateService: AppUpdateService
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginManager: LaunchAtLoginManager

    var body: some View {
        let accentColor = IslandStyle.accent(for: statusService.currentState)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PreviewCard(
                    statusService: statusService,
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                )

                SettingsCard(
                    title: "行为",
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                ) { _ in
                    settingsToggleRow("显示浮动岛", binding: toggleBinding(\.showsIsland), accentColor: accentColor)
                    settingsToggleRow("启用动画", binding: toggleBinding(\.animationsEnabled), accentColor: accentColor)
                    settingsToggleRow("静音提示音", binding: toggleBinding(\.isMuted), accentColor: accentColor)
                    settingsToggleRow("登录时启动", binding: toggleBinding(\.launchAtLoginEnabled), accentColor: accentColor)

                    Text(launchAtLoginManager.supportDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let lastErrorMessage = launchAtLoginManager.lastErrorMessage {
                        Text(lastErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                SettingsCard(
                    title: "应用更新",
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                ) { phase in
                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled,
                        fillOpacity: 0.05
                    ) {
                        LabeledContent("更新状态", value: appUpdateService.statusDescription)
                    }

                    if let feedURLString = appUpdateService.feedURLString {
                        InteractiveFeedbackRow(
                            accentColor: accentColor,
                            animationsEnabled: settingsStore.settings.animationsEnabled,
                            fillOpacity: 0.05
                        ) {
                            LabeledContent("更新源") {
                                Text(feedURLString)
                                    .multilineTextAlignment(.trailing)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    ) {
                        Toggle(
                            "自动检查更新",
                            isOn: Binding(
                                get: { appUpdateService.automaticallyChecksForUpdates },
                                set: { appUpdateService.automaticallyChecksForUpdates = $0 }
                            )
                        )
                    }
                    .disabled(!appUpdateService.isAvailable)

                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    ) {
                        Toggle(
                            "自动下载更新",
                            isOn: Binding(
                                get: { appUpdateService.automaticallyDownloadsUpdates },
                                set: { appUpdateService.automaticallyDownloadsUpdates = $0 }
                            )
                        )
                    }
                    .disabled(!appUpdateService.isAvailable || !appUpdateService.allowsAutomaticUpdates)

                    Text(appUpdateService.publicEDKeyConfigured ? "已配置 Sparkle 公钥。" : "未配置 Sparkle 公钥，无法启用真实更新。")
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(phase == .hovered ? 0.92 : 0.78))

                    if let updateError = appUpdateService.lastErrorMessage {
                        Text(updateError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    HStack(spacing: 8) {
                        Button("检查更新…") {
                            appUpdateService.checkForUpdates()
                        }
                        .buttonStyle(actionButtonStyle(accentColor))
                        .disabled(!appUpdateService.canCheckForUpdates)

                        if let feedURLString = appUpdateService.feedURLString {
                            Button("复制更新源") {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(feedURLString, forType: .string)
                            }
                            .buttonStyle(actionButtonStyle(accentColor))
                        }
                    }
                }

                SettingsCard(
                    title: "状态来源",
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                ) { phase in
                    let currentSessionID = statusService.currentProviderSession?.id
                    let recentSessions = statusService.recentProviderSessions.filter { $0.id != currentSessionID }

                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    ) {
                        Picker("来源类型", selection: providerBinding) {
                            ForEach(CodexProviderKind.allCases) { kind in
                                Text(kind.displayName).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Text(settingsStore.settings.providerKind.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(phase == .hovered ? 0.92 : 0.78))

                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled,
                        fillOpacity: 0.05
                    ) {
                        LabeledContent("当前来源", value: statusService.providerStatusSummary)
                    }

                    InteractiveFeedbackRow(
                        accentColor: accentColor,
                        animationsEnabled: settingsStore.settings.animationsEnabled,
                        fillOpacity: 0.05
                    ) {
                        LabeledContent("连接信息") {
                            Text(statusService.providerStatusDetail)
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                    }

                    if let connectionLabel = statusService.providerConnectionLabel {
                        InteractiveFeedbackRow(
                            accentColor: statusService.isProviderConnected ? .green : accentColor,
                            animationsEnabled: settingsStore.settings.animationsEnabled,
                            fillOpacity: 0.05
                        ) {
                            LabeledContent("桥接状态") {
                                Text(connectionLabel)
                                    .foregroundStyle(statusService.isProviderConnected ? Color.green : Color.secondary)
                            }
                        }
                    }

                    if let connectionDetail = statusService.providerConnectionDetail {
                        Text(connectionDetail)
                            .font(.caption)
                            .foregroundStyle(Color.secondary.opacity(phase == .hovered ? 0.92 : 0.78))
                    }

                    if let providerError = statusService.lastProviderError {
                        InteractiveFeedbackRow(
                            accentColor: .orange,
                            animationsEnabled: settingsStore.settings.animationsEnabled,
                            fillOpacity: 0.06
                        ) {
                            Text(providerError)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .textSelection(.enabled)
                        }
                    }

                    if let currentSession = statusService.currentProviderSession {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("当前会话")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            InteractiveFeedbackRow(
                                accentColor: IslandStyle.accent(for: currentSession.state),
                                animationsEnabled: settingsStore.settings.animationsEnabled,
                                fillOpacity: 0.05
                            ) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        StatusBadgeView(state: currentSession.state, compact: true)
                                        Text(currentSession.displayCommand)
                                            .font(.subheadline.weight(.medium))
                                        Spacer(minLength: 8)
                                        Text(currentSession.timestamp.shortRelativeString)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(currentSession.phaseLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary.opacity(0.84))
                                        .lineLimit(1)

                                    Text(currentSession.primarySummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)

                                    Text(currentSession.metadataSummary)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    if let errorSummary = currentSession.errorSummary {
                                        Text(errorSummary)
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                            .lineLimit(2)
                                    }

                                    Text(currentSession.threadID)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }

                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("最近会话")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ForEach(recentSessions.prefix(4)) { session in
                                InteractiveFeedbackRow(
                                    accentColor: IslandStyle.accent(for: session.state),
                                    animationsEnabled: settingsStore.settings.animationsEnabled,
                                    fillOpacity: 0.04
                                ) {
                                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                                        StatusBadgeView(state: session.state, compact: true)
                                            .frame(minWidth: 58, alignment: .leading)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(session.displayCommand)
                                                .font(.subheadline.weight(.medium))
                                            Text(session.phaseLabel)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.primary.opacity(0.84))
                                                .lineLimit(1)
                                            Text(session.primarySummary)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                            Text(session.metadataSummary)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                            if let errorSummary = session.errorSummary {
                                                Text(errorSummary)
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                                    .lineLimit(1)
                                            }
                                            Text(session.threadID)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                                .textSelection(.enabled)
                                        }
                                        Spacer(minLength: 8)
                                        Text(session.timestamp.shortRelativeString)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Button("复制来源信息") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(statusService.providerDiagnosticsText, forType: .string)
                        }
                        .buttonStyle(actionButtonStyle(accentColor))

                        Button("刷新当前来源") {
                            statusService.advance()
                        }
                        .buttonStyle(actionButtonStyle(accentColor))
                    }

                    if !statusService.recentProviderSessions.isEmpty {
                        Button("复制最近会话诊断") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(
                                statusService.recentProviderSessions
                                    .map(\.diagnosticLine)
                                    .joined(separator: "\n"),
                                forType: .string
                            )
                        }
                        .buttonStyle(actionButtonStyle(accentColor))
                    }
                }

                SettingsCard(
                    title: statusService.canManuallyTransition ? "模拟状态控制" : "来源刷新",
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                ) { phase in
                    if statusService.canManuallyTransition {
                        FlowRow(spacing: 8) {
                            ForEach(CodexState.allCases, id: \.self) { state in
                                Button(state.displayName) {
                                    statusService.setPreviewState(state)
                                }
                                .buttonStyle(actionButtonStyle(IslandStyle.accent(for: state)))
                            }
                        }

                        Button("切换到下一个模拟状态") {
                            statusService.advance()
                        }
                        .buttonStyle(actionButtonStyle(accentColor))
                    } else {
                        Button("刷新当前来源") {
                            statusService.advance()
                        }
                        .buttonStyle(actionButtonStyle(accentColor))

                        Text("非模拟来源会自行驱动状态；刷新会主动向当前来源请求一份新的状态快照。")
                            .font(.caption)
                            .foregroundStyle(Color.secondary.opacity(phase == .hovered ? 0.92 : 0.78))
                    }
                }

                SettingsCard(
                    title: "历史记录",
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled
                ) { phase in
                    HStack {
                        Button("清空历史") {
                            statusService.clearHistory()
                        }
                        .buttonStyle(actionButtonStyle(.orange))
                        .disabled(statusService.history.isEmpty)
                        Spacer()
                    }

                    ForEach(statusService.history.prefix(8)) { entry in
                        InteractiveFeedbackRow(
                            accentColor: IslandStyle.accent(for: entry.state),
                            animationsEnabled: settingsStore.settings.animationsEnabled,
                            fillOpacity: 0.04
                        ) {
                            HStack {
                                StatusBadgeView(state: entry.state, compact: true)
                                Text(entry.taskTitle)
                                Spacer()
                                Text(entry.timestamp.shortRelativeString)
                                    .foregroundStyle(Color.secondary.opacity(phase == .hovered ? 0.9 : 0.72))
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func toggleBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                settingsStore.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private var providerBinding: Binding<CodexProviderKind> {
        Binding(
            get: { settingsStore.settings.providerKind },
            set: { newValue in
                settingsStore.update { $0.providerKind = newValue }
            }
        )
    }

    private func actionButtonStyle(_ color: Color) -> InteractiveButtonStyle {
        InteractiveButtonStyle(
            prominence: .secondary,
            accentColor: color,
            cornerRadius: 14,
            fillOpacity: 0.14,
            animationsEnabled: settingsStore.settings.animationsEnabled
        )
    }

    @ViewBuilder
    private func settingsToggleRow(
        _ title: String,
        binding: Binding<Bool>,
        accentColor: Color
    ) -> some View {
        InteractiveFeedbackRow(
            accentColor: accentColor,
            animationsEnabled: settingsStore.settings.animationsEnabled
        ) {
            Toggle(title, isOn: binding)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let accentColor: Color
    let animationsEnabled: Bool
    let content: (InteractivePhase) -> Content

    init(
        title: String,
        accentColor: Color,
        animationsEnabled: Bool,
        @ViewBuilder content: @escaping (InteractivePhase) -> Content
    ) {
        self.title = title
        self.accentColor = accentColor
        self.animationsEnabled = animationsEnabled
        self.content = content
    }

    var body: some View {
        InteractiveCard(
            prominence: .secondary,
            accentColor: accentColor,
            cornerRadius: 22,
            animationsEnabled: animationsEnabled
        ) { phase in
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .brightness(phase == .hovered ? 0.06 : 0.0)
                    .offset(y: phase == .pressed ? 1.0 : (phase == .hovered ? -0.8 : 0.0))

                content(phase)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
            )
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: phase)
        }
    }
}

private struct PreviewCard: View {
    let statusService: CodexStatusService
    let accentColor: Color
    let animationsEnabled: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            LobsterAvatarView(
                state: statusService.currentState,
                animationsEnabled: animationsEnabled,
                interactionPhase: isHovered ? .hovered : .resting
            )
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text("预览")
                    .font(.headline)
                Text(statusService.currentTask.title)
                    .font(.headline.weight(.semibold))
                Text(statusService.currentTask.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                StatusBadgeView(state: statusService.currentState)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.78))
        )
        .interactiveSurface(
            phase: isHovered ? .hovered : .resting,
            prominence: .primary,
            accentColor: accentColor,
            cornerRadius: 24,
            animationsEnabled: animationsEnabled
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct FlowRow<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        HStack(spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
