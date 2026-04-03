import AppKit
import SwiftUI

struct MenuBarStatusView: View {
    let statusService: CodexStatusService
    let appUpdateService: AppUpdateService
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginManager: LaunchAtLoginManager
    @State private var isProviderListExpanded = false

    var body: some View {
        let accentColor = IslandStyle.accent(for: statusService.currentState)
        let headerSummary = statusService.providerStatusSummary == statusService.currentTask.title
            ? statusService.currentState.subtitle
            : statusService.providerStatusSummary
        let currentSession = statusService.currentProviderSession

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Label(statusService.currentState.displayName, systemImage: statusService.currentState.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandStyle.secondaryText)

                Text(statusService.currentTask.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(headerSummary)
                    .font(.caption)
                    .foregroundStyle(IslandStyle.tertiaryText)
                    .lineLimit(1)

                if let providerError = statusService.lastProviderError {
                    Text(providerError)
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.9))
                        .lineLimit(1)
                }

                if let currentSession {
                    Text("\(currentSession.displayCommand) · \(currentSession.phaseLabel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.84))
                        .lineLimit(1)

                    Text(currentSession.primarySummary)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)
                        .lineLimit(2)

                    if let errorSummary = currentSession.errorSummary {
                        Text(errorSummary)
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.9))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 6) {
                Button(settingsStore.settings.showsIsland ? "隐藏浮动岛" : "显示浮动岛") {
                    settingsStore.update { $0.showsIsland.toggle() }
                }
                .buttonStyle(menuButtonStyle(accentColor))

                InteractiveFeedbackRow(
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    fillOpacity: 0.05,
                    isCompact: true
                ) {
                    Toggle("静音提示音", isOn: toggleBinding(\.isMuted))
                }

                InteractiveFeedbackRow(
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    fillOpacity: 0.05,
                    isCompact: true
                ) {
                    Toggle("启用动画", isOn: toggleBinding(\.animationsEnabled))
                }

                InteractiveFeedbackRow(
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    fillOpacity: 0.05,
                    isCompact: true
                ) {
                    Toggle("登录时启动", isOn: toggleBinding(\.launchAtLoginEnabled))
                }
            }
            .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 6) {
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

                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        isProviderListExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("状态来源")
                        Spacer()
                        Text(settingsStore.settings.providerKind.displayName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: isProviderListExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(menuButtonStyle(accentColor))

                if isProviderListExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(CodexProviderKind.allCases) { kind in
                            Button {
                                settingsStore.update { $0.providerKind = kind }
                                isProviderListExpanded = false
                            } label: {
                                HStack {
                                    Image(systemName: settingsStore.settings.providerKind == kind ? "checkmark" : "circle")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(settingsStore.settings.providerKind == kind ? accentColor : IslandStyle.tertiaryText)
                                    Text(kind.displayName)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(menuButtonStyle(accentColor))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button("复制来源信息") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(statusService.providerDiagnosticsText, forType: .string)
                }
                .buttonStyle(menuButtonStyle(accentColor))

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
                    .buttonStyle(menuButtonStyle(accentColor))
                }
            }
            .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 6) {
                Button("检查更新…") {
                    appUpdateService.checkForUpdates()
                }
                .buttonStyle(menuButtonStyle(accentColor))
                .disabled(!appUpdateService.canCheckForUpdates)

                if appUpdateService.isAvailable {
                    Text(appUpdateService.statusDescription)
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)
                        .lineLimit(2)
                }

                Button(statusService.canManuallyTransition ? "切换到下一个模拟状态" : "刷新当前来源") {
                    statusService.advance()
                }
                .buttonStyle(menuButtonStyle(accentColor))

                Button("清空历史") {
                    statusService.clearHistory()
                }
                .buttonStyle(menuButtonStyle(.orange))

                if statusService.canManuallyTransition {
                    Text("设置模拟状态")
                        .font(.caption2)
                        .foregroundStyle(IslandStyle.tertiaryText)

                    ForEach(CodexState.allCases, id: \.self) { state in
                        Button(state.displayName) {
                            statusService.setPreviewState(state)
                        }
                        .buttonStyle(menuButtonStyle(IslandStyle.accent(for: state)))
                    }
                }
            }
            .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 10)

            HStack(spacing: 6) {
                InteractiveFeedbackRow(
                    accentColor: accentColor,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    fillOpacity: 0.05,
                    isCompact: true
                ) {
                    SettingsLink {
                        Text("设置…")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Button("退出") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(menuButtonStyle(.red))
            }
        }
        .padding(10)
        .frame(width: 248)
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
}
