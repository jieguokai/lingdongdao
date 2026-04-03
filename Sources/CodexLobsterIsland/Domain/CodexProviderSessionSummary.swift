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
    let phase: String?
    let errorSummary: String?
    let timestamp: Date
}

extension CodexProviderSessionSummary {
    var threadID: String { id }

    var displayCommand: String {
        commandName ?? "codex"
    }

    var phaseLabel: String {
        switch phase {
        case "thread_started":
            return "会话已建立"
        case "turn_started":
            return "正在处理"
        case "reconnecting":
            return "正在重连"
        case "response_ready":
            return "已生成回复"
        case "turn_completed":
            return "回合已完成"
        case "completed":
            return "已完成"
        case "failed":
            return "已失败"
        case "error":
            return "报告错误"
        case "started":
            return "已启动"
        default:
            return title
        }
    }

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
        let phase = phase.map { " phase=\($0)" } ?? ""
        let error = errorSummary.map { " error=\($0)" } ?? ""
        return "[\(timestamp.ISO8601Format())] \(state.rawValue) \(command) thread=\(id)\(phase)\(exit)\(usage)\(response)\(error) \(detail)"
    }
}
