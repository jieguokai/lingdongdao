import Foundation

enum CodexAuthenticationState: Equatable {
    case checking
    case authenticated(String)
    case unauthenticated
    case authorizing
    case unavailable(String)
    case failed(String)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .checking, .authorizing:
            return true
        case .authenticated, .unauthenticated, .unavailable, .failed:
            return false
        }
    }

    var statusText: String {
        switch self {
        case .checking:
            return "正在检查 Codex 登录状态…"
        case let .authenticated(summary):
            return summary
        case .unauthenticated:
            return "未登录，首次发送任务时会打开 Codex 官方登录流程。"
        case .authorizing:
            return "正在等待浏览器授权完成…"
        case let .unavailable(message):
            return message
        case let .failed(message):
            return message
        }
    }
}
