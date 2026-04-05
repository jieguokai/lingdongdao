import Foundation
import Observation

@MainActor
@Observable
final class AppBootstrap {
    let dependencies: AppDependencies
    private var hasStarted = false
    private var lastObservedSnapshot: CodexStatusSnapshot?

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        wireEvents()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        dependencies.floatingIslandWindowManager.install(
            statusService: dependencies.statusService,
            settingsStore: dependencies.settingsStore
        )
        applySettings(dependencies.settingsStore.settings)
        dependencies.appUpdateService.start()
        dependencies.statusService.start()
        Task {
            await dependencies.taskLaunchService.refreshAuthenticationState()
        }
        dependencies.floatingIslandWindowManager.refresh()
    }

    private func wireEvents() {
        dependencies.statusService.onSnapshotApplied = { [weak self] snapshot in
            guard let self else { return }
            dependencies.floatingIslandWindowManager.refresh()
            dependencies.floatingIslandWindowManager.handleDisplayStateChange(dependencies.statusService.effectiveDisplayState)
            dependencies.soundManager.handleTransition(from: lastObservedSnapshot, to: snapshot)
            lastObservedSnapshot = snapshot
        }

        dependencies.settingsStore.onSettingsChanged = { [weak self] settings in
            self?.applySettings(settings)
        }
    }

    private func applySettings(_ settings: AppSettings) {
        dependencies.soundManager.isMuted = settings.isMuted
        dependencies.soundManager.isDoNotDisturbEnabled = settings.isDoNotDisturbEnabled
        dependencies.floatingIslandWindowManager.setVisible(settings.showsIsland)
        dependencies.floatingIslandWindowManager.refresh()
        dependencies.launchAtLoginManager.applyPreference(settings.launchAtLoginEnabled)
    }
}
