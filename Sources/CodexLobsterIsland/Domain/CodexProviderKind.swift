import Foundation

enum CodexProviderKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case mock
    case processWatcher
    case logParser
    case socketEvent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mock:
            "Mock"
        case .processWatcher:
            "Process Watcher"
        case .logParser:
            "Log Parser"
        case .socketEvent:
            "Socket Event"
        }
    }

    var subtitle: String {
        switch self {
        case .mock:
            "Built-in demo flow for MVP"
        case .processWatcher:
            "Observe a local Codex process"
        case .logParser:
            "Read status from structured logs"
        case .socketEvent:
            "Receive status over a local socket"
        }
    }
}
