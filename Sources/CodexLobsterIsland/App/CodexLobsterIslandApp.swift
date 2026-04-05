import AppKit
import SwiftUI

@main
struct CodexLobsterIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let bootstrap: AppBootstrap

    init() {
        let bootstrap = AppBootstrap()
        self.bootstrap = bootstrap
        AppLaunchCoordinator.shared.bootstrap = bootstrap
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarStatusView(
                statusService: bootstrap.dependencies.statusService,
                taskLaunchService: bootstrap.dependencies.taskLaunchService,
                appUpdateService: bootstrap.dependencies.appUpdateService,
                soundManager: bootstrap.dependencies.soundManager,
                settingsStore: bootstrap.dependencies.settingsStore,
                launchAtLoginManager: bootstrap.dependencies.launchAtLoginManager
            )
        } label: {
            Label(
                bootstrap.dependencies.statusService.currentState.menuBarLabel,
                systemImage: bootstrap.dependencies.statusService.currentState.symbolName
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                statusService: bootstrap.dependencies.statusService,
                appUpdateService: bootstrap.dependencies.appUpdateService,
                settingsStore: bootstrap.dependencies.settingsStore,
                launchAtLoginManager: bootstrap.dependencies.launchAtLoginManager
            )
            .frame(width: 420, height: 480)
        }
    }
}

@MainActor
private final class AppLaunchCoordinator {
    static let shared = AppLaunchCoordinator()
    var bootstrap: AppBootstrap?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppLaunchCoordinator.shared.bootstrap?.start()
    }
}
