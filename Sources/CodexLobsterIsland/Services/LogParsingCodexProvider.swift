import Foundation

@MainActor
final class LogParsingCodexProvider: CodexStatusProviding {
    private let logFileURL: URL
    private let pollInterval: TimeInterval
    private let fileManager: FileManager
    private let parser: CodexLogEventParser
    private var timer: Timer?
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private var lastObservedLine: String?
    private(set) var latestSnapshot: CodexStatusSnapshot

    init(
        logFileURL: URL = LogParsingCodexProvider.defaultLogFileURL(),
        pollInterval: TimeInterval = 3.0,
        fileManager: FileManager = .default,
        parser: CodexLogEventParser = CodexLogEventParser()
    ) {
        self.logFileURL = logFileURL
        self.pollInterval = pollInterval
        self.fileManager = fileManager
        self.parser = parser

        let timestamp = Date()
        let task = CodexTask(
            title: "Watching Codex log file",
            detail: "Waiting for \(logFileURL.path)",
            state: .idle,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        self.latestSnapshot = CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        publishCurrentSnapshot()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func advance() -> CodexStatusSnapshot {
        publishCurrentSnapshot()
        return latestSnapshot
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.publishCurrentSnapshot()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func publishCurrentSnapshot() {
        let now = Date()

        do {
            guard fileManager.fileExists(atPath: logFileURL.path) else {
                latestSnapshot = makeSnapshot(
                    state: .idle,
                    title: "Watching Codex log file",
                    detail: "No log file found at \(logFileURL.path)",
                    timestamp: now,
                    resetStart: false
                )
                onUpdate?(latestSnapshot)
                return
            }

            let content = try String(contentsOf: logFileURL, encoding: .utf8)
            guard let line = content.split(whereSeparator: \.isNewline).reversed().first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
                latestSnapshot = makeSnapshot(
                    state: .idle,
                    title: "Codex log is empty",
                    detail: "Waiting for structured events in \(logFileURL.lastPathComponent)",
                    timestamp: now,
                    resetStart: false
                )
                onUpdate?(latestSnapshot)
                return
            }

            let lineValue = String(line)
            if lineValue == lastObservedLine {
                onUpdate?(latestSnapshot)
                return
            }

            let event = try parser.parse(line: lineValue)
            lastObservedLine = lineValue
            latestSnapshot = makeSnapshot(
                state: event.state,
                title: event.title,
                detail: event.detail,
                timestamp: event.timestamp,
                resetStart: latestSnapshot.state != event.state
            )
        } catch {
            latestSnapshot = makeSnapshot(
                state: .error,
                title: "Log parser failed",
                detail: error.localizedDescription,
                timestamp: now,
                resetStart: latestSnapshot.state != .error
            )
        }

        onUpdate?(latestSnapshot)
    }

    private func makeSnapshot(
        state: CodexState,
        title: String,
        detail: String,
        timestamp: Date,
        resetStart: Bool
    ) -> CodexStatusSnapshot {
        let startedAt = resetStart ? timestamp : latestSnapshot.task.startedAt
        let task = CodexTask(
            title: title,
            detail: detail,
            state: state,
            startedAt: startedAt,
            updatedAt: timestamp
        )
        return CodexStatusSnapshot(state: state, task: task, updatedAt: timestamp)
    }

    private static func defaultLogFileURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["CODEX_LOBSTER_LOG_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Codex")
            .appendingPathComponent("codex-status.log")
    }
}
