import Foundation

struct CodexProviderSessionSummary: Identifiable, Equatable, Sendable {
    let id: String
    let state: CodexState
    let title: String
    let detail: String
    let commandName: String?
    let exitCode: Int?
    let timestamp: Date
}

extension CodexProviderSessionSummary {
    var diagnosticLine: String {
        let command = commandName ?? title
        let exit = exitCode.map { " exit=\($0)" } ?? ""
        return "[\(timestamp.ISO8601Format())] \(state.rawValue) \(command) session=\(id)\(exit) \(detail)"
    }
}
