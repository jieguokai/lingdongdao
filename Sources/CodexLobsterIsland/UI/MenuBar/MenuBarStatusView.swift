import SwiftUI

struct MenuBarStatusView: View {
    let statusService: CodexStatusService
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginManager: LaunchAtLoginManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(statusService.currentState.displayName, systemImage: statusService.currentState.symbolName)
                .font(.headline)

            Text(statusService.currentTask.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(statusService.currentTask.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Divider()

            Button(settingsStore.settings.showsIsland ? "Hide Island" : "Show Island") {
                settingsStore.update { $0.showsIsland.toggle() }
            }

            Toggle("Mute Sounds", isOn: toggleBinding(\.isMuted))
            Toggle("Enable Animations", isOn: toggleBinding(\.animationsEnabled))
            Toggle("Launch at Login", isOn: toggleBinding(\.launchAtLoginEnabled))

            Divider()

            Menu("Status Source") {
                ForEach(CodexProviderKind.allCases) { kind in
                    Button(kind.displayName) {
                        settingsStore.update { $0.providerKind = kind }
                    }
                }
            }

            Divider()

            Button(statusService.canManuallyTransition ? "Next Mock State" : "Refresh Source") {
                statusService.advance()
            }

            if statusService.canManuallyTransition {
                Divider()
                Text("Set Mock State")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(CodexState.allCases, id: \.self) { state in
                    Button(state.displayName) {
                        statusService.setPreviewState(state)
                    }
                }
            }

            Divider()

            SettingsLink {
                Text("Settings…")
            }

            Button("Quit Codex Lobster Island") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private func toggleBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                settingsStore.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }
}
