import AppKit
import Foundation

@MainActor
final class CodexDesktopInputMonitor {
    private var globalKeyMonitor: Any?
    private(set) var lastTypingActivityAt: Date?

    func start() {
        guard globalKeyMonitor == nil else { return }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] _ in
            guard Self.isCodexFrontmost else { return }
            Task { @MainActor in
                self?.lastTypingActivityAt = Date()
            }
        }
    }

    func stop() {
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
        }
        globalKeyMonitor = nil
    }

    func hasRecentTypingActivity(within interval: TimeInterval) -> Bool {
        guard let lastTypingActivityAt else { return false }
        return Date().timeIntervalSince(lastTypingActivityAt) <= interval
    }

    private static var isCodexFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.openai.codex"
    }
}
