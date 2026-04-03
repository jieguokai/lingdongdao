import Foundation
import Observation

@MainActor
@Observable
final class CodexStatusService {
    private var provider: CodexStatusProviding
    var onSnapshotApplied: ((CodexStatusSnapshot) -> Void)?

    private(set) var currentState: CodexState
    private(set) var currentTask: CodexTask
    private(set) var lastUpdatedAt: Date
    private(set) var history: [StatusHistoryEntry] = []

    init(provider: CodexStatusProviding) {
        self.provider = provider
        self.currentState = provider.latestSnapshot.state
        self.currentTask = provider.latestSnapshot.task
        self.lastUpdatedAt = provider.latestSnapshot.updatedAt
    }

    func start() {
        provider.stop()
        provider.start { [weak self] snapshot in
            self?.apply(snapshot: snapshot)
        }
        onSnapshotApplied?(provider.latestSnapshot)
    }

    func advance() {
        let snapshot = provider.advance()
        apply(snapshot: snapshot)
    }

    func setPreviewState(_ state: CodexState) {
        guard let controllable = provider as? CodexStatusControllable else { return }
        let snapshot = controllable.transition(to: state)
        apply(snapshot: snapshot)
    }

    var canManuallyTransition: Bool {
        provider is CodexStatusControllable
    }

    var providerKind: CodexProviderKind {
        inspectableProvider?.providerKind ?? .mock
    }

    var providerStatusSummary: String {
        inspectableProvider?.providerStatusSummary ?? providerKind.displayName
    }

    var providerStatusDetail: String {
        inspectableProvider?.providerStatusDetail ?? providerKind.subtitle
    }

    var lastProviderError: String? {
        inspectableProvider?.lastProviderError
    }

    var providerConnectionLabel: String? {
        inspectableProvider?.providerConnectionLabel
    }

    var providerConnectionDetail: String? {
        inspectableProvider?.providerConnectionDetail
    }

    var isProviderConnected: Bool {
        inspectableProvider?.isProviderConnected ?? false
    }

    var recentProviderSessions: [CodexProviderSessionSummary] {
        inspectableProvider?.recentProviderSessions ?? []
    }

    var providerDiagnosticsText: String {
        let header = [
            providerStatusSummary,
            providerConnectionLabel,
            providerStatusDetail,
            providerConnectionDetail
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        guard !recentProviderSessions.isEmpty else {
            return header
        }

        let sessions = recentProviderSessions.map(\.diagnosticLine).joined(separator: "\n")
        return "\(header)\n\n最近会话\n\(sessions)"
    }

    func replaceProvider(_ provider: CodexStatusProviding) {
        self.provider.stop()
        self.provider = provider
        history.removeAll(keepingCapacity: true)
        currentState = provider.latestSnapshot.state
        currentTask = provider.latestSnapshot.task
        lastUpdatedAt = provider.latestSnapshot.updatedAt
        start()
    }

    func apply(snapshot: CodexStatusSnapshot) {
        currentState = snapshot.state
        currentTask = snapshot.task
        lastUpdatedAt = snapshot.updatedAt
        history.insert(
            StatusHistoryEntry(
                state: snapshot.state,
                taskTitle: snapshot.task.title,
                timestamp: snapshot.updatedAt
            ),
            at: 0
        )
        if history.count > 12 {
            history.removeLast(history.count - 12)
        }
        onSnapshotApplied?(snapshot)
    }

    func clearHistory() {
        history.removeAll(keepingCapacity: false)
    }

    private var inspectableProvider: CodexProviderInspectable? {
        provider as? CodexProviderInspectable
    }
}
