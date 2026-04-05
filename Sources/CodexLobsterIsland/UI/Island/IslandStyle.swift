import SwiftUI

enum IslandStyle {
    static var notchFill: LinearGradient {
        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.024, green: 0.024, blue: 0.028, opacity: 0.998),
                Color(.sRGB, red: 0.010, green: 0.010, blue: 0.012, opacity: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var notchEdge: Color {
        .clear
    }

    static var notchInnerEdge: Color {
        .clear
    }

    static var codexPanelFill: LinearGradient {
        notchFill
    }

    static var codexPanelStroke: Color {
        .clear
    }

    static var codexPanelInnerStroke: Color {
        .clear
    }

    static var codexPanelConnectorFill: LinearGradient {
        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.068, green: 0.073, blue: 0.083, opacity: 1),
                Color(.sRGB, red: 0.052, green: 0.056, blue: 0.066, opacity: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var codexPanelConnectorStroke: Color {
        Color.white.opacity(0.05)
    }

    static var codexSectionFill: Color {
        Color.white.opacity(0.015)
    }

    static var codexSectionElevatedFill: Color {
        Color.white.opacity(0.028)
    }

    static var codexSectionStroke: Color {
        .clear
    }

    static var codexSectionSeparator: Color {
        Color.white.opacity(0.035)
    }

    static var codexHeaderText: Color {
        Color.white.opacity(0.98)
    }

    static var codexSectionTitleText: Color {
        Color.white.opacity(0.68)
    }

    static var codexHeaderRule: Color {
        Color.white.opacity(0.035)
    }

    static var codexPanelShadow: Color {
        Color.black.opacity(0.32)
    }

    static var codexPanelGlowShadow: Color {
        Color.black.opacity(0.08)
    }

    static func background(for state: CodexState) -> AnyShapeStyle {
        AnyShapeStyle(shellGradient(for: state))
    }

    static func shellGradient(for state: CodexState) -> LinearGradient {
        if state == .idle {
            return LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.018, green: 0.018, blue: 0.020, opacity: 1.0),
                    Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.030, green: 0.031, blue: 0.036, opacity: 1.0),
                Color(.sRGB, red: 0.014, green: 0.015, blue: 0.018, opacity: 1.0),
                accent(for: state).opacity(0.025)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func materialWash(for state: CodexState) -> LinearGradient {
        if state == .idle {
            return LinearGradient(
                colors: [
                    Color.black,
                    Color.black,
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(0.016),
                accent(for: state).opacity(0.02),
                Color.black.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var edgeHighlight: LinearGradient {
        return LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                Color.white.opacity(0.04),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var innerStroke: LinearGradient {
        return LinearGradient(
            colors: [
                .clear,
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var topSheen: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.02),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func glow(for state: CodexState) -> Color {
        if state == .idle {
            return .clear
        }
        return accent(for: state).opacity(0.06)
    }

    static func accent(for state: CodexState) -> Color {
        switch state {
        case .idle:
            Color(.sRGB, red: 0.46, green: 0.61, blue: 0.97, opacity: 1)
        case .typing:
            Color(.sRGB, red: 0.95, green: 0.72, blue: 0.26, opacity: 1)
        case .running:
            Color(.sRGB, red: 0.13, green: 0.73, blue: 0.91, opacity: 1)
        case .awaitingReply:
            Color(.sRGB, red: 0.98, green: 0.76, blue: 0.26, opacity: 1)
        case .awaitingApproval:
            Color(.sRGB, red: 0.99, green: 0.64, blue: 0.22, opacity: 1)
        case .success:
            Color(.sRGB, red: 0.24, green: 0.79, blue: 0.55, opacity: 1)
        case .error:
            Color(.sRGB, red: 0.95, green: 0.43, blue: 0.36, opacity: 1)
        }
    }

    static var panelFill: Color {
        Color.white.opacity(0.02)
    }

    static var cardFill: LinearGradient {
        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.030, green: 0.031, blue: 0.036, opacity: 0.98),
                Color(.sRGB, red: 0.016, green: 0.017, blue: 0.020, opacity: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardAccentWash(for state: CodexState) -> LinearGradient {
        if state == .idle {
            return LinearGradient(
                colors: [.clear, .clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                accent(for: state).opacity(0.04),
                accent(for: state).opacity(0.01),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardStroke: Color {
        .clear
    }

    static var cardInnerStroke: Color {
        .clear
    }

    static func avatarPlateFill(for state: CodexState) -> LinearGradient {
        if state == .idle {
            return LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.020, green: 0.020, blue: 0.022, opacity: 1),
                    Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0, opacity: 1),
                    Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0, opacity: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.040, green: 0.042, blue: 0.048, opacity: 1),
                Color(.sRGB, red: 0.016, green: 0.017, blue: 0.020, opacity: 1),
                accent(for: state).opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var avatarPlateSheen: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.white.opacity(0.01),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func avatarGlow(for state: CodexState) -> Color {
        if state == .idle {
            return .clear
        }
        return accent(for: state).opacity(0.12)
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
        accent(for: state).opacity(0.06)
    }

    static func microChipStroke(for state: CodexState) -> Color {
        accent(for: state).opacity(0.10)
    }

    static var separator: Color {
        Color.white.opacity(0.045)
    }

    static var primaryText: Color {
        Color.white.opacity(0.96)
    }

    static var compactTitleText: Color {
        Color(.sRGB, red: 0.99, green: 0.995, blue: 1.0, opacity: 1)
    }

    static var secondaryText: Color {
        Color.white.opacity(0.72)
    }

    static var tertiaryText: Color {
        Color.white.opacity(0.50)
    }

    static var quaternaryText: Color {
        Color.white.opacity(0.34)
    }

    static var compactPromptText: Color {
        Color.white.opacity(0.60)
    }

    static func approvalSectionFill(for state: CodexState) -> Color {
        accent(for: state).opacity(0.05)
    }

    static func approvalSectionStroke(for state: CodexState) -> Color {
        .clear
    }
}
