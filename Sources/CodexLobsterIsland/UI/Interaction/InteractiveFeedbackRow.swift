import SwiftUI

struct InteractiveFeedbackRow<Content: View>: View {
    let prominence: InteractionProminence
    let accentColor: Color
    let cornerRadius: CGFloat
    let animationsEnabled: Bool
    let fillOpacity: Double
    var isCompact = false
    let content: () -> Content

    @State private var isHovered = false
    @GestureState private var isPressed = false

    init(
        prominence: InteractionProminence = .subtle,
        accentColor: Color,
        cornerRadius: CGFloat = 14,
        animationsEnabled: Bool,
        fillOpacity: Double = 0.08,
        isCompact: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.prominence = prominence
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.animationsEnabled = animationsEnabled
        self.fillOpacity = fillOpacity
        self.isCompact = isCompact
        self.content = content
    }

    private var phase: InteractivePhase {
        if isPressed {
            return .pressed
        }
        return isHovered ? .hovered : .resting
    }

    var body: some View {
        let baseFill: Color = isCompact ? .clear : IslandStyle.codexSectionFill
        let overlayOpacity = fillOpacity * (phase == .resting ? 0.45 : (phase == .pressed ? 1.2 : 0.9))

        content()
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 6 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(baseFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill((isCompact ? Color.white : accentColor).opacity(overlayOpacity))
                    }
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}
