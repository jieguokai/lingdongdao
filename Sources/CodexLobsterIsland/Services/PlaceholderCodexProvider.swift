import Foundation

@MainActor
class PlaceholderCodexProvider: CodexStatusProviding, CodexProviderInspectable {
    let kind: CodexProviderKind
    let latestSnapshot: CodexStatusSnapshot
    let providerStatusDetail: String

    var providerKind: CodexProviderKind { kind }
    var providerStatusSummary: String { kind.displayName }
    var lastProviderError: String? { nil }

    init(kind: CodexProviderKind, title: String, detail: String) {
        self.kind = kind
        self.providerStatusDetail = detail
        let timestamp = Date()
        let task = CodexTask(
            title: title,
            detail: detail,
            state: .idle,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        self.latestSnapshot = CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        onUpdate(latestSnapshot)
    }

    func stop() {}

    func advance() -> CodexStatusSnapshot {
        latestSnapshot
    }
}
