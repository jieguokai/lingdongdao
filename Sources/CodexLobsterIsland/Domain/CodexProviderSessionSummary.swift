import Foundation

struct CodexProviderSessionSummary: Identifiable, Equatable, Sendable {
    let id: String
    let identitySeed: String?
    let source: String?
    let threadTitle: String?
    let state: CodexState
    let title: String
    let detail: String
    let commandName: String?
    let exitCode: Int?
    let responsePreview: String?
    let usageSummary: String?
    let phase: String?
    let errorSummary: String?
    let approvalReason: String?
    let approvalActions: [CodexApprovalAction]
    let timestamp: Date
    let turns: [CodexProviderTurnSummary]

    init(
        id: String,
        identitySeed: String? = nil,
        source: String? = nil,
        threadTitle: String? = nil,
        state: CodexState,
        title: String,
        detail: String,
        commandName: String? = nil,
        exitCode: Int? = nil,
        responsePreview: String? = nil,
        usageSummary: String? = nil,
        phase: String? = nil,
        errorSummary: String? = nil,
        approvalReason: String? = nil,
        approvalActions: [CodexApprovalAction] = [],
        timestamp: Date,
        turns: [CodexProviderTurnSummary] = []
    ) {
        self.id = id
        self.identitySeed = identitySeed
        self.source = source
        self.threadTitle = threadTitle
        self.state = state
        self.title = title
        self.detail = detail
        self.commandName = commandName
        self.exitCode = exitCode
        self.responsePreview = responsePreview
        self.usageSummary = usageSummary
        self.phase = phase
        self.errorSummary = errorSummary
        self.approvalReason = approvalReason
        self.approvalActions = approvalActions
        self.timestamp = timestamp
        self.turns = turns
    }
}

extension CodexProviderSessionSummary {
    var threadID: String { id }

    var displayCommand: String {
        commandName ?? "codex"
    }

    var phaseLabel: String {
        switch state {
        case .typing:
            return "输入中"
        case .awaitingReply:
            return "等待回复"
        case .awaitingApproval:
            return "等待确认"
        default:
            break
        }

        switch phase {
        case "thread_started":
            return "会话已建立"
        case "turn_started":
            return "正在处理"
        case "typing":
            return "输入中"
        case "awaiting_reply":
            return "等待回复"
        case "awaiting_approval":
            return "等待确认"
        case "attached_idle":
            return "已连接"
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

    var livePhaseLabel: String {
        phaseLabel
    }

    var metadataSummary: String {
        let parts = [
            source ?? "thread \(threadID)",
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
        let approval = approvalReason.map { " approval=\($0)" } ?? ""
        let sourceInfo = source.map { " source=\($0)" } ?? ""
        return "[\(timestamp.ISO8601Format())] \(state.rawValue) \(command) thread=\(id)\(sourceInfo)\(phase)\(exit)\(usage)\(response)\(error)\(approval) \(detail)"
    }
}
