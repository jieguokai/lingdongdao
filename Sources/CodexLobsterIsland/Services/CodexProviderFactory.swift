import Foundation

@MainActor
enum CodexProviderFactory {
    static func makeProvider(kind: CodexProviderKind) -> CodexStatusProviding {
        switch kind {
        case .mock:
            MockStatusGenerator()
        case .processWatcher:
            ProcessWatchingCodexProvider()
        case .logParser:
            LogParsingCodexProvider()
        case .socketEvent:
            SocketEventCodexProvider()
        }
    }
}
