import AppKit
import Foundation

@MainActor
final class CodexDesktopThreadProvider: CodexStatusProviding, CodexProviderInspectable, CodexApprovalControlling, CodexPermissionControlling {
    private enum DefaultsKeys {
        static let desktopPermissionAutoPromptConsumed = "desktopThread.permissionAutoPromptConsumed"
    }

    private let permissionManager: CodexDesktopPermissionManager
    private let inputMonitor: CodexDesktopInputMonitor
    private let actionBridge: CodexDesktopActionBridge
    private let ocrService: CodexDesktopOCRService
    private let defaults: UserDefaults
    private var pollTimer: Timer?
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private var lastPromptText = ""
    private var lastOCRDigest = ""
    private var lastOCRUpdatedAt: Date?
    private var highlightedStateHoldUntil: Date?
    private var consecutiveFrontmostSnapshotFailures = 0
    private var lastFrontmostBundleIdentifier: String?
    private var lastWindowSnapshot: CodexDesktopWindowSnapshot?
    private var permissionState = CodexDesktopPermissionState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        inputMonitoringGranted: false,
        phase: .unauthorized
    )
    private var threadSessionsByID: [String: CodexProviderSessionSummary] = [:]
    private var recentThreadIDs: [String] = []
    private var liveCurrentProviderSession: CodexProviderSessionSummary?
    private var liveRecentProviderSessions: [CodexProviderSessionSummary] = []
    private(set) var latestSnapshot: CodexStatusSnapshot

    init(
        permissionManager: CodexDesktopPermissionManager = CodexDesktopPermissionManager(),
        inputMonitor: CodexDesktopInputMonitor = CodexDesktopInputMonitor(),
        actionBridge: CodexDesktopActionBridge = CodexDesktopActionBridge(),
        ocrService: CodexDesktopOCRService = CodexDesktopOCRService(),
        defaults: UserDefaults = .standard
    ) {
        self.permissionManager = permissionManager
        self.inputMonitor = inputMonitor
        self.actionBridge = actionBridge
        self.ocrService = ocrService
        self.defaults = defaults
        let now = Date()
        self.latestSnapshot = CodexStatusSnapshot(
            state: .idle,
            task: CodexTask(
                title: "等待 Codex 对话",
                detail: "激活 Codex Desktop 窗口后，小龙虾会跟随当前线程同步输入、执行、确认和反馈。",
                state: .idle,
                startedAt: now,
                updatedAt: now
            ),
            updatedAt: now
        )
    }

    var providerKind: CodexProviderKind { .desktopThread }
    var providerStatusSummary: String { "Codex Desktop 对话" }
    var providerStatusDetail: String { "当前前台 Codex 窗口 + 本地桌面对话适配" }
    var lastProviderError: String? { nil }
    var providerRuntimeDiagnostics: String? {
        let snapshot = lastWindowSnapshot
        return [
            "phase: \(String(describing: permissionState.phase))",
            "frontmostBundleID: \(lastFrontmostBundleIdentifier ?? "nil")",
            "snapshotAvailable: \(snapshot != nil)",
            "windowAvailable: \(snapshot?.windowAvailable == true)",
            "promptFocused: \(snapshot?.promptFocused == true)",
            "focusedElementRole: \(snapshot?.focusedElementRole ?? "nil")",
            "focusedValuePresent: \(((snapshot?.focusedElementValue?.isEmpty == false) ? "true" : "false"))",
            "threadTitle: \(snapshot?.threadTitle ?? "nil")",
            "threadFingerprint: \(snapshot?.threadFingerprint ?? "nil")",
            "frameAvailable: \(snapshot?.frame != nil)",
            "consecutiveSnapshotFailures: \(consecutiveFrontmostSnapshotFailures)",
            "accessibilityGranted: \(permissionState.accessibilityGranted)",
            "screenRecordingGranted: \(permissionState.screenRecordingGranted)",
            "inputMonitoringGranted: \(permissionState.inputMonitoringGranted)"
        ].joined(separator: "\n")
    }
    var providerConnectionLabel: String? {
        permissionState.statusLabel
    }
    var providerConnectionDetail: String? {
        if permissionState.phase == .live, let session = liveCurrentProviderSession {
            return [session.metadataSummary, session.primarySummary].joined(separator: "\n")
        }
        if permissionState.phase == .attachedIdle, let session = liveCurrentProviderSession {
            return session.metadataSummary.isEmpty ? permissionState.statusDetail : "\(session.metadataSummary)\n\(permissionState.statusDetail)"
        }
        return permissionState.statusDetail
    }
    var isProviderConnected: Bool {
        permissionState.isConnected && liveCurrentProviderSession != nil
    }
    var currentProviderSession: CodexProviderSessionSummary? { liveCurrentProviderSession }
    var recentProviderSessions: [CodexProviderSessionSummary] { liveRecentProviderSessions }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        permissionState = permissionManager.refresh(mode: .silentCheck)
        if permissionState.hasMissingPermissions, shouldAutomaticallyPromptForMissingPermissions {
            markAutomaticPermissionPromptConsumed()
            permissionState = permissionManager.refresh(mode: .autoPromptAllNeeded)
        }
        inputMonitor.start()
        onUpdate(latestSnapshot)
        refresh()
        startTimer()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        inputMonitor.stop()
    }

    func advance() -> CodexStatusSnapshot {
        refresh()
        onUpdate?(latestSnapshot)
        return latestSnapshot
    }

    func performApprovalAction(_ action: CodexApprovalAction) async throws {
        guard actionBridge.perform(action: action) else {
            throw DesktopApprovalError.actionUnavailable
        }
    }

    func requestPermissionPrompt() {
        permissionState = permissionManager.refresh(mode: .manualPromptFull)
        refresh()
    }

    func recheckPermissionState() {
        permissionState = permissionManager.refresh(mode: .silentCheck)
        refresh()
    }

    private var shouldAutomaticallyPromptForMissingPermissions: Bool {
        !defaults.bool(forKey: DefaultsKeys.desktopPermissionAutoPromptConsumed)
    }

    private func markAutomaticPermissionPromptConsumed() {
        defaults.set(true, forKey: DefaultsKeys.desktopPermissionAutoPromptConsumed)
    }

    private func startTimer() {
        pollTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func refresh() {
        permissionState = permissionManager.refresh(mode: .silentCheck)
        lastFrontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard permissionState.isReady else {
            consecutiveFrontmostSnapshotFailures = 0
            lastWindowSnapshot = nil
            permissionState = permissionState.updating(phase: .unauthorized)
            publishMissingPermissionsSnapshot()
            return
        }

        let isCodexRunning = actionBridge.isCodexRunning

        guard let windowSnapshot = actionBridge.snapshot() else {
            lastWindowSnapshot = nil
            preserveTerminalStateIfNeeded()
            if isCodexRunning {
                consecutiveFrontmostSnapshotFailures += 1
                let phase: CodexDesktopPermissionState.SyncPhase = consecutiveFrontmostSnapshotFailures >= 3 ? .pendingRestart : .readyInactive
                permissionState = permissionState.updating(phase: phase)
                if liveCurrentProviderSession == nil {
                    publishIdleSnapshot(
                        title: permissionState.statusLabel,
                        detail: permissionState.statusDetail
                    )
                }
            } else {
                consecutiveFrontmostSnapshotFailures = 0
                permissionState = permissionState.updating(phase: .readyInactive)
                if liveCurrentProviderSession == nil {
                    publishIdleSnapshot(title: "等待 Codex 运行", detail: permissionState.statusDetail)
                }
            }
            return
        }

        consecutiveFrontmostSnapshotFailures = 0
        lastWindowSnapshot = windowSnapshot
        let isAttached = windowSnapshot.windowAvailable
            && (windowSnapshot.focusedElementRole != nil || windowSnapshot.frame != nil)
        guard isAttached else {
            permissionState = permissionState.updating(phase: isCodexRunning ? .pendingRestart : .readyInactive)
            publishIdleSnapshot(title: permissionState.statusLabel, detail: permissionState.statusDetail)
            return
        }

        let now = Date()
        let prompt = windowSnapshot.promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let ocrSnapshot = permissionState.screenRecordingGranted
            ? windowSnapshot.frame.flatMap { ocrService.captureWindowSnapshot(frame: $0) }
            : nil
        let ocrDigest = ocrSnapshot?.lines.joined(separator: "\n") ?? ""
        if !ocrDigest.isEmpty, ocrDigest != lastOCRDigest {
            lastOCRDigest = ocrDigest
            lastOCRUpdatedAt = now
        }
        let hasApprovalPrompt = ocrSnapshot?.hasApprovalPrompt == true
        let replyReason = hasApprovalPrompt ? nil : ocrSnapshot?.replyReason

        let threadIdentity = resolveThreadIdentity(
            windowSnapshot: windowSnapshot,
            ocrSnapshot: ocrSnapshot,
            prompt: prompt
        )
        let threadTitle = threadIdentity.title
        let approvalActions = hasApprovalPrompt ? windowSnapshot.actionCandidates.map {
            CodexApprovalAction(label: $0.label, role: $0.role, actionPayload: $0.label)
        } : []

        permissionState = permissionState.updating(phase: .attachedIdle)

        let inferredState = inferState(
            now: now,
            prompt: prompt,
            promptFocused: windowSnapshot.promptFocused,
            hasApprovalPrompt: hasApprovalPrompt,
            approvalActions: approvalActions,
            ocrSnapshot: ocrSnapshot
        )

        if inferredState == .idle, shouldRetainHighlightedState(at: now) {
            permissionState = permissionState.updating(phase: .live)
            return
        }

        switch inferredState {
        case .idle:
            permissionState = permissionState.updating(phase: .attachedIdle)
            let idleSummary = prompt.isEmpty ? (ocrSnapshot?.summary ?? windowSnapshot.focusedElementValue) : prompt
            if shouldPreserveSessionDetailsAfterHighlight {
                publishIdleSnapshotPreservingSession(
                    title: "已连接当前桌面对话",
                    detail: threadTitle,
                    summary: idleSummary,
                    timestamp: now
                )
            } else {
                publishAttachedIdleSession(
                    id: threadIdentity.id,
                    identitySeed: threadIdentity.seed,
                    title: "已连接当前桌面对话",
                    detail: threadTitle,
                    summary: idleSummary,
                    timestamp: now,
                    source: "codex-desktop-thread"
                )
            }
        case .typing:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .typing,
                title: "Codex 正在听指令",
                detail: prompt.isEmpty ? "正在输入新指令。" : prompt,
                summary: prompt,
                approvalReason: nil,
                approvalActions: [],
                timestamp: now,
                source: "codex-desktop-thread"
            )
        case .running:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .running,
                title: "Codex 正在执行",
                detail: threadTitle,
                summary: ocrSnapshot?.summary,
                approvalReason: nil,
                approvalActions: [],
                timestamp: now,
                source: "codex-desktop-thread"
            )
        case .awaitingReply:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .awaitingReply,
                title: "Codex 等待回复",
                detail: threadTitle,
                summary: replyReason ?? ocrSnapshot?.summary,
                approvalReason: nil,
                approvalActions: [],
                timestamp: now,
                source: "codex-desktop-thread"
            )
        case .awaitingApproval:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .awaitingApproval,
                title: "Codex 等待确认",
                detail: threadTitle,
                summary: ocrSnapshot?.summary,
                approvalReason: ocrSnapshot?.approvalReason ?? ocrSnapshot?.summary,
                approvalActions: approvalActions,
                timestamp: now,
                source: "codex-desktop-thread"
            )
        case .success:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .success,
                title: "Codex 已完成",
                detail: threadTitle,
                summary: ocrSnapshot?.summary,
                approvalReason: nil,
                approvalActions: [],
                timestamp: now,
                source: "codex-desktop-thread"
            )
        case .error:
            permissionState = permissionState.updating(phase: .live)
            publishSession(
                id: threadIdentity.id,
                identitySeed: threadIdentity.seed,
                state: .error,
                title: "Codex 出错了",
                detail: threadTitle,
                summary: ocrSnapshot?.summary,
                approvalReason: nil,
                approvalActions: [],
                timestamp: now,
                source: "codex-desktop-thread"
            )
        }

        lastPromptText = prompt
    }

    private func inferState(
        now: Date,
        prompt: String,
        promptFocused: Bool,
        hasApprovalPrompt: Bool,
        approvalActions: [CodexApprovalAction],
        ocrSnapshot: CodexDesktopOCRSnapshot?
    ) -> CodexState {
        CodexDesktopStateInference.inferState(
            CodexDesktopStateInferenceContext(
                latestState: latestSnapshot.state,
                prompt: prompt,
                promptFocused: promptFocused,
                promptChanged: prompt != lastPromptText,
                hasRecentTypingActivity: inputMonitor.hasRecentTypingActivity(within: 1.2),
                hasApprovalPrompt: hasApprovalPrompt,
                hasApprovalActions: !approvalActions.isEmpty,
                analysis: ocrSnapshot.map { CodexDesktopConversationAnalysis(lines: $0.lines) },
                hasRecentOCRActivity: lastOCRUpdatedAt.map { now.timeIntervalSince($0) <= 1.8 } ?? false
            )
        )
    }

    private func publishAttachedIdleSession(
        id: String,
        identitySeed: String,
        title: String,
        detail: String,
        summary: String?,
        timestamp: Date,
        source: String
    ) {
        highlightedStateHoldUntil = nil
        let task = CodexTask(
            title: title,
            detail: detail,
            summary: summary,
            state: .idle,
            startedAt: latestSnapshot.state == .idle ? latestSnapshot.task.startedAt : timestamp,
            updatedAt: timestamp
        )
        latestSnapshot = CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
        let existingSession = threadSessionsByID[id]
        let shouldInsertIdleTurn = liveCurrentProviderSession?.id != id || existingSession?.state != .idle
        _ = upsertThreadSession(
            id: id,
            identitySeed: identitySeed,
            source: source,
            state: .idle,
            title: title,
            detail: detail,
            summary: summary,
            phase: "attached_idle",
            timestamp: timestamp,
            insertTurn: shouldInsertIdleTurn
        )
        onUpdate?(latestSnapshot)
    }

    private func publishIdleSnapshotPreservingSession(
        title: String,
        detail: String,
        summary: String?,
        timestamp: Date
    ) {
        highlightedStateHoldUntil = nil
        let task = CodexTask(
            title: title,
            detail: detail,
            summary: summary,
            state: .idle,
            startedAt: latestSnapshot.state == .idle ? latestSnapshot.task.startedAt : timestamp,
            updatedAt: timestamp
        )
        latestSnapshot = CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
        onUpdate?(latestSnapshot)
    }

    private func publishSession(
        id: String,
        identitySeed: String,
        state: CodexState,
        title: String,
        detail: String,
        summary: String?,
        approvalReason: String?,
        approvalActions: [CodexApprovalAction],
        timestamp: Date,
        source: String
    ) {
        if Self.highlightRetainedStates.contains(state) {
            highlightedStateHoldUntil = timestamp.addingTimeInterval(Self.highlightRetentionInterval)
        } else {
            highlightedStateHoldUntil = nil
        }

        let task = CodexTask(
            title: title,
            detail: detail,
            summary: summary,
            approvalReason: approvalReason,
            approvalActions: approvalActions,
            state: state,
            startedAt: state == latestSnapshot.state ? latestSnapshot.task.startedAt : timestamp,
            updatedAt: timestamp
        )
        latestSnapshot = CodexStatusSnapshot(state: state, task: task, updatedAt: timestamp)

        _ = upsertThreadSession(
            id: id,
            identitySeed: identitySeed,
            source: source,
            state: state,
            title: title,
            detail: detail,
            summary: summary,
            phase: state.phaseToken,
            errorSummary: state == .error ? summary : nil,
            approvalReason: approvalReason,
            approvalActions: approvalActions,
            timestamp: timestamp,
            insertTurn: true
        )
        onUpdate?(latestSnapshot)
    }

    private var shouldPreserveSessionDetailsAfterHighlight: Bool {
        guard let state = liveCurrentProviderSession?.state else { return false }
        return state == .awaitingReply || state == .awaitingApproval || state == .error
    }

    private func shouldRetainHighlightedState(at now: Date) -> Bool {
        guard let highlightedStateHoldUntil else { return false }
        return now < highlightedStateHoldUntil
    }

    private func publishIdleSnapshot(title: String, detail: String) {
        let now = Date()
        latestSnapshot = CodexStatusSnapshot(
            state: .idle,
            task: CodexTask(
                title: title,
                detail: detail,
                state: .idle,
                startedAt: now,
                updatedAt: now
            ),
            updatedAt: now
        )
        liveCurrentProviderSession = nil
        syncRecentProviderSessions()
        onUpdate?(latestSnapshot)
    }

    private func publishMissingPermissionsSnapshot() {
        let now = Date()
        latestSnapshot = CodexStatusSnapshot(
            state: .idle,
            task: CodexTask(
                title: permissionState.statusLabel,
                detail: permissionState.statusDetail,
                state: .idle,
                startedAt: now,
                updatedAt: now
            ),
            updatedAt: now
        )
        liveCurrentProviderSession = nil
        syncRecentProviderSessions()
        onUpdate?(latestSnapshot)
    }

    private func preserveTerminalStateIfNeeded() {
        if permissionState.phase == .attachedIdle || permissionState.phase == .live {
            return
        }
        if latestSnapshot.state == .success,
           Date().timeIntervalSince(latestSnapshot.updatedAt) <= Self.highlightRetentionInterval {
            return
        }
        if latestSnapshot.state == .awaitingReply || latestSnapshot.state == .awaitingApproval || latestSnapshot.state == .error {
            return
        }
        liveCurrentProviderSession = nil
        syncRecentProviderSessions()
    }

    private static let highlightRetentionInterval: TimeInterval = 2
    private static let highlightRetainedStates: Set<CodexState> = [.awaitingApproval, .success, .error]

    private func resolveThreadIdentity(
        windowSnapshot: CodexDesktopWindowSnapshot,
        ocrSnapshot: CodexDesktopOCRSnapshot?,
        prompt: String
    ) -> ResolvedThreadIdentity {
        let fallbackTitle = windowSnapshot.threadTitle
            ?? windowSnapshot.threadContextLines.first
            ?? ocrSnapshot?.summary
            ?? "当前桌面对话"
        let fallbackSeed = [windowSnapshot.threadFingerprint, fallbackTitle, ocrSnapshot?.summary, prompt.nonEmptyValue]
            .compactMap { Self.normalizedIdentityComponent(from: $0) }
            .joined(separator: " | ")

        if let currentSession = liveCurrentProviderSession,
           windowSnapshot.threadFingerprint == nil,
           currentSession.detail == fallbackTitle,
           Date().timeIntervalSince(currentSession.timestamp) <= 8 {
            return ResolvedThreadIdentity(id: currentSession.id, seed: currentSession.identitySeed ?? fallbackSeed, title: fallbackTitle)
        }

        let seed = Self.normalizedIdentityComponent(from: windowSnapshot.threadFingerprint)
            ?? Self.normalizedIdentityComponent(from: fallbackSeed)
            ?? Self.normalizedIdentityComponent(from: fallbackTitle)
            ?? "desktop-thread"

        if let existingSession = threadSessionsByID.values.first(where: { $0.identitySeed == seed }) {
            return ResolvedThreadIdentity(id: existingSession.id, seed: seed, title: fallbackTitle)
        }

        return ResolvedThreadIdentity(
            id: Self.threadID(forSeed: seed, fallbackTitle: fallbackTitle),
            seed: seed,
            title: fallbackTitle
        )
    }

    private func upsertThreadSession(
        id: String,
        identitySeed: String,
        source: String,
        state: CodexState,
        title: String,
        detail: String,
        summary: String?,
        phase: String,
        errorSummary: String? = nil,
        approvalReason: String? = nil,
        approvalActions: [CodexApprovalAction] = [],
        timestamp: Date,
        insertTurn: Bool
    ) -> CodexProviderSessionSummary {
        let turn = CodexProviderTurnSummary(
            id: Self.turnID(
                state: state,
                phase: phase,
                title: title,
                detail: detail,
                summary: summary,
                approvalReason: approvalReason,
                errorSummary: errorSummary
            ),
            state: state,
            title: title,
            detail: detail,
            summary: summary,
            approvalReason: approvalReason,
            approvalActions: approvalActions,
            phase: phase,
            errorSummary: errorSummary,
            timestamp: timestamp
        )

        var turns = threadSessionsByID[id]?.turns ?? []
        if insertTurn {
            if let firstTurn = turns.first, firstTurn.id == turn.id {
                turns[0] = turn
            } else {
                turns.insert(turn, at: 0)
            }
            if turns.count > Self.maxTurnsPerThread {
                turns.removeLast(turns.count - Self.maxTurnsPerThread)
            }
        }

        let session = CodexProviderSessionSummary(
            id: id,
            identitySeed: identitySeed,
            source: source,
            threadTitle: detail,
            state: state,
            title: title,
            detail: detail,
            commandName: "desktop-thread",
            exitCode: nil,
            responsePreview: summary,
            usageSummary: nil,
            phase: phase,
            errorSummary: errorSummary,
            approvalReason: approvalReason,
            approvalActions: approvalActions,
            timestamp: timestamp,
            turns: turns
        )
        threadSessionsByID[id] = session
        liveCurrentProviderSession = session
        markThreadAsRecent(id)
        syncRecentProviderSessions()
        return session
    }

    private func markThreadAsRecent(_ id: String) {
        recentThreadIDs.removeAll { $0 == id }
        recentThreadIDs.insert(id, at: 0)
        if recentThreadIDs.count > Self.maxRecentThreads {
            let removedIDs = recentThreadIDs.suffix(from: Self.maxRecentThreads)
            for removedID in removedIDs {
                threadSessionsByID.removeValue(forKey: removedID)
            }
            recentThreadIDs.removeLast(recentThreadIDs.count - Self.maxRecentThreads)
        }
    }

    private func syncRecentProviderSessions() {
        liveRecentProviderSessions = recentThreadIDs.compactMap { threadSessionsByID[$0] }
    }

    private static func threadID(forSeed seed: String, fallbackTitle: String) -> String {
        let slug = (normalizedIdentityComponent(from: seed) ?? normalizedIdentityComponent(from: fallbackTitle) ?? "desktop-thread")
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
            .joined()
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let truncated = String(slug.prefix(72))
        return truncated.isEmpty ? "desktop-thread" : "desktop-\(truncated)"
    }

    private static func normalizedIdentityComponent(from raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        return value.isEmpty ? nil : value
    }

    private static func turnID(
        state: CodexState,
        phase: String,
        title: String,
        detail: String,
        summary: String?,
        approvalReason: String?,
        errorSummary: String?
    ) -> String {
        [
            state.rawValue,
            phase,
            title,
            detail,
            summary ?? "",
            approvalReason ?? "",
            errorSummary ?? ""
        ].joined(separator: "|")
    }

    private static let maxRecentThreads = 4
    private static let maxTurnsPerThread = 3
}

private extension CodexState {
    var phaseToken: String {
        switch self {
        case .idle:
            return "idle"
        case .typing:
            return "typing"
        case .running:
            return "running"
        case .awaitingReply:
            return "awaiting_reply"
        case .awaitingApproval:
            return "awaiting_approval"
        case .success:
            return "completed"
        case .error:
            return "failed"
        }
    }
}

private struct ResolvedThreadIdentity {
    let id: String
    let seed: String
    let title: String
}

private extension String {
    var nonEmptyValue: String? {
        isEmpty ? nil : self
    }
}

private enum DesktopApprovalError: LocalizedError {
    case actionUnavailable

    var errorDescription: String? {
        "当前桌面对话没有可点击的原生确认按钮。"
    }
}
