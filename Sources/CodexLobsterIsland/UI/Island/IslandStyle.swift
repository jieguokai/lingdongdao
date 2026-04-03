import SwiftUI

enum IslandStyle {
    static func background(for state: CodexState) -> AnyShapeStyle {
        AnyShapeStyle(shellGradient(for: state))
    }

    static func shellGradient(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(.sRGB, red: 0.105, green: 0.125, blue: 0.158, opacity: 0.98),
                Color(.sRGB, red: 0.085, green: 0.098, blue: 0.128, opacity: 0.99),
                accent(for: state).opacity(0.06),
                Color(.sRGB, red: 0.055, green: 0.065, blue: 0.089, opacity: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func materialWash(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.035),
                accent(for: state).opacity(0.035),
                Color.black.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var edgeHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                Color.white.opacity(0.08),
                Color.white.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var innerStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.black.opacity(0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var topSheen: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Color.white.opacity(0.05),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func glow(for state: CodexState) -> Color {
        accent(for: state).opacity(0.18)
    }

    static func accent(for state: CodexState) -> Color {
        switch state {
        case .idle:
            Color(.sRGB, red: 0.46, green: 0.61, blue: 0.97, opacity: 1)
        case .running:
            Color(.sRGB, red: 0.13, green: 0.73, blue: 0.91, opacity: 1)
        case .success:
            Color(.sRGB, red: 0.24, green: 0.79, blue: 0.55, opacity: 1)
        case .error:
            Color(.sRGB, red: 0.95, green: 0.43, blue: 0.36, opacity: 1)
        }
    }

    static var panelFill: Color {
        Color.white.opacity(0.05)
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(.sRGB, red: 0.132, green: 0.148, blue: 0.184, opacity: 0.96),
                Color(.sRGB, red: 0.106, green: 0.118, blue: 0.152, opacity: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardAccentWash(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                accent(for: state).opacity(0.09),
                accent(for: state).opacity(0.015),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardStroke: Color {
        Color.white.opacity(0.11)
    }

    static var cardInnerStroke: Color {
        Color.white.opacity(0.06)
    }

    static func avatarPlateFill(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(.sRGB, red: 0.16, green: 0.19, blue: 0.24, opacity: 1),
                Color(.sRGB, red: 0.09, green: 0.11, blue: 0.14, opacity: 1),
                accent(for: state).opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var avatarPlateSheen: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0.02),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func avatarGlow(for state: CodexState) -> Color {
        accent(for: state).opacity(0.22)
    }

    static func statusDotFill(for state: CodexState) -> LinearGradient {
        LinearGradient(
            colors: [
                accent(for: state).opacity(0.98),
                accent(for: state).opacity(0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func microChipFill(for state: CodexState) -> Color {
        accent(for: state).opacity(0.12)
    }

    static func microChipStroke(for state: CodexState) -> Color {
        accent(for: state).opacity(0.22)
    }

    static var separator: Color {
        Color.white.opacity(0.08)
    }

    static var primaryText: Color {
        Color.white.opacity(0.96)
    }

    static var compactTitleText: Color {
        Color(.sRGB, red: 0.99, green: 0.995, blue: 1.0, opacity: 1)
    }

    static var secondaryText: Color {
        Color.white.opacity(0.78)
    }

    static var tertiaryText: Color {
        Color.white.opacity(0.56)
    }

    static var quaternaryText: Color {
        Color.white.opacity(0.42)
    }
}
