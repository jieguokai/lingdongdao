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
        content()
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 6 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        accentColor.opacity(
                            fillOpacity + (phase == .hovered ? 0.04 : 0.0) + (phase == .pressed ? 0.06 : 0.0)
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}
