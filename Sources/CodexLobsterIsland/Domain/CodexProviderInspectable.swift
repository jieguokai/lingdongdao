import Foundation

@MainActor
protocol CodexProviderInspectable: AnyObject {
    var providerKind: CodexProviderKind { get }
    var providerStatusSummary: String { get }
    var providerStatusDetail: String { get }
    var lastProviderError: String? { get }
}
