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
            let fillColor: Color = {
                switch prominence {
                case .primary:
                    return accentColor
                case .secondary, .subtle:
                    return .white
                }
            }()

            configuration.label
                .frame(maxWidth: expandsHorizontally ? .infinity : nil, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            fillColor.opacity(
                                fillOpacity + (phase == .hovered ? 0.05 : 0.0) + (phase == .pressed ? 0.08 : 0.0)
                            )
                        )
                )
                .interactiveSurface(
                    phase: phase,
                    prominence: prominence,
                    accentColor: accentColor,
                    cornerRadius: cornerRadius,
                    animationsEnabled: animationsEnabled
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}
