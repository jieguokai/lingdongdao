import Foundation

@MainActor
final class ProcessWatchingCodexProvider: PlaceholderCodexProvider {
    init() {
        super.init(
            kind: .processWatcher,
            title: "Process watcher not connected",
            detail: "Select this source when you are ready to watch a local Codex process."
        )
    }
}
