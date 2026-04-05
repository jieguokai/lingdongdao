import Foundation

package enum CodexState: String, Codable, CaseIterable, Sendable {
    case idle
    case typing
    case running
    case awaitingReply
    case awaitingApproval
    case success
    case error

    var displayName: String {
        switch self {
        case .idle:
            "空闲"
        case .typing:
            "输入中"
        case .running:
            "运行中"
        case .awaitingReply:
            "等待回复"
        case .awaitingApproval:
            "等待确认"
        case .success:
            "成功"
        case .error:
            "错误"
        }
    }

    var symbolName: String {
        switch self {
        case .idle:
            "moon.stars.fill"
        case .typing:
            "keyboard.fill"
        case .running:
            "bolt.circle.fill"
        case .awaitingReply:
            "ellipsis.message.fill"
        case .awaitingApproval:
            "questionmark.circle.fill"
        case .success:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var menuBarLabel: String {
        switch self {
        case .idle:
            "空闲"
        case .typing:
            "输入中"
        case .running:
            "运行中"
        case .awaitingReply:
            "等待回复"
        case .awaitingApproval:
            "等待确认"
        case .success:
            "成功"
        case .error:
            "错误"
        }
    }

    var subtitle: String {
        switch self {
        case .idle:
            "静息待命"
        case .typing:
            "正在接收指令"
        case .running:
            "持续处理中"
        case .awaitingReply:
            "等待你继续补充"
        case .awaitingApproval:
            "等待你确认后继续"
        case .success:
            "已顺利完成"
        case .error:
            "需要立即处理"
        }
    }

    var dynamicIslandTitle: String {
        switch self {
        case .idle:
            "等待中"
        case .typing:
            "听指令"
        case .running:
            "执行中"
        case .awaitingReply:
            "等你回复"
        case .awaitingApproval:
            "等待确认"
        case .success:
            "已完成"
        case .error:
            "出错了"
        }
    }

    var soundResourceName: String? {
        switch self {
        case .typing:
            "typing"
        case .running:
            "running"
        case .awaitingReply:
            "awaitingReply"
        case .awaitingApproval:
            "approval"
        case .success:
            "success"
        case .error:
            "error"
        case .idle:
            nil
        }
    }
}
