import Foundation
import Observation
#if canImport(ServiceManagement)
import ServiceManagement
#endif

@MainActor
@Observable
final class LaunchAtLoginManager {
    private(set) var lastErrorMessage: String?

    var supportDescription: String {
        if Bundle.main.bundleURL.pathExtension != "app" {
            return "Running via swift run: launch at login registration may be unavailable until packaged as an .app bundle."
        }
        return "Uses ServiceManagement when available."
    }

    func applyPreference(_ enabled: Bool) {
        #if canImport(ServiceManagement)
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            lastErrorMessage = "Launch at login requires an app bundle."
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #else
        lastErrorMessage = "ServiceManagement is unavailable in the current toolchain."
        #endif
    }
}
