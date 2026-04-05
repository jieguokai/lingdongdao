import Foundation

struct CodexProviderTurnSummary: Identifiable, Equatable, Sendable {
    let id: String
    let state: CodexState
    let title: String
    let detail: String
    let summary: String?
    let approvalReason: String?
    let approvalActions: [CodexApprovalAction]
    let phase: String?
    let errorSummary: String?
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        state: CodexState,
        title: String,
        detail: String,
        summary: String? = nil,
        approvalReason: String? = nil,
        approvalActions: [CodexApprovalAction] = [],
        phase: String? = nil,
        errorSummary: String? = nil,
        timestamp: Date
    ) {
        self.id = id
        self.state = state
        self.title = title
        self.detail = detail
        self.summary = summary
        self.approvalReason = approvalReason
        self.approvalActions = approvalActions
        self.phase = phase
        self.errorSummary = errorSummary
        self.timestamp = timestamp
    }
}

extension CodexProviderTurnSummary {
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
        summary ?? detail
    }
}
