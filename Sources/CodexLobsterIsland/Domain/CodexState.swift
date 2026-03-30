import Foundation

package enum CodexState: String, Codable, CaseIterable, Sendable {
    case idle
    case running
    case success
    case error

    var displayName: String {
        rawValue.capitalized
    }

    var symbolName: String {
        switch self {
        case .idle:
            "moon.stars.fill"
        case .running:
            "bolt.circle.fill"
        case .success:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var menuBarLabel: String {
        switch self {
        case .idle:
            "Idle"
        case .running:
            "Running"
        case .success:
            "Success"
        case .error:
            "Error"
        }
    }

    var subtitle: String {
        switch self {
        case .idle:
            "Calm breathing"
        case .running:
            "Looping motion"
        case .success:
            "Celebration ping"
        case .error:
            "Warning shake"
        }
    }
}
