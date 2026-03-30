import Foundation

@MainActor
final class LogParsingCodexProvider: PlaceholderCodexProvider {
    init() {
        super.init(
            kind: .logParser,
            title: "Log parser not connected",
            detail: "This source will map structured Codex logs into island snapshots later."
        )
    }
}
