import Foundation
import Observation

@MainActor
@Observable
final class CodexStatusService {
    private var provider: CodexStatusProviding
    private var previewSelection: DisplaySelection?
    var onSnapshotApplied: ((CodexStatusSnapshot) -> Void)?

    private(set) var currentState: CodexState
    private(set) var currentTask: CodexTask
    private(set) var lastUpdatedAt: Date
    private(set) var history: [StatusHistoryEntry] = []

    init(provider: CodexStatusProviding) {
        self.provider = provider
        self.currentState = provider.latestSnapshot.state
        self.currentTask = provider.latestSnapshot.task
        self.lastUpdatedAt = provider.latestSnapshot.updatedAt
    }

    func start() {
        provider.stop()
        provider.start { [weak self] snapshot in
            self?.apply(snapshot: snapshot)
        }
        onSnapshotApplied?(provider.latestSnapshot)
    }

    func advance() {
        let snapshot = provider.advance()
        apply(snapshot: snapshot)
    }

    func setPreviewState(_ state: CodexState) {
        previewSelection = makePreviewSelection(for: state, referenceDate: .now)
    }

    func clearPreviewState() {
        previewSelection = nil
    }

    var isPreviewOverrideActive: Bool {
        previewSelection != nil
    }

    var canPreviewStates: Bool {
        true
    }

    var showsDebugUI: Bool {
        ProcessInfo.processInfo.environment["CODEX_LOBSTER_ENABLE_DEBUG_UI"] == "1"
    }

    var canManuallyTransition: Bool {
        showsDebugUI && provider is CodexStatusControllable
    }

    var providerKind: CodexProviderKind {
        inspectableProvider?.providerKind ?? .mock
    }

    var providerStatusSummary: String {
        inspectableProvider?.providerStatusSummary ?? providerKind.displayName
    }

    var providerStatusDetail: String {
        inspectableProvider?.providerStatusDetail ?? providerKind.subtitle
    }

    var lastProviderError: String? {
        inspectableProvider?.lastProviderError
    }

    var providerRuntimeDiagnostics: String? {
        inspectableProvider?.providerRuntimeDiagnostics
    }

    var providerConnectionLabel: String? {
        inspectableProvider?.providerConnectionLabel
    }

    var providerConnectionDetail: String? {
        inspectableProvider?.providerConnectionDetail
    }

    var isProviderConnected: Bool {
        inspectableProvider?.isProviderConnected ?? false
    }

    var supportsAppTaskLaunching: Bool {
        providerKind == .desktopThread || providerKind == .codexCLI
    }

    var blocksNewAppLaunch: Bool {
        providerKind == .codexCLI
            && isProviderConnected
            && [.typing, .running, .awaitingApproval].contains(effectiveDisplayState)
    }

    var shouldShowBridgeQuickStart: Bool {
        switch providerKind {
        case .desktopThread:
            return false
        case .codexCLI:
            return !isProviderConnected
        default:
            return false
        }
    }

    var bridgeQuickStartCommand: String {
        let projectRoot = Self.projectRoot.replacingOccurrences(of: "\"", with: "\\\"")
        return "cd \"\(projectRoot)\" && ./scripts/codex-island.sh exec \"summarize the current repo\""
    }

    var bridgeQuickStartDescription: String {
        switch providerKind {
        case .desktopThread:
            return "桌面对话模式优先同步当前 Codex Desktop 线程；菜单栏输入只作为兼容入口。"
        case .codexCLI:
            return "正式版会从 app 内自动拉起 bridge；这里保留的是兼容外部工作流时的诊断说明。"
        default:
            return "当前来源不以桌面对话实时同步为主。"
        }
    }

    var currentProviderSession: CodexProviderSessionSummary? {
        inspectableProvider?.currentProviderSession
    }

    var recentProviderSessions: [CodexProviderSessionSummary] {
        inspectableProvider?.recentProviderSessions ?? []
    }

    var currentThreadTurns: [CodexProviderTurnSummary] {
        currentProviderSession?.turns ?? []
    }

    var recentThreadSessions: [CodexProviderSessionSummary] {
        guard let currentProviderSession else { return recentProviderSessions }
        return recentProviderSessions.filter { $0.id != currentProviderSession.id }
    }

    var effectiveDisplayState: CodexState {
        effectiveDisplaySelection.state
    }

    var effectiveDisplayTask: CodexTask {
        effectiveDisplaySelection.task
    }

    var effectiveDisplayUpdatedAt: Date {
        effectiveDisplaySelection.updatedAt
    }

    var effectiveRiskLevel: CodexRiskLevel {
        CodexRiskLevel.inferred(from: effectiveDisplaySelection.state)
    }

    var providerDiagnosticsText: String {
        let header = [
            providerStatusSummary,
            providerConnectionLabel,
            providerStatusDetail,
            providerConnectionDetail
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        let current = currentProviderSession.map { session in
            let turns = session.turns.map { turn in
                "[\(turn.timestamp.ISO8601Format())] \(turn.state.rawValue) phase=\(turn.phase ?? "nil") \(turn.primarySummary)"
            }.joined(separator: "\n")
            let turnSection = turns.isEmpty ? nil : "最近回合\n\(turns)"
            return ["当前线程", session.diagnosticLine, turnSection].compactMap { $0 }.joined(separator: "\n")
        }

        guard !recentProviderSessions.isEmpty else {
            if let current {
                return "\(header)\n\n\(current)"
            }
            return header
        }

        let sessions = recentProviderSessions.map(\.diagnosticLine).joined(separator: "\n")
        let sections = [header, current, "最近线程\n\(sessions)"].compactMap { $0 }
        return sections.joined(separator: "\n\n")
    }

    var currentApprovalReason: String? {
        effectiveDisplayTask.approvalReason ?? currentProviderSession?.approvalReason ?? currentTask.approvalReason
    }

    var currentApprovalActions: [CodexApprovalAction] {
        let sessionActions = currentProviderSession?.approvalActions ?? []
        if !sessionActions.isEmpty {
            return sessionActions
        }
        return currentTask.approvalActions
    }

    var hasNativeApprovalActions: Bool {
        !currentApprovalActions.isEmpty
    }

    var shouldPromoteNativeActionPanel: Bool {
        effectiveDisplayState == .awaitingApproval && hasNativeApprovalActions
    }

    var currentActionPanelTitle: String {
        shouldPromoteNativeActionPanel ? "原生确认动作" : "确认请求"
    }

    var currentActionPanelSubtitle: String {
        if hasNativeApprovalActions {
            return "沿用 Codex 原生按钮语义"
        }
        if providerKind == .desktopThread {
            return "当前桌面对话没有可用的原生动作"
        }
        return "当前没有 bridge 提供的原生动作"
    }

    var currentActionEntryHint: String? {
        guard shouldPromoteNativeActionPanel else { return nil }
        return "点开顶部浮窗，使用 Codex 原生确认按钮。"
    }

    var syncStatusHintText: String? {
        if let providerConnectionDetail {
            return providerConnectionDetail
        }
        if shouldShowBridgeQuickStart {
            return bridgeQuickStartDescription
        }
        return nil
    }

    var canPerformApprovalActions: Bool {
        provider is CodexApprovalControlling && !currentApprovalActions.isEmpty
    }

    var canManageDesktopPermissions: Bool {
        provider is CodexPermissionControlling
    }

    func replaceProvider(_ provider: CodexStatusProviding) {
        self.provider.stop()
        self.provider = provider
        history.removeAll(keepingCapacity: true)
        currentState = provider.latestSnapshot.state
        currentTask = provider.latestSnapshot.task
        lastUpdatedAt = provider.latestSnapshot.updatedAt
        start()
    }

    func apply(snapshot: CodexStatusSnapshot) {
        currentState = snapshot.state
        currentTask = snapshot.task
        lastUpdatedAt = snapshot.updatedAt
        history.insert(
            StatusHistoryEntry(
                state: snapshot.state,
                taskTitle: snapshot.task.title,
                timestamp: snapshot.updatedAt
            ),
            at: 0
        )
        if history.count > 12 {
            history.removeLast(history.count - 12)
        }
        onSnapshotApplied?(snapshot)
    }

    func clearHistory() {
        history.removeAll(keepingCapacity: false)
    }

    func performApprovalAction(_ action: CodexApprovalAction) async throws {
        guard let controller = provider as? CodexApprovalControlling else {
            throw ApprovalUnavailableError.unsupportedProvider
        }
        try await controller.performApprovalAction(action)
    }

    func requestDesktopPermissionPrompt() {
        guard let controller = provider as? CodexPermissionControlling else { return }
        controller.requestPermissionPrompt()
    }

    func recheckDesktopPermissions() {
        guard let controller = provider as? CodexPermissionControlling else {
            advance()
            return
        }
        controller.recheckPermissionState()
    }

    private var inspectableProvider: CodexProviderInspectable? {
        provider as? CodexProviderInspectable
    }

    private var effectiveDisplaySelection: DisplaySelection {
        if let previewSelection {
            return previewSelection
        }

        let currentSelection = normalizedDisplaySelection(
            DisplaySelection(
                state: currentState,
                task: currentTask,
                updatedAt: lastUpdatedAt,
                session: nil
            )
        )

        let sessionSelections = prioritizedSessions().map { session in
            normalizedDisplaySelection(
                DisplaySelection(
                    state: session.state,
                    task: CodexTask(
                        title: session.title,
                        detail: session.detail,
                        summary: session.responsePreview,
                        approvalReason: session.approvalReason,
                        approvalActions: session.approvalActions,
                        state: session.state,
                        startedAt: session.timestamp,
                        updatedAt: session.timestamp
                    ),
                    updatedAt: session.timestamp,
                    session: session
                )
            )
        }

        return ([currentSelection] + sessionSelections)
            .sorted(by: Self.displaySelectionSort)
            .first ?? currentSelection
    }

    private func normalizedDisplaySelection(_ selection: DisplaySelection) -> DisplaySelection {
        guard shouldDemoteHighlightedState(selection) else { return selection }
        return DisplaySelection(
            state: .idle,
            task: neutralDisplayTask(referenceDate: selection.updatedAt),
            updatedAt: selection.updatedAt,
            session: selection.session
        )
    }

    private func shouldDemoteHighlightedState(_ selection: DisplaySelection) -> Bool {
        guard Self.highlightDisplayStates.contains(selection.state) else { return false }
        return Date().timeIntervalSince(selection.updatedAt) > Self.highlightDisplayRetentionInterval
    }

    private func neutralDisplayTask(referenceDate: Date) -> CodexTask {
        CodexTask(
            title: neutralDisplayTitle,
            detail: providerConnectionDetail ?? providerStatusDetail,
            state: .idle,
            startedAt: referenceDate,
            updatedAt: referenceDate
        )
    }

    private var neutralDisplayTitle: String {
        if providerKind == .desktopThread && isProviderConnected {
            return "已连接当前桌面对话"
        }
        return providerConnectionLabel ?? providerStatusSummary
    }

    private func prioritizedSessions() -> [CodexProviderSessionSummary] {
        [currentProviderSession].compactMap { $0 }
    }

    private static func displaySelectionSort(_ lhs: DisplaySelection, _ rhs: DisplaySelection) -> Bool {
        let lhsPriority = statePriority(lhs.state)
        let rhsPriority = statePriority(rhs.state)
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        return lhs.updatedAt > rhs.updatedAt
    }

    private static func statePriority(_ state: CodexState) -> Int {
        switch state {
        case .awaitingApproval:
            0
        case .awaitingReply:
            1
        case .error:
            2
        case .running:
            3
        case .typing:
            4
        case .success:
            5
        case .idle:
            6
        }
    }

    private static let highlightDisplayRetentionInterval: TimeInterval = 2
    private static let highlightDisplayStates: Set<CodexState> = [.awaitingApproval, .success, .error]

    private func makePreviewSelection(for state: CodexState, referenceDate: Date) -> DisplaySelection {
        let task = CodexTask(
            title: state.dynamicIslandTitle,
            detail: state.subtitle,
            summary: "龙虾状态轮播预览",
            approvalReason: state == .awaitingApproval ? "这是状态预览，不会真的请求确认。" : nil,
            approvalActions: [],
            state: state,
            startedAt: referenceDate,
            updatedAt: referenceDate
        )
        return DisplaySelection(
            state: state,
            task: task,
            updatedAt: referenceDate,
            session: nil
        )
    }

}

private extension CodexStatusService {
    static let projectRoot: String = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .path
}

private struct DisplaySelection {
    let state: CodexState
    let task: CodexTask
    let updatedAt: Date
    let session: CodexProviderSessionSummary?
}

private enum ApprovalUnavailableError: LocalizedError {
    case unsupportedProvider

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            "当前来源不支持实时确认动作。"
        }
    }
}
