import Foundation

enum CodexRiskLevel: String, Equatable, Sendable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:
            "低风险"
        case .medium:
            "中风险"
        case .high:
            "高风险"
        }
    }

    static func inferred(from state: CodexState) -> CodexRiskLevel {
        switch state {
        case .awaitingApproval, .error:
            .high
        case .running:
            .medium
        case .idle, .typing, .awaitingReply, .success:
            .low
        }
    }
}
