import SwiftUI

enum IslandStyle {
    static func background(for state: CodexState) -> AnyShapeStyle {
        _ = state
        return AnyShapeStyle(.ultraThinMaterial)
    }

    static func tintOverlay(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(.sRGB, red: 0.07, green: 0.08, blue: 0.11, opacity: 0.46),
                accent(for: state).opacity(0.05),
                Color(.sRGB, red: 0.04, green: 0.05, blue: 0.07, opacity: 0.34)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var edgeHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.20),
                Color.white.opacity(0.09),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glow(for state: CodexState) -> Color {
        accent(for: state).opacity(0.16)
    }

    static func accent(for state: CodexState) -> Color {
        switch state {
        case .idle:
            Color(.sRGB, red: 0.37, green: 0.56, blue: 0.96, opacity: 1)
        case .running:
            Color(.sRGB, red: 0.14, green: 0.72, blue: 0.95, opacity: 1)
        case .success:
            Color(.sRGB, red: 0.22, green: 0.79, blue: 0.52, opacity: 1)
        case .error:
            Color(.sRGB, red: 1.0, green: 0.42, blue: 0.38, opacity: 1)
        }
    }

    static var panelFill: Color {
        Color.white.opacity(0.06)
    }

    static var separator: Color {
        Color.white.opacity(0.10)
    }

    static var secondaryText: Color {
        Color.white.opacity(0.76)
    }

    static var tertiaryText: Color {
        Color.white.opacity(0.58)
    }
}
