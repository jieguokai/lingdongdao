import Foundation

struct CodexProviderSessionSummary: Identifiable, Equatable, Sendable {
    let id: String
    let state: CodexState
    let title: String
    let detail: String
    let commandName: String?
    let exitCode: Int?
    let responsePreview: String?
    let usageSummary: String?
    let timestamp: Date
}

extension CodexProviderSessionSummary {
    var threadID: String { id }

    var primarySummary: String {
        responsePreview ?? detail
    }

    var metadataSummary: String {
        let parts = [
            "thread \(threadID)",
            usageSummary,
            exitCode.map { "exit \($0)" }
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    var diagnosticLine: String {
        let command = commandName ?? title
        let response = responsePreview.map { " response=\($0)" } ?? ""
        let usage = usageSummary.map { " usage=\($0)" } ?? ""
        let exit = exitCode.map { " exit=\($0)" } ?? ""
        return "[\(timestamp.ISO8601Format())] \(state.rawValue) \(command) thread=\(id)\(exit)\(usage)\(response) \(detail)"
    }
}
