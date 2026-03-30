import AppKit
import SwiftUI

struct SettingsView: View {
    let statusService: CodexStatusService
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginManager: LaunchAtLoginManager

    var body: some View {
        Form {
            Section("Preview") {
                HStack(spacing: 16) {
                    LobsterAvatarView(
                        state: statusService.currentState,
                        animationsEnabled: settingsStore.settings.animationsEnabled
                    )
                    .frame(width: 84, height: 84)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(statusService.currentTask.title)
                            .font(.headline)
                        Text(statusService.currentTask.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        StatusBadgeView(state: statusService.currentState)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Behavior") {
                Toggle("Show floating island", isOn: toggleBinding(\.showsIsland))
                Toggle("Enable animations", isOn: toggleBinding(\.animationsEnabled))
                Toggle("Mute sounds", isOn: toggleBinding(\.isMuted))
                Toggle("Launch at login", isOn: toggleBinding(\.launchAtLoginEnabled))
                Text(launchAtLoginManager.supportDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let lastErrorMessage = launchAtLoginManager.lastErrorMessage {
                    Text(lastErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Status Source") {
                Picker("Provider", selection: providerBinding) {
                    ForEach(CodexProviderKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }

                Text(settingsStore.settings.providerKind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LabeledContent("Active Source", value: statusService.providerStatusSummary)
                LabeledContent("Connection") {
                    Text(statusService.providerStatusDetail)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }

                if let providerError = statusService.lastProviderError {
                    Text(providerError)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }

                HStack {
                    Button("Copy Source Info") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(
                            "\(statusService.providerStatusSummary)\n\(statusService.providerStatusDetail)",
                            forType: .string
                        )
                    }

                    Button("Refresh Current Source") {
                        statusService.advance()
                    }
                }
            }

            Section(statusService.canManuallyTransition ? "Mock State Controls" : "Source Refresh") {
                if statusService.canManuallyTransition {
                    HStack(spacing: 8) {
                        ForEach(CodexState.allCases, id: \.self) { state in
                            Button(state.displayName) {
                                statusService.setPreviewState(state)
                            }
                        }
                    }

                    Button("Advance to Next Mock State") {
                        statusService.advance()
                    }
                } else {
                    Button("Refresh Current Source") {
                        statusService.advance()
                    }
                    Text("Non-mock providers drive their own state. Refresh asks the active source for a new snapshot.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("History") {
                HStack {
                    Button("Clear History") {
                        statusService.clearHistory()
                    }
                    .disabled(statusService.history.isEmpty)
                    Spacer()
                }

                ForEach(statusService.history.prefix(8)) { entry in
                    HStack {
                        StatusBadgeView(state: entry.state, compact: true)
                        Text(entry.taskTitle)
                        Spacer()
                        Text(entry.timestamp.shortRelativeString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
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
}
