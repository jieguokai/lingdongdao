import Foundation

@MainActor
struct AppDependencies {
    let settingsStore: SettingsStore
    let statusService: CodexStatusService
    let taskLaunchService: CodexTaskLaunchService
    let appUpdateService: AppUpdateService
    let soundManager: SoundManager
    let floatingIslandWindowManager: FloatingIslandWindowManager
    let launchAtLoginManager: LaunchAtLoginManager

    static var live: AppDependencies {
        let settingsStore = SettingsStore()
        let provider = CodexProviderFactory.makeProvider(kind: .desktopThread)
        let statusService = CodexStatusService(provider: provider)
        let taskLaunchService = CodexTaskLaunchService()
        let appUpdateService = AppUpdateService()
        let soundManager = SoundManager()
        let floatingIslandWindowManager = FloatingIslandWindowManager()
        let launchAtLoginManager = LaunchAtLoginManager()
        return AppDependencies(
            settingsStore: settingsStore,
            statusService: statusService,
            taskLaunchService: taskLaunchService,
            appUpdateService: appUpdateService,
            soundManager: soundManager,
            floatingIslandWindowManager: floatingIslandWindowManager,
            launchAtLoginManager: launchAtLoginManager
        )
    }
}
