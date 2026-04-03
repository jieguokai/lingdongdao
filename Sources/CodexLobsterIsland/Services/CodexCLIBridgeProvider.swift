import Foundation

@MainActor
final class CodexCLIBridgeProvider: CodexStatusProviding, CodexProviderInspectable {
    private let socketProvider: SocketEventCodexProvider
    private let logFileURL: URL
    private let fileManager: FileManager
    private let parser: CodexLogEventParser
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private var lastErrorMessage: String?
    private var lastLiveEventAt: Date?
    private var currentSessionID: String?
    private var currentCommandName: String?
    private var lastExitCode: Int?
    private let codexBinaryPath: String?
    private(set) var currentProviderSession: CodexProviderSessionSummary?
    private(set) var recentProviderSessions: [CodexProviderSessionSummary] = []
    private(set) var latestSnapshot: CodexStatusSnapshot

    var providerKind: CodexProviderKind { .codexCLI }
    var providerStatusSummary: String { "Codex CLI Bridge" }
    var providerStatusDetail: String { "\(logFileURL.path) · tcp://127.0.0.1:\(port)" }
    var lastProviderError: String? { socketProvider.lastProviderError ?? lastErrorMessage }
    var providerConnectionLabel: String? {
        if codexBinaryPath == nil {
            return "Codex CLI 不可用"
        }
        if isProviderConnected {
            return "真实 Codex 运行中"
        }
        if let lastExitCode {
            return lastExitCode == 0 ? "最近 Codex 会话已完成" : "最近 Codex 会话失败"
        }
        if currentSessionID != nil {
            return "最近 Codex 会话已记录"
        }
        return "等待 Codex CLI 桥接"
    }
    var providerConnectionDetail: String? {
        let sessionLine = currentSessionID.map { sessionID in
            if let currentCommandName {
                return "当前线程：\(sessionID) · \(currentCommandName)"
            }
            return "当前线程：\(sessionID)"
        }
        let binaryLine = codexBinaryPath.map { "CLI：\($0)" } ?? "未发现 codex 可执行文件，可设置 CODEX_LOBSTER_CODEX_BIN。"
        let exitLine = lastExitCode.map { "最近退出码：\($0)" }
        let eventLine = lastLiveEventAt.map { "最近实时事件：\($0.formatted(date: .omitted, time: .standard))" }

        if isProviderConnected {
            return [sessionLine, eventLine, binaryLine].compactMap { $0 }.joined(separator: "\n")
        }
        if fileManager.fileExists(atPath: logFileURL.path) {
            return [sessionLine, exitLine, eventLine, binaryLine, "已从桥接日志恢复最近状态，等待下一次 CLI 事件。"]
                .compactMap { $0 }
                .joined(separator: "\n")
        }
        return [sessionLine, binaryLine, "运行 scripts/codex-bridge.py 后会自动建立实时连接。"]
            .compactMap { $0 }
            .joined(separator: "\n")
    }
    var isProviderConnected: Bool {
        guard let lastLiveEventAt else { return false }
        return Date().timeIntervalSince(lastLiveEventAt) <= Self.bridgeHeartbeatInterval
    }

    private var port: UInt16 {
        if let value = UInt16(ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_PORT"] ?? "") {
            return value
        }
        return 45541
    }

    init(
        logFileURL: URL = CodexCLIBridgeProvider.defaultLogFileURL(),
        fileManager: FileManager = .default,
        parser: CodexLogEventParser = CodexLogEventParser()
    ) {
        self.logFileURL = logFileURL
        self.fileManager = fileManager
        self.parser = parser
        self.codexBinaryPath = CodexCLIBridgeProvider.resolveCodexBinaryPath(fileManager: fileManager)
        self.latestSnapshot = CodexCLIBridgeProvider.makeWaitingSnapshot(logFileURL: logFileURL)
        self.socketProvider = SocketEventCodexProvider(
            port: CodexCLIBridgeProvider.defaultPort(),
            parser: parser,
            publishesInitialSnapshot: false,
            publishesReadySnapshot: false
        )

        if let bootstrap = Self.loadSnapshot(from: logFileURL, fileManager: fileManager, parser: parser) {
            self.latestSnapshot = bootstrap.snapshot
            self.lastErrorMessage = bootstrap.errorMessage
            self.currentSessionID = bootstrap.sessionID
            self.currentCommandName = bootstrap.commandName
            self.lastExitCode = bootstrap.exitCode
            self.currentProviderSession = bootstrap.sessionSummary
        }
        self.recentProviderSessions = Self.loadRecentSessions(from: logFileURL, fileManager: fileManager, parser: parser)
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        refreshFromLogIfAvailable()
        onUpdate(latestSnapshot)

        socketProvider.start { [weak self] snapshot in
            guard let self else { return }
            self.latestSnapshot = snapshot
            self.lastErrorMessage = nil
            self.lastLiveEventAt = snapshot.updatedAt
            if let result = Self.loadSnapshot(from: self.logFileURL, fileManager: self.fileManager, parser: self.parser) {
                self.latestSnapshot = result.snapshot
                self.currentSessionID = result.sessionID
                self.currentCommandName = result.commandName
                self.lastExitCode = result.exitCode
                self.currentProviderSession = result.sessionSummary
            }
            self.recentProviderSessions = Self.loadRecentSessions(from: self.logFileURL, fileManager: self.fileManager, parser: self.parser)
            self.onUpdate?(self.latestSnapshot)
        }
    }

    func stop() {
        socketProvider.stop()
    }

    func advance() -> CodexStatusSnapshot {
        refreshFromLogIfAvailable()
        onUpdate?(latestSnapshot)
        return latestSnapshot
    }

    private func refreshFromLogIfAvailable() {
        guard fileManager.fileExists(atPath: logFileURL.path) else { return }

        guard let result = Self.loadSnapshot(from: logFileURL, fileManager: fileManager, parser: parser) else {
            return
        }

        latestSnapshot = result.snapshot
        lastErrorMessage = result.errorMessage
        currentSessionID = result.sessionID
        currentCommandName = result.commandName
        lastExitCode = result.exitCode
        currentProviderSession = result.sessionSummary
        recentProviderSessions = Self.loadRecentSessions(from: logFileURL, fileManager: fileManager, parser: parser)
    }

    private static func loadSnapshot(
        from logFileURL: URL,
        fileManager: FileManager,
        parser: CodexLogEventParser
    ) -> SnapshotLoadResult? {
        do {
            guard fileManager.fileExists(atPath: logFileURL.path) else { return nil }
            let content = try String(contentsOf: logFileURL, encoding: .utf8)
            guard let line = content
                .split(whereSeparator: \.isNewline)
                .reversed()
                .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            else {
                return nil
            }

            let event = try parser.parse(line: String(line))
            let task = CodexTask(
                title: event.title,
                detail: event.detail,
                state: event.state,
                startedAt: event.timestamp,
                updatedAt: event.timestamp
            )
            let snapshot = CodexStatusSnapshot(state: event.state, task: task, updatedAt: event.timestamp)
            return SnapshotLoadResult(
                snapshot: snapshot,
                errorMessage: nil,
                sessionID: event.sessionID,
                commandName: event.command,
                exitCode: event.exitCode,
                sessionSummary: makeSessionSummary(from: event)
            )
        } catch {
            let snapshot = makeErrorSnapshot(logFileURL: logFileURL, detail: error.localizedDescription)
            return SnapshotLoadResult(
                snapshot: snapshot,
                errorMessage: error.localizedDescription,
                sessionID: nil,
                commandName: nil,
                exitCode: nil,
                sessionSummary: nil
            )
        }
    }

    private static func makeSessionSummary(from event: CodexLogEvent) -> CodexProviderSessionSummary? {
        guard let sessionID = event.sessionID else { return nil }
        return CodexProviderSessionSummary(
            id: sessionID,
            state: event.state,
            title: event.title,
            detail: event.detail,
            commandName: event.command,
            exitCode: event.exitCode,
            responsePreview: event.responsePreview,
            usageSummary: event.usageSummary,
            phase: event.phase,
            errorSummary: event.errorSummary,
            timestamp: event.timestamp
        )
    }

    private static func loadRecentSessions(
        from logFileURL: URL,
        fileManager: FileManager,
        parser: CodexLogEventParser,
        limit: Int = 5
    ) -> [CodexProviderSessionSummary] {
        guard fileManager.fileExists(atPath: logFileURL.path) else { return [] }
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else { return [] }

        var seenSessionIDs = Set<String>()
        var sessions: [CodexProviderSessionSummary] = []

        for line in content.split(whereSeparator: \.isNewline).reversed() {
            guard let event = try? parser.parse(line: String(line)),
                  let sessionID = event.sessionID,
                  !seenSessionIDs.contains(sessionID)
            else {
                continue
            }

            seenSessionIDs.insert(sessionID)
            sessions.append(
                CodexProviderSessionSummary(
                    id: sessionID,
                    state: event.state,
                    title: event.title,
                    detail: event.detail,
                    commandName: event.command,
                    exitCode: event.exitCode,
                    responsePreview: event.responsePreview,
                    usageSummary: event.usageSummary,
                    phase: event.phase,
                    errorSummary: event.errorSummary,
                    timestamp: event.timestamp
                )
            )

            if sessions.count >= limit {
                break
            }
        }

        return sessions
    }

    private static func makeWaitingSnapshot(logFileURL: URL) -> CodexStatusSnapshot {
        let timestamp = Date()
        let task = CodexTask(
            title: "正在等待 Codex CLI 事件",
            detail: "使用 codex-bridge.py 写入 \(logFileURL.lastPathComponent)",
            state: .idle,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        return CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
    }

    private static func makeErrorSnapshot(logFileURL: URL, detail: String) -> CodexStatusSnapshot {
        let timestamp = Date()
        let task = CodexTask(
            title: "Codex CLI Bridge 读取失败",
            detail: "\(logFileURL.path): \(detail)",
            state: .error,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        return CodexStatusSnapshot(state: .error, task: task, updatedAt: timestamp)
    }

    private static func defaultLogFileURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_LOG_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".codex-lobster-island")
            .appendingPathComponent("codex-events.jsonl")
    }

    private static func defaultPort() -> UInt16 {
        if let override = ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_PORT"], let value = UInt16(override) {
            return value
        }
        return 45541
    }

    private static var bridgeHeartbeatInterval: TimeInterval {
        if let override = ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_HEARTBEAT_SECONDS"],
           let value = TimeInterval(override) {
            return value
        }
        return 8
    }

    private static func resolveCodexBinaryPath(fileManager: FileManager) -> String? {
        let environment = ProcessInfo.processInfo.environment
        if let override = environment["CODEX_LOBSTER_CODEX_BIN"], fileManager.isExecutableFile(atPath: override) {
            return override
        }
        if let path = environment["PATH"] {
            for candidateRoot in path.split(separator: ":").map(String.init) {
                let candidate = URL(fileURLWithPath: candidateRoot).appendingPathComponent("codex").path
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }
        let bundled = "/Applications/Codex.app/Contents/Resources/codex"
        if fileManager.isExecutableFile(atPath: bundled) {
            return bundled
        }
        return nil
    }
}

private struct SnapshotLoadResult {
    let snapshot: CodexStatusSnapshot
    let errorMessage: String?
    let sessionID: String?
    let commandName: String?
    let exitCode: Int?
    let sessionSummary: CodexProviderSessionSummary?
}
