import Foundation

@MainActor
final class CodexCLIBridgeProvider: CodexStatusProviding, CodexProviderInspectable, CodexApprovalControlling {
    private let socketProvider: SocketEventCodexProvider
    private let logFileURL: URL
    private let actionDirectoryURL: URL
    private let fileManager: FileManager
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private var lastErrorMessage: String?
    private var lastLiveEventAt: Date?
    private var currentSessionID: String?
    private var currentCommandName: String?
    private var lastExitCode: Int?
    private var heartbeatTimer: Timer?
    private let codexBinaryPath: String?
    private var liveCurrentProviderSession: CodexProviderSessionSummary?
    private var liveRecentProviderSessions: [CodexProviderSessionSummary] = []
    private var highlightedStateHoldUntil: Date?
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
            return "bridge 实时同步中"
        }
        if lastLiveEventAt != nil {
            return "bridge 已断开"
        }
        return "等待 bridge"
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
        if lastLiveEventAt != nil {
            return [sessionLine, exitLine, eventLine, binaryLine, "bridge 已断开。你可以直接从菜单栏重新发起任务；兼容模式下也可运行 scripts/codex-island.sh 恢复同步。"]
                .compactMap { $0 }
                .joined(separator: "\n")
        }
        return [binaryLine, "尚未收到实时任务事件。你可以直接从菜单栏发起任务；兼容模式下也可运行 scripts/codex-island.sh 或 scripts/codex-bridge.py。"]
            .compactMap { $0 }
            .joined(separator: "\n")
    }
    var isProviderConnected: Bool {
        guard let lastLiveEventAt else { return false }
        return Date().timeIntervalSince(lastLiveEventAt) <= Self.bridgeHeartbeatInterval
    }
    var currentProviderSession: CodexProviderSessionSummary? {
        shouldRetainDisconnectedSessionContext ? liveCurrentProviderSession : nil
    }
    var recentProviderSessions: [CodexProviderSessionSummary] {
        shouldRetainDisconnectedSessionContext ? liveRecentProviderSessions : []
    }

    private var port: UInt16 {
        if let value = UInt16(ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_PORT"] ?? "") {
            return value
        }
        return 45541
    }

    init(
        logFileURL: URL = CodexCLIBridgeProvider.defaultLogFileURL(),
        actionDirectoryURL: URL = CodexCLIBridgeProvider.defaultActionDirectoryURL(),
        fileManager: FileManager = .default,
        parser: CodexLogEventParser = CodexLogEventParser()
    ) {
        self.logFileURL = logFileURL
        self.actionDirectoryURL = actionDirectoryURL
        self.fileManager = fileManager
        self.codexBinaryPath = CodexCLIBridgeProvider.resolveCodexBinaryPath(fileManager: fileManager)
        self.latestSnapshot = CodexCLIBridgeProvider.makeWaitingSnapshot(logFileURL: logFileURL)
        self.socketProvider = SocketEventCodexProvider(
            port: CodexCLIBridgeProvider.defaultPort(),
            parser: parser,
            publishesInitialSnapshot: false,
            publishesReadySnapshot: false
        )
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        startHeartbeatTimer()
        onUpdate(latestSnapshot)

        socketProvider.start { [weak self] snapshot in
            guard let self else { return }
            if let event = self.socketProvider.latestEvent {
                self.handleRealtimeEvent(event, snapshot: snapshot)
            } else {
                self.latestSnapshot = snapshot
            }
            self.onUpdate?(self.latestSnapshot)
        }
    }

    func stop() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        socketProvider.stop()
    }

    func advance() -> CodexStatusSnapshot {
        refreshConnectionState()
        onUpdate?(latestSnapshot)
        return latestSnapshot
    }

    func performApprovalAction(_ action: CodexApprovalAction) async throws {
        guard isProviderConnected, let sessionID = liveCurrentProviderSession?.id ?? currentSessionID else {
            throw CodexApprovalError.noActiveSession
        }

        let actionFileURL = actionDirectoryURL.appendingPathComponent("\(sessionID).jsonl")
        try fileManager.createDirectory(at: actionDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        let payload = try JSONEncoder().encode(BridgeApprovalCommand(action: action))
        guard let line = String(data: payload, encoding: .utf8) else {
            throw CodexApprovalError.invalidPayload
        }

        if fileManager.fileExists(atPath: actionFileURL.path) == false {
            fileManager.createFile(atPath: actionFileURL.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: actionFileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        if let data = (line + "\n").data(using: .utf8) {
            try handle.write(contentsOf: data)
        } else {
            throw CodexApprovalError.invalidPayload
        }
    }

    private func startHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshConnectionState()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    private func refreshConnectionState() {
        guard lastLiveEventAt != nil, isProviderConnected == false else { return }
        guard latestSnapshot.task.title != Self.waitingTitle else { return }
        if shouldRetainHighlightedState {
            return
        }
        if latestSnapshot.state == .error {
            return
        }

        latestSnapshot = Self.makeWaitingSnapshot(logFileURL: logFileURL)
        onUpdate?(latestSnapshot)
    }

    private func handleRealtimeEvent(_ event: CodexLogEvent, snapshot: CodexStatusSnapshot) {
        latestSnapshot = snapshot
        lastErrorMessage = nil
        lastLiveEventAt = event.timestamp
        currentSessionID = event.sessionID ?? currentSessionID
        currentCommandName = event.command ?? currentCommandName

        if let exitCode = event.exitCode {
            lastExitCode = exitCode
        } else if event.state == .typing || event.state == .running || event.state == .awaitingReply || event.state == .awaitingApproval {
            lastExitCode = nil
        }

        guard let sessionSummary = Self.makeSessionSummary(from: event) else { return }
        if Self.highlightRetainedStates.contains(sessionSummary.state) {
            highlightedStateHoldUntil = event.timestamp.addingTimeInterval(Self.highlightRetentionInterval)
        } else {
            highlightedStateHoldUntil = nil
        }
        upsertRecentSession(sessionSummary)
        liveCurrentProviderSession = liveRecentProviderSessions.first(where: { $0.id == sessionSummary.id }) ?? sessionSummary
    }

    private static func makeSessionSummary(from event: CodexLogEvent) -> CodexProviderSessionSummary? {
        guard let sessionID = event.sessionID else { return nil }
        let turn = CodexProviderTurnSummary(
            id: [
                event.state.rawValue,
                event.phase ?? "",
                event.title,
                event.detail,
                event.responsePreview ?? "",
                event.approvalReason ?? "",
                event.errorSummary ?? ""
            ].joined(separator: "|"),
            state: event.state,
            title: event.title,
            detail: event.detail,
            summary: event.responsePreview,
            approvalReason: event.approvalReason,
            approvalActions: event.approvalActions,
            phase: event.phase,
            errorSummary: event.errorSummary,
            timestamp: event.timestamp
        )
        return CodexProviderSessionSummary(
            id: sessionID,
            identitySeed: sessionID,
            source: "codex-cli-bridge",
            threadTitle: event.command ?? sessionID,
            state: event.state,
            title: event.title,
            detail: event.detail,
            commandName: event.command,
            exitCode: event.exitCode,
            responsePreview: event.responsePreview,
            usageSummary: event.usageSummary,
            phase: event.phase,
            errorSummary: event.errorSummary,
            approvalReason: event.approvalReason,
            approvalActions: event.approvalActions,
            timestamp: event.timestamp,
            turns: [turn]
        )
    }

    private func upsertRecentSession(_ session: CodexProviderSessionSummary) {
        let existingTurns = liveRecentProviderSessions.first(where: { $0.id == session.id })?.turns ?? liveCurrentProviderSession?.turns ?? []
        let mergedTurns: [CodexProviderTurnSummary]
        if let firstTurn = existingTurns.first, let nextTurn = session.turns.first, firstTurn.id == nextTurn.id {
            mergedTurns = [nextTurn] + existingTurns.dropFirst()
        } else {
            mergedTurns = Array((session.turns + existingTurns).prefix(3))
        }

        let mergedSession = CodexProviderSessionSummary(
            id: session.id,
            identitySeed: session.identitySeed,
            source: session.source,
            threadTitle: session.threadTitle,
            state: session.state,
            title: session.title,
            detail: session.detail,
            commandName: session.commandName,
            exitCode: session.exitCode,
            responsePreview: session.responsePreview,
            usageSummary: session.usageSummary,
            phase: session.phase,
            errorSummary: session.errorSummary,
            approvalReason: session.approvalReason,
            approvalActions: session.approvalActions,
            timestamp: session.timestamp,
            turns: mergedTurns
        )
        liveRecentProviderSessions.removeAll { $0.id == session.id }
        liveRecentProviderSessions.insert(mergedSession, at: 0)
        if liveRecentProviderSessions.count > 5 {
            liveRecentProviderSessions.removeLast(liveRecentProviderSessions.count - 5)
        }
        if liveCurrentProviderSession?.id == mergedSession.id {
            liveCurrentProviderSession = mergedSession
        }
    }

    private static func makeWaitingSnapshot(logFileURL: URL) -> CodexStatusSnapshot {
        let timestamp = Date()
        let task = CodexTask(
            title: waitingTitle,
            detail: "从菜单栏发起任务后，小龙虾会显示实时状态、声音提示和原生确认按钮。",
            state: .idle,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        return CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
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

    private static func defaultActionDirectoryURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["CODEX_LOBSTER_BRIDGE_ACTION_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".codex-lobster-island")
            .appendingPathComponent("actions")
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

    private var shouldRetainDisconnectedSessionContext: Bool {
        isProviderConnected || shouldRetainSessionContextAfterDisconnect
    }

    private var shouldRetainSessionContextAfterDisconnect: Bool {
        if let currentState = liveCurrentProviderSession?.state,
           currentState == .awaitingReply || currentState == .awaitingApproval || currentState == .error {
            return true
        }
        return shouldRetainHighlightedState
    }

    private var shouldRetainHighlightedState: Bool {
        guard let highlightedStateHoldUntil else { return false }
        return Date() < highlightedStateHoldUntil
    }

    private static let highlightRetentionInterval: TimeInterval = 2
    private static let highlightRetainedStates: Set<CodexState> = [.awaitingApproval, .success, .error]

    private static var waitingTitle: String {
        "正在等待 bridge 事件"
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

private struct BridgeApprovalCommand: Encodable {
    let id: String
    let label: String
    let role: String
    let actionPayload: String

    init(action: CodexApprovalAction) {
        self.id = action.id
        self.label = action.label
        self.role = action.role.rawValue
        self.actionPayload = action.actionPayload
    }
}

private enum CodexApprovalError: LocalizedError {
    case noActiveSession
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            "当前没有可确认的 Codex 会话。"
        case .invalidPayload:
            "确认动作无法编码。"
        }
    }
}
