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
}

package struct CodexLogEventParser {
    private let decoder = JSONDecoder()
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
        guard let payload = try? decoder.decode(JSONPayload.self, from: data) else { return nil }
        guard let state = CodexState(rawValue: payload.state.lowercased()) else {
            throw CodexLogParsingError.invalidState(payload.state)
        }
        return CodexLogEvent(
            state: state,
            title: payload.title,
            detail: payload.detail,
            timestamp: iso8601Formatter.date(from: payload.timestamp) ?? .now,
            source: payload.source,
            command: payload.command,
            sessionID: payload.sessionID,
            exitCode: payload.exitCode,
            responsePreview: payload.responsePreview,
            usageSummary: payload.usageSummary,
            phase: payload.phase,
            errorSummary: payload.errorSummary
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
            let state = CodexState(rawValue: rawState.lowercased()),
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
            errorSummary: dictionary["errorSummary"]
        )
    }
}

private struct JSONPayload: Decodable {
    let state: String
    let title: String
    let detail: String
    let timestamp: String
    let source: String?
    let command: String?
    let sessionID: String?
    let exitCode: Int?
    let responsePreview: String?
    let usageSummary: String?
    let phase: String?
    let errorSummary: String?

    private enum CodingKeys: String, CodingKey {
        case state
        case title
        case detail
        case timestamp
        case source
        case command
        case sessionID = "sessionId"
        case exitCode
        case responsePreview
        case usageSummary
        case phase
        case errorSummary
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
