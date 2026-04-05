import SwiftUI

struct InteractiveSurfaceModifier: ViewModifier {
    let phase: InteractivePhase
    let prominence: InteractionProminence
    let accentColor: Color
    let cornerRadius: CGFloat
    let animationsEnabled: Bool
    let allowsScaling: Bool

    func body(content: Content) -> some View {
        let style = InteractionStyle.surface(
            for: phase,
            prominence: prominence,
            animationsEnabled: animationsEnabled
        )

        content
            .scaleEffect(allowsScaling ? style.scale : 1.0)
            .offset(y: style.yOffset)
            .shadow(
                color: .black.opacity(style.shadowOpacity),
                radius: max(4.0, style.shadowRadius * 0.65),
                x: 0,
                y: max(1.0, 3.5 - style.yOffset)
            )
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
        animationsEnabled: Bool,
        allowsScaling: Bool = false
    ) -> some View {
        modifier(
            InteractiveSurfaceModifier(
                phase: phase,
                prominence: prominence,
                accentColor: accentColor,
                cornerRadius: cornerRadius,
                animationsEnabled: animationsEnabled,
                allowsScaling: allowsScaling
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
