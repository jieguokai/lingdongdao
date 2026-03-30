import Foundation
import Network

@MainActor
final class SocketEventCodexProvider: CodexStatusProviding {
    private let port: UInt16
    private let parser: CodexLogEventParser
    private let queue: DispatchQueue
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var bufferedData: [ObjectIdentifier: Data] = [:]
    private var onUpdate: (@MainActor (CodexStatusSnapshot) -> Void)?
    private(set) var latestSnapshot: CodexStatusSnapshot

    init(
        port: UInt16 = SocketEventCodexProvider.defaultPort(),
        parser: CodexLogEventParser = CodexLogEventParser()
    ) {
        self.port = port
        self.parser = parser
        self.queue = DispatchQueue(label: "com.codex.lobsterisland.socket-provider")

        let timestamp = Date()
        let task = CodexTask(
            title: "Listening for Codex socket events",
            detail: "Waiting on tcp://127.0.0.1:\(port)",
            state: .idle,
            startedAt: timestamp,
            updatedAt: timestamp
        )
        self.latestSnapshot = CodexStatusSnapshot(state: .idle, task: task, updatedAt: timestamp)
    }

    func start(onUpdate: @escaping @MainActor (CodexStatusSnapshot) -> Void) {
        self.onUpdate = onUpdate
        onUpdate(latestSnapshot)
        startListener()
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for connection in connections.values {
            connection.cancel()
        }
        connections.removeAll()
        bufferedData.removeAll()
    }

    func advance() -> CodexStatusSnapshot {
        onUpdate?(latestSnapshot)
        return latestSnapshot
    }

    private func startListener() {
        guard listener == nil else { return }

        do {
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                publishError("Invalid socket port \(port).")
                return
            }

            let listener = try NWListener(using: .tcp, on: nwPort)
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    self?.handleListenerState(state)
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.accept(connection)
                }
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            publishError(error.localizedDescription)
        }
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            let now = Date()
            latestSnapshot = makeSnapshot(
                state: .idle,
                title: "Socket listener ready",
                detail: "Waiting on tcp://127.0.0.1:\(port)",
                timestamp: now,
                resetStart: false
            )
            onUpdate?(latestSnapshot)
        case let .failed(error):
            publishError(error.localizedDescription)
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        connections[id] = connection
        bufferedData[id] = Data()

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleConnectionState(state, id: id)
            }
        }

        connection.start(queue: queue)
        receiveNextChunk(on: connection, id: id)
    }

    private func handleConnectionState(_ state: NWConnection.State, id: ObjectIdentifier) {
        switch state {
        case .cancelled, .failed:
            connections[id] = nil
            bufferedData[id] = nil
        default:
            break
        }
    }

    private func receiveNextChunk(on connection: NWConnection, id: ObjectIdentifier) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.publishError(error.localizedDescription)
                    self.connections[id]?.cancel()
                    self.connections[id] = nil
                    self.bufferedData[id] = nil
                    return
                }

                if let data, !data.isEmpty {
                    self.consume(data: data, id: id)
                }

                if isComplete {
                    self.connections[id]?.cancel()
                    self.connections[id] = nil
                    self.bufferedData[id] = nil
                    return
                }

                if let connection = self.connections[id] {
                    self.receiveNextChunk(on: connection, id: id)
                }
            }
        }
    }

    private func consume(data: Data, id: ObjectIdentifier) {
        var buffer = bufferedData[id] ?? Data()
        buffer.append(data)

        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer[..<newlineIndex]
            buffer.removeSubrange(...newlineIndex)

            guard
                let line = String(data: lineData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !line.isEmpty
            else {
                continue
            }

            do {
                let event = try parser.parse(line: line)
                latestSnapshot = makeSnapshot(
                    state: event.state,
                    title: event.title,
                    detail: event.detail,
                    timestamp: event.timestamp,
                    resetStart: latestSnapshot.state != event.state
                )
                onUpdate?(latestSnapshot)
            } catch {
                publishError(error.localizedDescription)
            }
        }

        bufferedData[id] = buffer
    }

    private func publishError(_ detail: String) {
        latestSnapshot = makeSnapshot(
            state: .error,
            title: "Socket listener failed",
            detail: detail,
            timestamp: Date(),
            resetStart: latestSnapshot.state != .error
        )
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

    nonisolated private static func defaultPort() -> UInt16 {
        if
            let raw = ProcessInfo.processInfo.environment["CODEX_LOBSTER_SOCKET_PORT"],
            let value = UInt16(raw)
        {
            return value
        }
        return 45540
    }
}
