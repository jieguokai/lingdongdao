import Foundation
import Observation

@MainActor
@Observable
final class AppBootstrap {
    let dependencies: AppDependencies
    private var hasStarted = false
    private var activeProviderKind: CodexProviderKind

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        self.activeProviderKind = dependencies.settingsStore.settings.providerKind
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
        dependencies.statusService.start()
        dependencies.floatingIslandWindowManager.refresh()
    }

    private func wireEvents() {
        dependencies.statusService.onSnapshotApplied = { [weak self] snapshot in
            guard let self else { return }
            dependencies.floatingIslandWindowManager.refresh()
            dependencies.soundManager.play(for: snapshot.state)
        }

        dependencies.settingsStore.onSettingsChanged = { [weak self] settings in
            self?.applySettings(settings)
        }
    }

    private func applySettings(_ settings: AppSettings) {
        dependencies.soundManager.isMuted = settings.isMuted
        dependencies.floatingIslandWindowManager.setVisible(settings.showsIsland)
        dependencies.floatingIslandWindowManager.refresh()
        dependencies.launchAtLoginManager.applyPreference(settings.launchAtLoginEnabled)
        if settings.providerKind != activeProviderKind {
            activeProviderKind = settings.providerKind
            let provider = CodexProviderFactory.makeProvider(kind: settings.providerKind)
            dependencies.statusService.replaceProvider(provider)
        }
    }
}
