import Foundation

struct CodexStatusSnapshot: Equatable, Sendable {
    var state: CodexState
    var task: CodexTask
    var updatedAt: Date
}

@MainActor
protocol CodexStatusProviding: AnyObject {
    var latestSnapshot: CodexStatusSnapshot { get }
    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void)
    func stop()
    func advance() -> CodexStatusSnapshot
}

@MainActor
protocol CodexStatusControllable: AnyObject {
    func transition(to state: CodexState) -> CodexStatusSnapshot
}

@MainActor
protocol CodexApprovalControlling: AnyObject {
    func performApprovalAction(_ action: CodexApprovalAction) async throws
}

@MainActor
protocol CodexPermissionControlling: AnyObject {
    func requestPermissionPrompt()
    func recheckPermissionState()
}
