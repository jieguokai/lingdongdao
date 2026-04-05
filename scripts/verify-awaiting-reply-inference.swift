import Foundation

@main
struct VerifyAwaitingReplyInference {
    static func main() throws {
        try assertAwaitingReplyForClarificationPrompt()
        try assertAwaitingReplyForOptionSelection()
        try assertApprovalTakesPrecedence()
        try assertSuccessfulOutputDoesNotBecomeAwaitingReply()
        try assertTypingOverridesAwaitingReply()
        print("awaiting reply inference verification passed")
    }

    private static func assertAwaitingReplyForClarificationPrompt() throws {
        let state = inferState(
            latestState: .running,
            prompt: "",
            promptFocused: false,
            promptChanged: false,
            hasRecentTypingActivity: false,
            hasApprovalPrompt: false,
            hasApprovalActions: false,
            lines: [
                "请补充一下你希望我重点优化的部分？",
                "我已经看完当前实现。"
            ],
            hasRecentOCRActivity: false
        )
        guard state == .awaitingReply else {
            throw VerificationError("Expected clarification prompt to map to awaitingReply, got \(state.rawValue)")
        }
    }

    private static func assertAwaitingReplyForOptionSelection() throws {
        let state = inferState(
            latestState: .running,
            prompt: "",
            promptFocused: false,
            promptChanged: false,
            hasRecentTypingActivity: false,
            hasApprovalPrompt: false,
            hasApprovalActions: false,
            lines: [
                "你更偏向哪种方式？我可以走方案 A 或方案 B。",
                "两个方向我都能继续做。"
            ],
            hasRecentOCRActivity: false
        )
        guard state == .awaitingReply else {
            throw VerificationError("Expected option prompt to map to awaitingReply, got \(state.rawValue)")
        }
    }

    private static func assertApprovalTakesPrecedence() throws {
        let state = inferState(
            latestState: .running,
            prompt: "",
            promptFocused: false,
            promptChanged: false,
            hasRecentTypingActivity: false,
            hasApprovalPrompt: true,
            hasApprovalActions: true,
            lines: [
                "请确认后继续",
                "是否继续执行当前动作？"
            ],
            hasRecentOCRActivity: false
        )
        guard state == .awaitingApproval else {
            throw VerificationError("Expected approval prompt to stay in awaitingApproval, got \(state.rawValue)")
        }
    }

    private static func assertSuccessfulOutputDoesNotBecomeAwaitingReply() throws {
        let state = inferState(
            latestState: .running,
            prompt: "",
            promptFocused: false,
            promptChanged: false,
            hasRecentTypingActivity: false,
            hasApprovalPrompt: false,
            hasApprovalActions: false,
            lines: [
                "已完成本轮修复，所有校验通过。",
                "等待你的下一步指令。"
            ],
            hasRecentOCRActivity: false
        )
        guard state == .success else {
            throw VerificationError("Expected plain completion output to map to success, got \(state.rawValue)")
        }
    }

    private static func assertTypingOverridesAwaitingReply() throws {
        let state = inferState(
            latestState: .awaitingReply,
            prompt: "我选择方案 A",
            promptFocused: true,
            promptChanged: true,
            hasRecentTypingActivity: true,
            hasApprovalPrompt: false,
            hasApprovalActions: false,
            lines: [
                "你更偏向哪种方式？"
            ],
            hasRecentOCRActivity: false
        )
        guard state == .typing else {
            throw VerificationError("Expected active typing to override awaitingReply, got \(state.rawValue)")
        }
    }

    private static func inferState(
        latestState: CodexState,
        prompt: String,
        promptFocused: Bool,
        promptChanged: Bool,
        hasRecentTypingActivity: Bool,
        hasApprovalPrompt: Bool,
        hasApprovalActions: Bool,
        lines: [String],
        hasRecentOCRActivity: Bool
    ) -> CodexState {
        let analysis = CodexDesktopConversationAnalysis(lines: lines)
        return CodexDesktopStateInference.inferState(
            CodexDesktopStateInferenceContext(
                latestState: latestState,
                prompt: prompt,
                promptFocused: promptFocused,
                promptChanged: promptChanged,
                hasRecentTypingActivity: hasRecentTypingActivity,
                hasApprovalPrompt: hasApprovalPrompt,
                hasApprovalActions: hasApprovalActions,
                analysis: analysis,
                hasRecentOCRActivity: hasRecentOCRActivity
            )
        )
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
