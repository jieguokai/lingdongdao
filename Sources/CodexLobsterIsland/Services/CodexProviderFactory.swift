import Foundation

@MainActor
enum CodexProviderFactory {
    static func makeProvider(kind: CodexProviderKind) -> CodexStatusProviding {
        switch kind {
        case .mock:
            MockStatusGenerator()
        case .desktopThread:
            CodexDesktopThreadProvider()
        case .codexCLI:
            CodexCLIBridgeProvider()
        case .processWatcher:
            ProcessWatchingCodexProvider()
        case .logParser:
            LogParsingCodexProvider()
        case .socketEvent:
            SocketEventCodexProvider()
        }
    }
}
