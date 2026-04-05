import Foundation

struct CodexDesktopStateInferenceContext {
    let latestState: CodexState
    let prompt: String
    let promptFocused: Bool
    let promptChanged: Bool
    let hasRecentTypingActivity: Bool
    let hasApprovalPrompt: Bool
    let hasApprovalActions: Bool
    let analysis: CodexDesktopConversationAnalysis?
    let hasRecentOCRActivity: Bool
}

enum CodexDesktopStateInference {
    static func inferState(_ context: CodexDesktopStateInferenceContext) -> CodexState {
        if context.promptFocused, !context.prompt.isEmpty,
           (context.hasRecentTypingActivity || context.promptChanged) {
            return .typing
        }

        if context.hasApprovalPrompt, context.hasApprovalActions {
            return .awaitingApproval
        }

        if context.analysis?.indicatesError == true {
            return .error
        }

        if shouldAwaitReply(context) {
            return .awaitingReply
        }

        if context.latestState == .typing, context.prompt.isEmpty {
            return .running
        }

        if context.hasRecentOCRActivity {
            return .running
        }

        if [.running, .awaitingReply, .awaitingApproval, .typing].contains(context.latestState),
           context.analysis?.summary != nil {
            return .success
        }

        return .idle
    }

    private static func shouldAwaitReply(_ context: CodexDesktopStateInferenceContext) -> Bool {
        guard !context.hasApprovalPrompt, !context.hasApprovalActions else { return false }
        guard context.prompt.isEmpty else { return false }
        guard let analysis = context.analysis, analysis.indicatesAwaitingReply else { return false }
        guard context.latestState != .error else { return false }
        return true
    }
}
