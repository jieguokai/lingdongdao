import Foundation
import Observation

@MainActor
@Observable
final class CodexTaskLaunchService {
    private let fileManager: FileManager
    private let environment: [String: String]
    private let projectRootURL: URL
    private let bridgeScriptURL: URL
    private var activeProcesses: [String: Process] = [:]

    private(set) var authenticationState: CodexAuthenticationState = .checking
    private(set) var isSubmitting = false
    private(set) var lastLaunchErrorMessage: String?
    private(set) var activeSessionID: String?

    init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        projectRootURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.environment = environment
        let resolvedProjectRootURL = projectRootURL ?? Self.defaultProjectRootURL()
        self.projectRootURL = resolvedProjectRootURL
        self.bridgeScriptURL = Self.resolveBridgeScriptURL(projectRootURL: resolvedProjectRootURL)
    }

    var canLaunchTask: Bool {
        authenticationState.isAuthenticated && !isSubmitting && activeProcesses.isEmpty
    }

    var hasRunningAppInitiatedSession: Bool {
        !activeProcesses.isEmpty
    }

    func refreshAuthenticationState() async {
        guard let codexBinaryPath = resolveCodexBinaryPath() else {
            authenticationState = .unavailable("当前设备未找到 Codex CLI，无法从 app 内直接发起任务。")
            return
        }

        authenticationState = .checking

        do {
            let result = try await runCommand(
                launchPath: codexBinaryPath,
                arguments: ["login", "status"]
            )
            let summary = result.combinedOutput
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })

            if result.exitCode == 0 {
                authenticationState = .authenticated(summary ?? "已登录 Codex，可直接从菜单栏发起任务。")
                return
            }

            if let summary, !summary.isEmpty {
                authenticationState = .unauthenticated
            } else {
                authenticationState = .failed("无法确认 Codex 登录状态（exit \(result.exitCode)）。")
            }
        } catch {
            authenticationState = .failed(error.localizedDescription)
        }
    }

    func ensureAuthenticated() async throws {
        if authenticationState.isAuthenticated {
            return
        }

        guard let codexBinaryPath = resolveCodexBinaryPath() else {
            let message = "当前设备未找到 Codex CLI，无法打开官方登录流程。"
            authenticationState = .unavailable(message)
            throw TaskLaunchError.codexUnavailable(message)
        }

        authenticationState = .authorizing

        do {
            let result = try await runCommand(
                launchPath: codexBinaryPath,
                arguments: ["login", "--device-auth"]
            )
            if result.exitCode != 0 {
                let message = result.combinedOutput.isEmpty
                    ? "Codex 登录未完成（exit \(result.exitCode)）。"
                    : result.combinedOutput
                authenticationState = .failed(message)
                throw TaskLaunchError.authenticationFailed(message)
            }

            await refreshAuthenticationState()
            guard authenticationState.isAuthenticated else {
                throw TaskLaunchError.authenticationFailed("Codex 登录流程已结束，但当前仍未登录。")
            }
        } catch {
            if case TaskLaunchError.authenticationFailed = error {
                throw error
            }
            let message = error.localizedDescription
            authenticationState = .failed(message)
            throw TaskLaunchError.authenticationFailed(message)
        }
    }

    func launchExec(prompt: String) async throws {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw TaskLaunchError.invalidPrompt
        }
        guard bridgeScriptURL.isFileURL, fileManager.fileExists(atPath: bridgeScriptURL.path) else {
            throw TaskLaunchError.bridgeUnavailable("未找到 codex-bridge.py，无法启动实时 bridge。")
        }
        guard authenticationState.isAuthenticated else {
            throw TaskLaunchError.notAuthenticated
        }
        guard activeProcesses.isEmpty else {
            throw TaskLaunchError.busy("当前已有一个通过 app 发起的 Codex 任务正在运行。")
        }

        isSubmitting = true
        defer { isSubmitting = false }
        lastLaunchErrorMessage = nil

        let sessionID = UUID().uuidString.lowercased()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [bridgeScriptURL.path, "exec", trimmedPrompt]
        process.currentDirectoryURL = projectRootURL

        var processEnvironment = sanitizedEnvironment
        processEnvironment["CODEX_LOBSTER_SESSION_ID"] = sessionID
        process.environment = processEnvironment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        process.terminationHandler = { [weak self] terminatedProcess in
            guard let self else { return }
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let combined = String(data: stdoutData + stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            Task { @MainActor in
                self.activeProcesses.removeValue(forKey: sessionID)
                if self.activeSessionID == sessionID {
                    self.activeSessionID = nil
                }
                if terminatedProcess.terminationStatus != 0 {
                    self.lastLaunchErrorMessage = combined?.isEmpty == false
                        ? combined
                        : "Codex 任务启动失败（exit \(terminatedProcess.terminationStatus)）。"
                }
            }
        }

        do {
            try process.run()
            activeProcesses[sessionID] = process
            activeSessionID = sessionID
        } catch {
            lastLaunchErrorMessage = error.localizedDescription
            throw TaskLaunchError.launchFailed(error.localizedDescription)
        }
    }

    private var sanitizedEnvironment: [String: String] {
        var next = environment
        next["PWD"] = projectRootURL.path
        next["PATH"] = resolvedLaunchPath
        next.removeValue(forKey: "OLDPWD")
        next.removeValue(forKey: "CODEX_THREAD_ID")
        next.removeValue(forKey: "CODEX_INTERNAL_ORIGINATOR_OVERRIDE")
        next.removeValue(forKey: "CODEX_SHELL")
        return next
    }

    private func resolveCodexBinaryPath() -> String? {
        if let override = environment["CODEX_LOBSTER_CODEX_BIN"], fileManager.isExecutableFile(atPath: override) {
            return override
        }

        let bundled = "/Applications/Codex.app/Contents/Resources/codex"
        if fileManager.isExecutableFile(atPath: bundled) {
            return bundled
        }

        let searchRoots = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
            + Self.commonExecutableRoots

        for root in searchRoots {
            let candidate = URL(fileURLWithPath: root).appendingPathComponent("codex").path
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    private var resolvedLaunchPath: String {
        let existing = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let merged = Array(NSOrderedSet(array: existing + Self.commonExecutableRoots).array as? [String] ?? Self.commonExecutableRoots)
        return merged.joined(separator: ":")
    }

    private func runCommand(launchPath: String, arguments: [String]) async throws -> CommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments
            process.currentDirectoryURL = projectRootURL
            process.environment = sanitizedEnvironment

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { terminatedProcess in
                let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(
                    returning: CommandResult(
                        exitCode: terminatedProcess.terminationStatus,
                        stdout: String(data: stdout, encoding: .utf8) ?? "",
                        stderr: String(data: stderr, encoding: .utf8) ?? ""
                    )
                )
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func defaultProjectRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func resolveBridgeScriptURL(projectRootURL: URL) -> URL {
        if let bundledURL = Bundle.module.url(forResource: "codex-bridge", withExtension: "py", subdirectory: "Bridge") {
            return bundledURL
        }
        if let packagedResourcesURL = Bundle.main.resourceURL?
            .appendingPathComponent("CodexLobsterIsland_CodexLobsterIsland.bundle", isDirectory: true)
            .appendingPathComponent("codex-bridge.py"),
           FileManager.default.fileExists(atPath: packagedResourcesURL.path) {
            return packagedResourcesURL
        }
        return projectRootURL.appendingPathComponent("scripts/codex-bridge.py")
    }

    private static let commonExecutableRoots = [
        "/Applications/Codex.app/Contents/Resources",
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ]
}

private struct CommandResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        [stdout, stderr]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

enum TaskLaunchError: LocalizedError {
    case codexUnavailable(String)
    case authenticationFailed(String)
    case bridgeUnavailable(String)
    case invalidPrompt
    case notAuthenticated
    case busy(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case let .codexUnavailable(message),
             let .authenticationFailed(message),
             let .bridgeUnavailable(message),
             let .busy(message),
             let .launchFailed(message):
            return message
        case .invalidPrompt:
            return "请输入一条要交给 Codex 的任务。"
        case .notAuthenticated:
            return "当前还没有登录 Codex。"
        }
    }
}
