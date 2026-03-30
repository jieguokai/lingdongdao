import Foundation

@main
struct VerifySocketProvider {
    static func main() async throws {
        let port: UInt16 = 45541
        let provider = SocketEventCodexProvider(port: port)
        var receivedSnapshot: CodexStatusSnapshot?

        provider.start { snapshot in
            receivedSnapshot = snapshot
        }

        let line = #"{"state":"success","title":"Socket event loaded","detail":"Verification event","timestamp":"2026-03-30T08:20:30Z"}"#
        try sendLine(line, port: port)

        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if receivedSnapshot?.state == .success {
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }

        provider.stop()

        guard receivedSnapshot?.state == .success else {
            throw VerificationError("Expected socket provider to emit success state")
        }
        guard receivedSnapshot?.task.title == "Socket event loaded" else {
            throw VerificationError("Expected socket provider to round-trip title")
        }

        print("socket verification passed")
    }

    private static func sendLine(_ line: String, port: UInt16) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "printf '%s\\n' \"$PAYLOAD\" | nc 127.0.0.1 \(port)"]
        process.environment = ["PAYLOAD": line]
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw VerificationError("Failed to send verification payload: \(output)")
        }
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
