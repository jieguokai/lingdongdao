import Foundation

struct CodexTask: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var detail: String
    var summary: String?
    var approvalReason: String?
    var approvalActions: [CodexApprovalAction]
    var state: CodexState
    var startedAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        summary: String? = nil,
        approvalReason: String? = nil,
        approvalActions: [CodexApprovalAction] = [],
        state: CodexState,
        startedAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.summary = summary
        self.approvalReason = approvalReason
        self.approvalActions = approvalActions
        self.state = state
        self.startedAt = startedAt
        self.updatedAt = updatedAt
    }
}
