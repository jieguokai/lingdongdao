import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    private enum Keys {
        static let isMuted = "settings.isMuted"
        static let isDoNotDisturbEnabled = "settings.isDoNotDisturbEnabled"
        static let showsIsland = "settings.showsIsland"
        static let animationsEnabled = "settings.animationsEnabled"
        static let launchAtLoginEnabled = "settings.launchAtLoginEnabled"
        static let providerKind = "settings.providerKind"
    }

    private let defaults: UserDefaults
    private(set) var settings: AppSettings
    var onSettingsChanged: ((AppSettings) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = AppSettings(
            isMuted: defaults.object(forKey: Keys.isMuted) as? Bool ?? false,
            isDoNotDisturbEnabled: defaults.object(forKey: Keys.isDoNotDisturbEnabled) as? Bool ?? false,
            showsIsland: defaults.object(forKey: Keys.showsIsland) as? Bool ?? true,
            animationsEnabled: defaults.object(forKey: Keys.animationsEnabled) as? Bool ?? true,
            launchAtLoginEnabled: defaults.object(forKey: Keys.launchAtLoginEnabled) as? Bool ?? false,
            providerKind: .desktopThread
        )
        defaults.set(CodexProviderKind.desktopThread.rawValue, forKey: Keys.providerKind)
    }

    func update(_ transform: (inout AppSettings) -> Void) {
        var next = settings
        transform(&next)
        next.providerKind = .desktopThread
        settings = next
        defaults.set(next.isMuted, forKey: Keys.isMuted)
        defaults.set(next.isDoNotDisturbEnabled, forKey: Keys.isDoNotDisturbEnabled)
        defaults.set(next.showsIsland, forKey: Keys.showsIsland)
        defaults.set(next.animationsEnabled, forKey: Keys.animationsEnabled)
        defaults.set(next.launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled)
        defaults.set(next.providerKind.rawValue, forKey: Keys.providerKind)
        onSettingsChanged?(next)
    }
}
