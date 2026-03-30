import SwiftUI

enum IslandStyle {
    static func background(for state: CodexState) -> LinearGradient {
        let colors: [Color]
        switch state {
        case .idle:
            colors = [Color.black.opacity(0.9), Color.blue.opacity(0.55)]
        case .running:
            colors = [Color.black.opacity(0.92), Color.teal.opacity(0.7)]
        case .success:
            colors = [Color.black.opacity(0.9), Color.green.opacity(0.72)]
        case .error:
            colors = [Color.black.opacity(0.92), Color.red.opacity(0.72)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func glow(for state: CodexState) -> Color {
        switch state {
        case .idle:
            Color.blue.opacity(0.25)
        case .running:
            Color.cyan.opacity(0.32)
        case .success:
            Color.green.opacity(0.36)
        case .error:
            Color.red.opacity(0.35)
        }
    }
}
