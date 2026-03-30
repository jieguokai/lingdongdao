import Foundation

@MainActor
class PlaceholderCodexProvider: CodexStatusProviding {
    let kind: CodexProviderKind
    let latestSnapshot: CodexStatusSnapshot

    init(kind: CodexProviderKind, title: String, detail: String) {
        self.kind = kind
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
