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
            title: "Waiting for work",
            detail: "Codex is standing by.",
            state: .idle,
            startedAt: referenceDate,
            updatedAt: referenceDate
        )
        let runningTask = CodexTask(
            title: "Implementing floating island",
            detail: "Composing views and services.",
            state: .running,
            startedAt: referenceDate.addingTimeInterval(10),
            updatedAt: referenceDate.addingTimeInterval(10)
        )
        let successTask = CodexTask(
            title: "Build completed",
            detail: "Latest mock task finished cleanly.",
            state: .success,
            startedAt: referenceDate.addingTimeInterval(20),
            updatedAt: referenceDate.addingTimeInterval(20)
        )
        let errorTask = CodexTask(
            title: "Build failed",
            detail: "Needs attention before continuing.",
            state: .error,
            startedAt: referenceDate.addingTimeInterval(30),
            updatedAt: referenceDate.addingTimeInterval(30)
        )

        return [
            CodexStatusSnapshot(state: .idle, task: idleTask, updatedAt: idleTask.updatedAt),
            CodexStatusSnapshot(state: .running, task: runningTask, updatedAt: runningTask.updatedAt),
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
