import Foundation

@MainActor
final class MockStatusGenerator: CodexStatusProviding, CodexStatusControllable {
    private let snapshots: [CodexStatusSnapshot]
    private var index = 0
    private var isRunning = false
    private var timer: Timer?
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?

    init(snapshots: [CodexStatusSnapshot] = MockStatusGenerator.defaultSnapshots()) {
        self.snapshots = snapshots
    }

    var latestSnapshot: CodexStatusSnapshot {
        snapshots[index]
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        isRunning = true
        scheduleTimer()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func advance() -> CodexStatusSnapshot {
        guard isRunning else { return snapshots[index] }
        index = (index + 1) % snapshots.count
        return snapshots[index]
    }

    func transition(to state: CodexState) -> CodexStatusSnapshot {
        if let matchedIndex = snapshots.firstIndex(where: { $0.state == state }) {
            index = matchedIndex
        }
        return snapshots[index]
    }

    static func defaultSnapshots(referenceDate: Date = .now) -> [CodexStatusSnapshot] {
        let idleTask = CodexTask(
            title: "等待任务",
            detail: "Codex 正在待命。",
            state: .idle,
            startedAt: referenceDate,
            updatedAt: referenceDate
        )
        let typingTask = CodexTask(
            title: "输入中",
            detail: "Codex 正在听取下一条指令。",
            summary: "准备执行新任务。",
            state: .typing,
            startedAt: referenceDate.addingTimeInterval(5),
            updatedAt: referenceDate.addingTimeInterval(5)
        )
        let runningTask = CodexTask(
            title: "正在实现浮动岛",
            detail: "正在组合视图与服务层。",
            state: .running,
            startedAt: referenceDate.addingTimeInterval(10),
            updatedAt: referenceDate.addingTimeInterval(10)
        )
        let awaitingReplyTask = CodexTask(
            title: "等待你继续回复",
            detail: "Codex 还需要你补充约束和输入。",
            summary: "请补充你想保留哪些交互行为。",
            state: .awaitingReply,
            startedAt: referenceDate.addingTimeInterval(12),
            updatedAt: referenceDate.addingTimeInterval(12)
        )
        let approvalTask = CodexTask(
            title: "等待确认",
            detail: "Codex 请求继续执行前确认。",
            summary: "需要确认是否继续修改工作区文件。",
            approvalReason: "将修改工作区文件并继续执行后续步骤。",
            approvalActions: [
                CodexApprovalAction(id: "approve", label: "继续", role: .approve, actionPayload: "approve"),
                CodexApprovalAction(id: "reject", label: "取消", role: .reject, actionPayload: "reject")
            ],
            state: .awaitingApproval,
            startedAt: referenceDate.addingTimeInterval(15),
            updatedAt: referenceDate.addingTimeInterval(15)
        )
        let successTask = CodexTask(
            title: "构建完成",
            detail: "最近一次模拟任务已顺利结束。",
            state: .success,
            startedAt: referenceDate.addingTimeInterval(20),
            updatedAt: referenceDate.addingTimeInterval(20)
        )
        let errorTask = CodexTask(
            title: "构建失败",
            detail: "继续之前需要先处理问题。",
            state: .error,
            startedAt: referenceDate.addingTimeInterval(30),
            updatedAt: referenceDate.addingTimeInterval(30)
        )

        return [
            CodexStatusSnapshot(state: .idle, task: idleTask, updatedAt: idleTask.updatedAt),
            CodexStatusSnapshot(state: .typing, task: typingTask, updatedAt: typingTask.updatedAt),
            CodexStatusSnapshot(state: .running, task: runningTask, updatedAt: runningTask.updatedAt),
            CodexStatusSnapshot(state: .awaitingReply, task: awaitingReplyTask, updatedAt: awaitingReplyTask.updatedAt),
            CodexStatusSnapshot(state: .awaitingApproval, task: approvalTask, updatedAt: approvalTask.updatedAt),
            CodexStatusSnapshot(state: .success, task: successTask, updatedAt: successTask.updatedAt),
            CodexStatusSnapshot(state: .error, task: errorTask, updatedAt: errorTask.updatedAt)
        ]
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let snapshot = self.advance()
                self.onUpdate?(snapshot)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
}
