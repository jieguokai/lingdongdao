import Foundation

protocol ShellCommandRunning {
    func run(_ launchPath: String, arguments: [String]) throws -> ShellCommandResult
}

struct ShellCommandResult: Sendable {
    let status: Int32
    let stdout: String
    let stderr: String
}

struct ShellCommandRunner: ShellCommandRunning {
    func run(_ launchPath: String, arguments: [String]) throws -> ShellCommandResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        if process.terminationStatus > 1 {
            throw ShellCommandError.executionFailed(
                command: ([launchPath] + arguments).joined(separator: " "),
                message: stderr.isEmpty ? stdout : stderr
            )
        }

        return ShellCommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
}

enum ShellCommandError: LocalizedError {
    case executionFailed(command: String, message: String)

    var errorDescription: String? {
        switch self {
        case let .executionFailed(command, message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Command failed: \(command)" : "Command failed: \(command) — \(trimmed)"
        }
    }
}
