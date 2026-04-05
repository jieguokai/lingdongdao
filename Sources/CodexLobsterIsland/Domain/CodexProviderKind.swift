import Foundation

enum CodexProviderKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case mock
    case desktopThread
    case codexCLI
    case processWatcher
    case logParser
    case socketEvent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mock:
            "模拟演示"
        case .desktopThread:
            "Codex 桌面对话"
        case .codexCLI:
            "Codex CLI 桥接"
        case .processWatcher:
            "进程监听"
        case .logParser:
            "日志解析"
        case .socketEvent:
            "套接字事件"
        }
    }

    var subtitle: String {
        switch self {
        case .mock:
            "内置演示流程"
        case .desktopThread:
            "优先跟随当前 Codex Desktop 对话线程"
        case .codexCLI:
            "只通过桥接启动的真实 Codex CLI 同步状态"
        case .processWatcher:
            "观察本地 Codex 进程状态"
        case .logParser:
            "从结构化日志中读取状态"
        case .socketEvent:
            "通过本地套接字接收状态"
        }
    }

    static var userFacingCases: [CodexProviderKind] {
        [.desktopThread]
    }
}
