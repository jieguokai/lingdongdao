import Foundation

@MainActor
protocol CodexProviderInspectable: AnyObject {
    var providerKind: CodexProviderKind { get }
    var providerStatusSummary: String { get }
    var providerStatusDetail: String { get }
    var lastProviderError: String? { get }
    var providerConnectionLabel: String? { get }
    var providerConnectionDetail: String? { get }
    var isProviderConnected: Bool { get }
    var recentProviderSessions: [CodexProviderSessionSummary] { get }
}

extension CodexProviderInspectable {
    var providerConnectionLabel: String? { nil }
    var providerConnectionDetail: String? { nil }
    var isProviderConnected: Bool { false }
    var recentProviderSessions: [CodexProviderSessionSummary] { [] }
}
