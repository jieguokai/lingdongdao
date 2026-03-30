import SwiftUI

struct LobsterAvatarView: View {
    let state: CodexState
    let animationsEnabled: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            let metrics = motionMetrics(phase: phase)

            ZStack {
                Circle()
                    .fill(glowColor.opacity(0.18))
                    .blur(radius: 8)
                    .scaleEffect(1.15)

                GeometryReader { proxy in
                    let pixel = min(proxy.size.width, proxy.size.height) / 16
                    ForEach(PixelLobsterShape.pixels) { square in
                        RoundedRectangle(cornerRadius: pixel * 0.16, style: .continuous)
                            .fill(color(for: square.role))
                            .frame(width: pixel * 0.92, height: pixel * 0.92)
                            .position(
                                x: (CGFloat(square.x) + 0.5) * pixel,
                                y: (CGFloat(square.y) + 0.5) * pixel
                            )
                    }
                }
            }
            .padding(6)
            .scaleEffect(metrics.scale)
            .rotationEffect(metrics.rotation)
            .offset(x: metrics.xOffset, y: metrics.yOffset)
        }
    }

    private var glowColor: Color {
        switch state {
        case .idle:
            .blue
        case .running:
            .teal
        case .success:
            .green
        case .error:
            .red
        }
    }

    private func color(for role: PixelLobsterShape.Pixel.Role) -> Color {
        switch role {
        case .shell:
            return state == .error ? Color.red.opacity(0.95) : Color.orange.opacity(0.95)
        case .claw:
            return state == .success ? Color.green.opacity(0.95) : Color.pink.opacity(0.95)
        case .belly:
            return Color.white.opacity(0.9)
        case .eye:
            return Color.black.opacity(0.9)
        }
    }

    private func motionMetrics(phase: TimeInterval) -> (scale: CGFloat, rotation: Angle, xOffset: CGFloat, yOffset: CGFloat) {
        guard animationsEnabled else {
            return (1.0, .degrees(0), 0, 0)
        }

        switch state {
        case .idle:
            return (
                0.98 + (sin(phase * 2.2) * 0.04),
                .degrees(0),
                0,
                sin(phase * 2.2) * -1.8
            )
        case .running:
            return (
                1.0,
                .degrees(sin(phase * 10.0) * 6),
                sin(phase * 10.0) * 2.8,
                cos(phase * 10.0) * -1.4
            )
        case .success:
            return (
                1.0 + abs(sin(phase * 7.0)) * 0.12,
                .degrees(sin(phase * 7.0) * 10),
                0,
                abs(cos(phase * 7.0)) * -5.0
            )
        case .error:
            return (
                1.0,
                .degrees(sin(phase * 18.0) * 3),
                sin(phase * 18.0) * 5.0,
                0
            )
        }
    }
}
