import AppKit
import SwiftUI

struct MenuBarStatusView: View {
    let statusService: CodexStatusService
    let taskLaunchService: CodexTaskLaunchService
    let appUpdateService: AppUpdateService
    @Bindable var soundManager: SoundManager
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginManager: LaunchAtLoginManager
    @State private var taskPrompt = ""
    @State private var taskComposerError: String?
    @FocusState private var isTaskPromptFocused: Bool

    var body: some View {
        let displayState = statusService.effectiveDisplayState
        let displayTask = statusService.effectiveDisplayTask
        let accentColor = IslandStyle.accent(for: displayState)
        let headerSummary = statusService.providerStatusSummary == displayTask.title
            ? displayState.subtitle
            : statusService.providerStatusSummary

        VStack(alignment: .leading, spacing: 0) {
            statusHeaderSection(
                displayState: displayState,
                displayTask: displayTask,
                headerSummary: headerSummary
            )
            menuDivider()

            taskComposerSection(accentColor: accentColor)
            menuDivider()

            VStack(alignment: .leading, spacing: 0) {
                menuToggleRow("显示浮动岛", isOn: toggleBinding(\.showsIsland), accentColor: accentColor)

                menuDivider()

                menuToggleRow("静音提示音", isOn: toggleBinding(\.isMuted), accentColor: accentColor)
            }

            menuDivider()

            VStack(alignment: .leading, spacing: 0) {
                menuRowButton(
                    soundManager.isPreviewPlaying ? "正在试听…" : "测试提示音",
                    accentColor: accentColor,
                    disabled: soundPreviewDisabled
                ) {
                    soundManager.playPreviewSequence()
                }
                menuDivider()

                menuRowButton("设置…", accentColor: accentColor) {
                    openSettingsWindow()
                }

                menuDivider()

                menuRowButton("退出", accentColor: accentColor) {
                    NSApp.terminate(nil)
                }
            }

            menuDivider()

            connectionSection(accentColor: accentColor)
        }
        .padding(12)
        .frame(width: 328)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(IslandStyle.codexPanelFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(IslandStyle.materialWash(for: displayState).opacity(0.48))
                }
        )
    }

    @ViewBuilder
    private func menuDivider() -> some View {
        Rectangle()
            .fill(IslandStyle.separator)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func statusHeaderSection(
        displayState: CodexState,
        displayTask: CodexTask,
        headerSummary: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(displayState.displayName, systemImage: displayState.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(IslandStyle.secondaryText)

            Text(displayTask.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(headerSummary)
                .font(.caption)
                .foregroundStyle(IslandStyle.tertiaryText)
                .lineLimit(1)

            if let actionHint = statusService.currentActionEntryHint {
                Text(actionHint)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange.opacity(0.92))
                    .lineLimit(2)
            } else if let providerError = statusService.lastProviderError {
                Text(providerError)
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func taskComposerSection(accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("发起 Codex 任务", systemImage: "text.cursor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(IslandStyle.secondaryText)

            HStack(spacing: 8) {
                TextField("让 Codex 做什么？", text: $taskPrompt)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .focused($isTaskPromptFocused)
                    .disabled(taskComposerDisabled)
                    .onSubmit {
                        submitPrompt()
                    }
                    .accessibilityLabel("Codex task prompt")

                Button {
                    submitPrompt()
                } label: {
                    Image(systemName: taskLaunchService.authenticationState.isAuthenticated ? "paperplane.fill" : "person.badge.key.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Send Codex task")
                .buttonStyle(menuButtonStyle(accentColor))
                .disabled(taskComposerDisabled || taskPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text(taskComposerStatusText)
                .font(.caption2)
                .foregroundStyle(IslandStyle.tertiaryText)
                .lineLimit(3)

            if shouldShowAuthenticationCTA {
                menuRowButton(authenticationCTAButtonTitle, accentColor: accentColor, disabled: taskLaunchService.authenticationState.isBusy) {
                    Task {
                        await beginAuthenticationOnly()
                    }
                }
            }

            if let taskComposerError {
                Text(taskComposerError)
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.94))
                    .lineLimit(3)
            } else if let launchError = taskLaunchService.lastLaunchErrorMessage {
                Text(launchError)
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.94))
                    .lineLimit(3)
            }
        }
        .padding(.bottom, 2)
        .task(id: taskComposerDisabled) {
            guard !taskComposerDisabled else { return }
            await MainActor.run {
                isTaskPromptFocused = true
            }
        }
        .padding(.vertical, 12)
    }

    private func toggleBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                settingsStore.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private func menuButtonStyle(_ color: Color) -> InteractiveButtonStyle {
        InteractiveButtonStyle(
            prominence: .subtle,
            accentColor: color,
            cornerRadius: 12,
            fillOpacity: 0.06,
            animationsEnabled: settingsStore.settings.animationsEnabled,
            expandsHorizontally: true
        )
    }

    @ViewBuilder
    private func menuRowButton(
        _ title: String,
        accentColor: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        InteractiveFeedbackRow(
            accentColor: accentColor,
            animationsEnabled: settingsStore.settings.animationsEnabled,
            fillOpacity: 0.03,
            isCompact: true
        ) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Text(title)
                        .foregroundStyle(IslandStyle.primaryText)
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .opacity(disabled ? 0.45 : 1.0)
    }

    @ViewBuilder
    private func menuToggleRow(
        _ title: String,
        isOn: Binding<Bool>,
        accentColor: Color
    ) -> some View {
        InteractiveFeedbackRow(
            accentColor: accentColor,
            animationsEnabled: settingsStore.settings.animationsEnabled,
            fillOpacity: 0.03,
            isCompact: true
        ) {
            Toggle(title, isOn: isOn)
                .toggleStyle(MinimalToggleStyle(accentColor: accentColor))
        }
    }

    @ViewBuilder
    private func connectionSection(accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("来源：\(statusService.providerStatusSummary)")
                .font(.caption)
                .foregroundStyle(IslandStyle.tertiaryText)
                .lineLimit(1)

            if let connectionLabel = statusService.providerConnectionLabel {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusService.isProviderConnected ? Color.green : IslandStyle.tertiaryText.opacity(0.8))
                        .frame(width: 6, height: 6)
                    Text(connectionLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(statusService.isProviderConnected ? Color.green.opacity(0.9) : IslandStyle.tertiaryText)
                        .lineLimit(1)
                }
            }

            if let syncStatusHintText = statusService.syncStatusHintText {
                Text(syncStatusHintText)
                    .font(.caption2)
                    .foregroundStyle(IslandStyle.tertiaryText)
                    .lineLimit(2)
            }

            if statusService.providerKind == .desktopThread && statusService.canManageDesktopPermissions {
                menuRowButton("完成授权", accentColor: accentColor) {
                    statusService.requestDesktopPermissionPrompt()
                }
            }
        }
        .padding(.top, 12)
    }

    private var taskComposerDisabled: Bool {
        taskLaunchService.authenticationState.isBusy
            || taskLaunchService.isSubmitting
            || statusService.blocksNewAppLaunch
    }

    private var soundPreviewDisabled: Bool {
        soundManager.isPreviewPlaying
            || settingsStore.settings.isMuted
            || settingsStore.settings.isDoNotDisturbEnabled
    }

    private var taskComposerStatusText: String {
        if statusService.blocksNewAppLaunch {
            return "当前已有一条实时 Codex 任务正在运行或等待确认。请先处理它，再发起下一条。"
        }
        if statusService.providerKind == .desktopThread {
            return "当前以桌面对话为主来源。这里仍可直接发起一条兼容的 Codex exec 任务。"
        }
        return taskLaunchService.authenticationState.statusText
    }

    private var shouldShowAuthenticationCTA: Bool {
        switch taskLaunchService.authenticationState {
        case .unauthenticated, .failed, .unavailable:
            return true
        case .checking, .authenticated, .authorizing:
            return false
        }
    }

    private var authenticationCTAButtonTitle: String {
        switch taskLaunchService.authenticationState {
        case .unauthenticated:
            return "登录 Codex"
        case .failed:
            return "重试登录"
        case .unavailable:
            return "重新检查 Codex CLI"
        case .checking, .authenticated, .authorizing:
            return "登录 Codex"
        }
    }

    private func submitPrompt() {
        let prompt = taskPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        Task {
            await submitPrompt(prompt)
        }
    }

    @MainActor
    private func submitPrompt(_ prompt: String) async {
        taskComposerError = nil

        if !taskLaunchService.authenticationState.isAuthenticated {
            guard presentAuthenticationAlert() else { return }

            do {
                try await taskLaunchService.ensureAuthenticated()
            } catch {
                taskComposerError = error.localizedDescription
                return
            }
        }

        do {
            try await taskLaunchService.launchExec(prompt: prompt)
            taskPrompt = ""
            taskComposerError = nil
        } catch {
            taskComposerError = error.localizedDescription
        }
    }

    @MainActor
    private func beginAuthenticationOnly() async {
        taskComposerError = nil

        switch taskLaunchService.authenticationState {
        case .unavailable:
            await taskLaunchService.refreshAuthenticationState()
        case .unauthenticated, .failed:
            guard presentAuthenticationAlert() else { return }
            do {
                try await taskLaunchService.ensureAuthenticated()
            } catch {
                taskComposerError = error.localizedDescription
            }
        case .checking, .authenticated, .authorizing:
            break
        }
    }

    @MainActor
    private func presentAuthenticationAlert() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "需要登录 Codex"
        alert.informativeText = "首次从 app 发起任务前，需要打开 Codex 官方登录流程。确认后会启动浏览器完成授权；完成后，小龙虾会自动显示实时状态、声音提醒和原生确认按钮。"
        alert.addButton(withTitle: "继续登录")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func openPrivacyPane(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
