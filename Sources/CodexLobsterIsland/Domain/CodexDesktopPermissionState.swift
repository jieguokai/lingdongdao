import Foundation

struct CodexDesktopPermissionState: Equatable, Sendable {
    enum SyncPhase: Equatable, Sendable {
        case unauthorized
        case pendingRestart
        case readyInactive
        case attachedIdle
        case live
    }

    var accessibilityGranted: Bool
    var screenRecordingGranted: Bool
    var inputMonitoringGranted: Bool
    var phase: SyncPhase

    var isReady: Bool {
        accessibilityGranted
    }

    var hasMissingRequiredPermissions: Bool {
        !accessibilityGranted
    }

    var hasMissingPermissions: Bool {
        !accessibilityGranted || !screenRecordingGranted || !inputMonitoringGranted
    }

    var isLive: Bool {
        phase == .live
    }

    var isConnected: Bool {
        phase == .attachedIdle || phase == .live
    }

    var missingRequiredLabels: [String] {
        var labels: [String] = []
        if !accessibilityGranted {
            labels.append("辅助功能")
        }
        return labels
    }

    var missingOptionalLabels: [String] {
        var labels: [String] = []
        if !screenRecordingGranted {
            labels.append("屏幕录制")
        }
        if !inputMonitoringGranted {
            labels.append("输入监控")
        }
        return labels
    }

    var statusLabel: String {
        switch phase {
        case .unauthorized:
            return "桌面对话同步未启用"
        case .pendingRestart:
            return "桌面对话已授权，待重开"
        case .readyInactive:
            return "等待连接 Codex"
        case .attachedIdle:
            return inputMonitoringGranted ? "桌面对话已连接" : "桌面对话已连接（输入监听降级）"
        case .live:
            return inputMonitoringGranted ? "桌面对话同步中" : "桌面对话同步中（输入监听降级）"
        }
    }

    var statusDetail: String {
        switch phase {
        case .unauthorized:
            let required = missingRequiredLabels.joined(separator: "、")
            let optional = missingOptionalLabels.joined(separator: "、")
            let combined = ([required].filter { !$0.isEmpty } + [optional].filter { !$0.isEmpty }).joined(separator: "、")
            return "需要在系统设置里允许\(combined)，小龙虾才能完整同步当前 Codex Desktop 对话。首次安装会自动把辅助功能、屏幕录制和输入监控一起请求一次；之后 app 会改为静默检测，请用菜单栏或展开浮窗里的授权按钮继续触发。"
        case .pendingRestart:
            return "系统权限已授予，但当前会话还没生效。请重开小龙虾或重启 Codex Desktop。"
        case .readyInactive:
            if screenRecordingGranted && inputMonitoringGranted {
                return "已授权辅助功能、屏幕录制和输入监控。只要 Codex Desktop 正在运行，小龙虾就会尝试附着当前线程。"
            }
            if screenRecordingGranted {
                return "已授权辅助功能和屏幕录制；typing 会退化为较慢的文本变化检测。只要 Codex Desktop 正在运行，小龙虾就会尝试附着当前线程。"
            }
            if inputMonitoringGranted {
                return "已授权辅助功能。当前可同步连接和输入；若再授权屏幕录制，就能获得更稳定的执行、确认和反馈识别。只要 Codex Desktop 正在运行，小龙虾就会尝试附着当前线程。"
            }
            return "已授权辅助功能。当前可同步连接；typing 会退化为较慢的文本变化检测。若再授权屏幕录制，就能获得更稳定的执行、确认和反馈识别。只要 Codex Desktop 正在运行，小龙虾就会尝试附着当前线程。"
        case .attachedIdle:
            if screenRecordingGranted && inputMonitoringGranted {
                return "已附着到当前 Codex Desktop 对话，等待输入或输出变化。"
            }
            if screenRecordingGranted {
                return "已附着到当前 Codex Desktop 对话，等待输入或输出变化；typing 会回退为较慢的文本变化检测。"
            }
            if inputMonitoringGranted {
                return "已附着到当前 Codex Desktop 对话；当前可同步连接和输入，执行与确认识别会降级。"
            }
            return "已附着到当前 Codex Desktop 对话；typing 会回退为较慢的文本变化检测。"
        case .live:
            if screenRecordingGranted && inputMonitoringGranted {
                return "已连接当前 Codex Desktop 对话线程。"
            }
            if screenRecordingGranted {
                return "已连接当前 Codex Desktop 对话线程；typing 会回退为较慢的文本变化检测。"
            }
            if inputMonitoringGranted {
                return "已连接当前 Codex Desktop 对话线程；执行、确认和反馈识别会降级。"
            }
            return "已连接当前 Codex Desktop 对话线程；OCR 与 typing 都处于降级模式。"
        }
    }

    func updating(phase: SyncPhase) -> Self {
        Self(
            accessibilityGranted: accessibilityGranted,
            screenRecordingGranted: screenRecordingGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            phase: phase
        )
    }
}
