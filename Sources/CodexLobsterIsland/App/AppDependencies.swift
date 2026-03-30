import Foundation

@MainActor
struct AppDependencies {
    let settingsStore: SettingsStore
    let statusService: CodexStatusService
    let soundManager: SoundManager
    let floatingIslandWindowManager: FloatingIslandWindowManager
    let launchAtLoginManager: LaunchAtLoginManager

    static var live: AppDependencies {
        let settingsStore = SettingsStore()
        let provider = CodexProviderFactory.makeProvider(kind: settingsStore.settings.providerKind)
        let statusService = CodexStatusService(provider: provider)
        let soundManager = SoundManager()
        let floatingIslandWindowManager = FloatingIslandWindowManager()
        let launchAtLoginManager = LaunchAtLoginManager()
        return AppDependencies(
            settingsStore: settingsStore,
            statusService: statusService,
            soundManager: soundManager,
            floatingIslandWindowManager: floatingIslandWindowManager,
            launchAtLoginManager: launchAtLoginManager
        )
    }
}
