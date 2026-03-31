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
            return "当前通过 swift run 运行；在打包为 .app 前，登录时启动可能不可用。"
        }
        return "打包为 .app 后会优先使用 ServiceManagement。"
    }

    func applyPreference(_ enabled: Bool) {
        #if canImport(ServiceManagement)
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            lastErrorMessage = "登录时启动需要 .app 应用包。"
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
        lastErrorMessage = "当前工具链不支持 ServiceManagement。"
        #endif
    }
}
