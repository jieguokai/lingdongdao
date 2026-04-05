import Foundation

package struct CodexLogEvent: Sendable {
    package let state: CodexState
    package let title: String
    package let detail: String
    package let timestamp: Date
    package let source: String?
    package let command: String?
    package let sessionID: String?
    package let exitCode: Int?
    package let responsePreview: String?
    package let usageSummary: String?
    package let phase: String?
    package let errorSummary: String?
    package let approvalReason: String?
    package let approvalActions: [CodexApprovalAction]
}

package struct CodexLogEventParser {
    private let iso8601Formatter = ISO8601DateFormatter()

    package init() {}

    package func parse(line: String) throws -> CodexLogEvent {
        if let event = try parseJSON(line: line) {
            return event
        }
        if let event = parseKeyValue(line: line) {
            return event
        }
        throw CodexLogParsingError.unrecognizedLine(line)
    }

    private func parseJSON(line: String) throws -> CodexLogEvent? {
        guard let data = line.data(using: .utf8) else { return nil }
        guard let rawPayload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let rawState = rawPayload["state"] as? String else { return nil }
        guard let state = state(from: rawState) else {
            throw CodexLogParsingError.invalidState(rawState)
        }
        return CodexLogEvent(
            state: state,
            title: string(from: rawPayload["title"]) ?? state.dynamicIslandTitle,
            detail: string(from: rawPayload["detail"]) ?? "",
            timestamp: string(from: rawPayload["timestamp"]).flatMap(iso8601Formatter.date(from:)) ?? .now,
            source: string(from: rawPayload["source"]),
            command: string(from: rawPayload["command"]),
            sessionID: string(from: rawPayload["sessionId"]) ?? string(from: rawPayload["sessionID"]),
            exitCode: int(from: rawPayload["exitCode"]),
            responsePreview: string(from: rawPayload["responsePreview"]),
            usageSummary: string(from: rawPayload["usageSummary"]),
            phase: string(from: rawPayload["phase"]),
            errorSummary: string(from: rawPayload["errorSummary"]),
            approvalReason: string(from: rawPayload["approvalReason"]),
            approvalActions: approvalActions(from: rawPayload["approvalActions"])
        )
    }

    private func parseKeyValue(line: String) -> CodexLogEvent? {
        let pairs = line
            .split(separator: " ")
            .compactMap { token -> (String, String)? in
                let pieces = token.split(separator: "=", maxSplits: 1).map(String.init)
                guard pieces.count == 2 else { return nil }
                return (pieces[0], pieces[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
            }

        let dictionary = Dictionary(uniqueKeysWithValues: pairs)
        guard
            let rawState = dictionary["state"],
            let state = state(from: rawState),
            let title = dictionary["title"],
            let detail = dictionary["detail"]
        else {
            return nil
        }

        let timestamp = dictionary["timestamp"].flatMap(iso8601Formatter.date(from:)) ?? .now
        return CodexLogEvent(
            state: state,
            title: title,
            detail: detail,
            timestamp: timestamp,
            source: dictionary["source"],
            command: dictionary["command"],
            sessionID: dictionary["sessionId"] ?? dictionary["sessionID"],
            exitCode: dictionary["exitCode"].flatMap(Int.init),
            responsePreview: dictionary["responsePreview"],
            usageSummary: dictionary["usageSummary"],
            phase: dictionary["phase"],
            errorSummary: dictionary["errorSummary"],
            approvalReason: dictionary["approvalReason"],
            approvalActions: []
        )
    }

    private func state(from rawState: String) -> CodexState? {
        switch rawState.lowercased() {
        case "typing":
            return .typing
        case "awaiting_reply", "awaitingreply", "waiting_for_reply", "needs_user_reply", "needsuserreply":
            return .awaitingReply
        case "awaiting_approval":
            return .awaitingApproval
        case "awaitingapproval":
            return .awaitingApproval
        default:
            return CodexState(rawValue: rawState.lowercased())
        }
    }

    private func string(from value: Any?) -> String? {
        value as? String
    }

    private func int(from value: Any?) -> Int? {
        value as? Int
    }

    private func approvalActions(from value: Any?) -> [CodexApprovalAction] {
        guard let array = value as? [Any] else { return [] }

        return array.enumerated().compactMap { index, element in
            if let raw = element as? String {
                return CodexApprovalAction(
                    id: "approval-\(index)",
                    label: raw,
                    role: inferredRole(from: raw),
                    actionPayload: raw
                )
            }

            guard let dictionary = element as? [String: Any] else { return nil }
            let label = (dictionary["label"] as? String) ?? (dictionary["title"] as? String) ?? (dictionary["name"] as? String)
            guard let label else { return nil }
            let id = (dictionary["id"] as? String) ?? "approval-\(index)"
            let role = (dictionary["role"] as? String).flatMap(role(from:)) ?? inferredRole(from: label)
            let actionPayload = payloadString(from: dictionary["actionPayload"] ?? dictionary["payload"] ?? dictionary["value"] ?? label)
            return CodexApprovalAction(
                id: id,
                label: label,
                role: role,
                actionPayload: actionPayload
            )
        }
    }

    private func role(from rawRole: String) -> CodexApprovalAction.Role? {
        switch rawRole.lowercased() {
        case "approve", "approved", "accept", "continue", "yes":
            return .approve
        case "reject", "denied", "abort", "cancel", "no":
            return .reject
        default:
            return .neutral
        }
    }

    private func inferredRole(from label: String) -> CodexApprovalAction.Role {
        role(from: label) ?? .neutral
    }

    private func payloadString(from value: Any) -> String {
        if let string = value as? String {
            return string
        }
        if let data = try? JSONSerialization.data(withJSONObject: value),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "\(value)"
    }
}

enum CodexLogParsingError: LocalizedError {
    case invalidState(String)
    case unrecognizedLine(String)

    var errorDescription: String? {
        switch self {
        case let .invalidState(value):
            "日志事件中包含不支持的状态“\(value)”。"
        case let .unrecognizedLine(line):
            "无法解析日志行：\(line)"
        }
    }
}
