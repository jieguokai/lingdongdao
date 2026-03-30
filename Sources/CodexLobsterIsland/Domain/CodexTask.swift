import Foundation

struct CodexTask: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var detail: String
    var state: CodexState
    var startedAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        state: CodexState,
        startedAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.state = state
        self.startedAt = startedAt
        self.updatedAt = updatedAt
    }
}
