import Foundation

@MainActor
final class SocketEventCodexProvider: PlaceholderCodexProvider {
    init() {
        super.init(
            kind: .socketEvent,
            title: "Socket source not connected",
            detail: "Use this mode when a local Codex daemon can push status events over a socket."
        )
    }
}
