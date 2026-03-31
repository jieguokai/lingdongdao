import Foundation

package struct CodexLogEvent: Sendable {
    package let state: CodexState
    package let title: String
    package let detail: String
    package let timestamp: Date
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
            timestamp: iso8601Formatter.date(from: payload.timestamp) ?? .now
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
        return CodexLogEvent(state: state, title: title, detail: detail, timestamp: timestamp)
    }
}

private struct JSONPayload: Decodable {
    let state: String
    let title: String
    let detail: String
    let timestamp: String
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
