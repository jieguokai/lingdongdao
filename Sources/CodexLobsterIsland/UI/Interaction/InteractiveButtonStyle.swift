import SwiftUI

struct InteractiveButtonStyle: ButtonStyle {
    let prominence: InteractionProminence
    let accentColor: Color
    let cornerRadius: CGFloat
    let fillOpacity: Double
    let animationsEnabled: Bool
    let expandsHorizontally: Bool

    init(
        prominence: InteractionProminence = .subtle,
        accentColor: Color,
        cornerRadius: CGFloat = 16,
        fillOpacity: Double = 0.16,
        animationsEnabled: Bool,
        expandsHorizontally: Bool = false
    ) {
        self.prominence = prominence
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.fillOpacity = fillOpacity
        self.animationsEnabled = animationsEnabled
        self.expandsHorizontally = expandsHorizontally
    }

    func makeBody(configuration: Configuration) -> some View {
        InteractiveButtonBody(
            configuration: configuration,
            prominence: prominence,
            accentColor: accentColor,
            cornerRadius: cornerRadius,
            fillOpacity: fillOpacity,
            animationsEnabled: animationsEnabled,
            expandsHorizontally: expandsHorizontally
        )
    }

    private struct InteractiveButtonBody: View {
        let configuration: Configuration
        let prominence: InteractionProminence
        let accentColor: Color
        let cornerRadius: CGFloat
        let fillOpacity: Double
        let animationsEnabled: Bool
        let expandsHorizontally: Bool

        @State private var isHovered = false

        private var phase: InteractivePhase {
            if configuration.isPressed {
                return .pressed
            }
            return isHovered ? .hovered : .resting
        }

        var body: some View {
            let backgroundOpacity: Double = {
                switch prominence {
                case .primary:
                    return phase == .pressed ? max(fillOpacity, 0.18) : max(fillOpacity, 0.14)
                case .secondary:
                    return phase == .resting ? 0.03 : 0.06
                case .subtle:
                    return phase == .resting ? 0.0 : 0.04
                }
            }()
            let labelColor: Color = {
                switch prominence {
                case .primary:
                    return IslandStyle.primaryText
                case .secondary:
                    return phase == .resting ? IslandStyle.secondaryText : IslandStyle.primaryText
                case .subtle:
                    return phase == .resting ? IslandStyle.tertiaryText : IslandStyle.secondaryText
                }
            }()
            let backgroundColor = prominence == .primary ? accentColor.opacity(backgroundOpacity) : Color.white.opacity(backgroundOpacity)

            configuration.label
                .foregroundStyle(labelColor)
                .frame(maxWidth: expandsHorizontally ? .infinity : nil, alignment: .leading)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(backgroundColor)
                )
                .interactiveSurface(
                    phase: phase,
                    prominence: prominence,
                    accentColor: accentColor,
                    cornerRadius: cornerRadius,
                    animationsEnabled: animationsEnabled
                )
                .contentShape(Capsule(style: .continuous))
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}
