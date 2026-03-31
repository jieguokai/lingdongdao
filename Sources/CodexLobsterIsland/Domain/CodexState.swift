import Foundation

package enum CodexState: String, Codable, CaseIterable, Sendable {
    case idle
    case running
    case success
    case error

    var displayName: String {
        switch self {
        case .idle:
            "空闲"
        case .running:
            "运行中"
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
        case .running:
            "bolt.circle.fill"
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
        case .running:
            "运行中"
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
        case .running:
            "持续处理中"
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
        case .running:
            "工作中"
        case .success:
            "已完成"
        case .error:
            "出错了"
        }
    }

    var soundResourceName: String? {
        switch self {
        case .success:
            "success"
        case .error:
            "error"
        case .idle, .running:
            nil
        }
    }
}
