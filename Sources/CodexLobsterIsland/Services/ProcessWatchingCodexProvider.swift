import Foundation

@MainActor
final class ProcessWatchingCodexProvider: CodexStatusProviding, CodexProviderInspectable {
    private let processQuery: String
    private let pollInterval: TimeInterval
    private let shellRunner: ShellCommandRunning
    private var timer: Timer?
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private var lastObservedCommand: String?
    private var wasRunning = false
    private var lastErrorMessage: String?
    private(set) var latestSnapshot: CodexStatusSnapshot

    var providerKind: CodexProviderKind { .processWatcher }
    var providerStatusSummary: String { "进程监听" }
    var providerStatusDetail: String { "pgrep -fal \(processQuery)" }
    var lastProviderError: String? { lastErrorMessage }

    init(
        processQuery: String = "codex",
        pollInterval: TimeInterval = 3.0,
        shellRunner: ShellCommandRunning = ShellCommandRunner()
    ) {
        self.processQuery = processQuery
        self.pollInterval = pollInterval
        self.shellRunner = shellRunner

        let timestamp = Date()
        let task = CodexTask(
            title: "正在监听本地 Codex 进程",
            detail: "等待匹配“\(processQuery)”的进程。",
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
            let result = try shellRunner.run("/usr/bin/pgrep", arguments: ["-fal", processQuery])
            let matches = parseMatches(from: result.stdout)
            lastErrorMessage = nil

            if let active = matches.first {
                wasRunning = true
                lastObservedCommand = active.command
                latestSnapshot = makeSnapshot(
                    state: .running,
                    title: matches.count == 1 ? "Codex 运行中" : "Codex 正在 \(matches.count) 个进程中运行",
                    detail: active.command,
                    now: now
                )
            } else if wasRunning {
                wasRunning = false
                latestSnapshot = makeSnapshot(
                    state: .success,
                    title: "Codex 活动已结束",
                    detail: lastObservedCommand ?? "最近检测到的 Codex 进程已正常退出。",
                    now: now
                )
            } else {
                latestSnapshot = makeSnapshot(
                    state: .idle,
                    title: "正在监听本地 Codex 进程",
                    detail: "当前没有匹配“\(processQuery)”的活动进程。",
                    now: now
                )
            }
        } catch {
            wasRunning = false
            lastErrorMessage = error.localizedDescription
            latestSnapshot = makeSnapshot(
                state: .error,
                title: "进程监听失败",
                detail: error.localizedDescription,
                now: now
            )
        }

        onUpdate?(latestSnapshot)
    }

    private func makeSnapshot(state: CodexState, title: String, detail: String, now: Date) -> CodexStatusSnapshot {
        let startedAt = latestSnapshot.state == state ? latestSnapshot.task.startedAt : now
        let task = CodexTask(
            title: title,
            detail: detail,
            state: state,
            startedAt: startedAt,
            updatedAt: now
        )
        return CodexStatusSnapshot(state: state, task: task, updatedAt: now)
    }

    private func parseMatches(from output: String) -> [ProcessMatch] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let value = String(line)
                guard !value.contains("pgrep -fal \(processQuery)") else { return nil }
                let pieces = value.split(separator: " ", maxSplits: 1).map(String.init)
                guard pieces.count == 2, let pid = Int32(pieces[0]) else { return nil }
                return ProcessMatch(pid: pid, command: pieces[1])
            }
    }
}

private struct ProcessMatch {
    let pid: Int32
    let command: String
}
