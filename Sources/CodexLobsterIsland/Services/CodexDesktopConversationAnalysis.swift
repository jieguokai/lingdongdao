import Foundation

struct CodexDesktopConversationAnalysis: Equatable {
    let lines: [String]
    let summary: String?
    let approvalReason: String?
    let replyReason: String?
    let indicatesAwaitingReply: Bool
    let indicatesError: Bool

    init(lines: [String]) {
        self.lines = lines
        self.summary = Self.resolveSummary(from: lines)
        self.approvalReason = Self.resolveApprovalReason(from: lines)
        self.replyReason = Self.resolveReplyReason(from: lines)
        self.indicatesAwaitingReply = replyReason != nil
        self.indicatesError = Self.resolveErrorSignal(from: lines)
    }
}

private extension CodexDesktopConversationAnalysis {
    static func resolveSummary(from lines: [String]) -> String? {
        lines.first(where: { $0.count >= 12 && !$0.hasPrefix("›") })
    }

    static func resolveApprovalReason(from lines: [String]) -> String? {
        lines.first { line in
            let lowercased = line.lowercased()
            return approvalPromptTerms.contains(where: lowercased.contains)
        }
    }

    static func resolveReplyReason(from lines: [String]) -> String? {
        let candidateWindow = Array(lines.prefix(6))
        let bestMatch = candidateWindow.enumerated()
            .compactMap { offset, line -> (score: Int, offset: Int, line: String)? in
                let score = replyPromptScore(for: line)
                guard score >= 4 else { return nil }
                return (score, offset, line)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.offset < rhs.offset
            }
            .first

        return bestMatch?.line
    }

    static func resolveErrorSignal(from lines: [String]) -> Bool {
        lines.contains { line in
            let lowercased = line.lowercased()
            return ["错误", "失败", "error", "invalid", "forbidden", "denied"].contains(where: lowercased.contains)
        }
    }

    static func replyPromptScore(for line: String) -> Int {
        let lowercased = line.lowercased()
        var score = 0

        if replyPromptTerms.contains(where: lowercased.contains) {
            score += 5
        }

        if optionPromptTerms.contains(where: lowercased.contains) {
            score += 4
        }

        if line.contains("?") || line.contains("？") {
            score += 2
        }

        if replyQuestionIndicators.contains(where: lowercased.contains) {
            score += 2
        }

        if line.hasPrefix("请") || lowercased.hasPrefix("please") || lowercased.hasPrefix("could you") || lowercased.hasPrefix("would you") {
            score += 1
        }

        return score
    }

    static let approvalPromptTerms: [String] = [
        "需要你的确认",
        "等待确认",
        "请确认",
        "确认后继续",
        "是否继续",
        "批准后继续",
        "approval required",
        "awaiting approval",
        "needs approval",
        "confirm to continue",
        "approve to continue"
    ]

    static let replyPromptTerms: [String] = [
        "请提供",
        "请补充",
        "请告诉我",
        "请说明",
        "请明确",
        "还需要你",
        "需要更多信息",
        "补充一下",
        "补充说明",
        "你希望我",
        "你想让我",
        "你更希望",
        "你偏向",
        "请确认一下你的需求",
        "请问你",
        "please provide",
        "please share",
        "please clarify",
        "please choose",
        "need more information",
        "could you share",
        "could you clarify",
        "what would you like",
        "which option",
        "which direction",
        "which approach",
        "how would you like",
        "do you want me to",
        "would you like me to",
        "can you confirm",
        "should i"
    ]

    static let optionPromptTerms: [String] = [
        "哪个方案",
        "哪种方式",
        "哪一种",
        "选项",
        "方案",
        "偏向",
        "倾向",
        "请选择",
        "是否要",
        "要不要",
        "which option",
        "which one",
        "which approach",
        "which direction",
        "choose one",
        "pick one"
    ]

    static let replyQuestionIndicators: [String] = [
        "你",
        "你的",
        "什么",
        "哪个",
        "哪种",
        "怎么",
        "是否",
        "要不要",
        "what",
        "which",
        "how",
        "could you",
        "can you",
        "would you",
        "please"
    ]
}
