import SwiftUI

struct InteractiveSurfaceModifier: ViewModifier {
    let phase: InteractivePhase
    let prominence: InteractionProminence
    let accentColor: Color
    let cornerRadius: CGFloat
    let animationsEnabled: Bool

    func body(content: Content) -> some View {
        let style = InteractionStyle.surface(
            for: phase,
            prominence: prominence,
            animationsEnabled: animationsEnabled
        )

        content
            .scaleEffect(style.scale)
            .offset(y: style.yOffset)
            .shadow(
                color: .black.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: max(2.0, 5.0 - style.yOffset)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(style.highlightOpacity),
                                Color.white.opacity(style.highlightOpacity * 0.55),
                                accentColor.opacity(style.glowOpacity * 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(style.highlightOpacity * 0.9),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(12.0, cornerRadius))
                    .blur(radius: 5.0)
                    .allowsHitTesting(false)
            }
            .animation(Self.animation(for: phase, animationsEnabled: animationsEnabled), value: phase)
    }

    private static func animation(for phase: InteractivePhase, animationsEnabled: Bool) -> Animation {
        if !animationsEnabled {
            return .easeOut(duration: 0.16)
        }

        switch phase {
        case .resting:
            return Animation.spring(response: 0.34, dampingFraction: 0.82)
        case .hovered:
            return Animation.spring(response: 0.28, dampingFraction: 0.76)
        case .pressed:
            return Animation.spring(response: 0.16, dampingFraction: 0.74)
        }
    }
}

extension View {
    func interactiveSurface(
        phase: InteractivePhase,
        prominence: InteractionProminence,
        accentColor: Color,
        cornerRadius: CGFloat,
        animationsEnabled: Bool
    ) -> some View {
        modifier(
            InteractiveSurfaceModifier(
                phase: phase,
                prominence: prominence,
                accentColor: accentColor,
                cornerRadius: cornerRadius,
                animationsEnabled: animationsEnabled
            )
        )
    }
}

struct InteractiveCard<Content: View>: View {
    let prominence: InteractionProminence
    let accentColor: Color
    let cornerRadius: CGFloat
    let animationsEnabled: Bool
    let content: (InteractivePhase) -> Content

    @State private var isHovered = false
    @GestureState private var isPressed = false

    init(
        prominence: InteractionProminence = .secondary,
        accentColor: Color,
        cornerRadius: CGFloat = 20,
        animationsEnabled: Bool,
        @ViewBuilder content: @escaping (InteractivePhase) -> Content
    ) {
        self.prominence = prominence
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.animationsEnabled = animationsEnabled
        self.content = content
    }

    private var phase: InteractivePhase {
        if isPressed {
            return .pressed
        }
        return isHovered ? .hovered : .resting
    }

    var body: some View {
        content(phase)
            .interactiveSurface(
                phase: phase,
                prominence: prominence,
                accentColor: accentColor,
                cornerRadius: cornerRadius,
                animationsEnabled: animationsEnabled
            )
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
