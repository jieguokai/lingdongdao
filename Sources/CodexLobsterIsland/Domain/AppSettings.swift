import Foundation

struct AppSettings: Equatable, Sendable {
    var isMuted: Bool = false
    var showsIsland: Bool = true
    var animationsEnabled: Bool = true
    var launchAtLoginEnabled: Bool = false
    var providerKind: CodexProviderKind = .mock
}
