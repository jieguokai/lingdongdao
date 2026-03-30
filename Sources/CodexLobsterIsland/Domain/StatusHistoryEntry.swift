import Foundation

struct StatusHistoryEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let state: CodexState
    let taskTitle: String
    let timestamp: Date

    init(id: UUID = UUID(), state: CodexState, taskTitle: String, timestamp: Date) {
        self.id = id
        self.state = state
        self.taskTitle = taskTitle
        self.timestamp = timestamp
    }
}
