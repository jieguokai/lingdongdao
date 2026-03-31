import SwiftUI

struct LobsterAvatarView: View {
    let state: CodexState
    let animationsEnabled: Bool
    var interactionPhase: InteractivePhase = .resting
    var contentPadding: CGFloat = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let timelinePhase = context.date.timeIntervalSinceReferenceDate
            let pixels = PixelLobsterSprite.pixels(for: state, tick: frameTick(for: timelinePhase))
            let bounds = PixelLobsterSprite.renderBounds
            let interaction = InteractionStyle.lobster(
                for: interactionPhase,
                animationsEnabled: animationsEnabled
            )
            let swayOffset = animationsEnabled
                ? CGFloat(sin(timelinePhase * 6.0)) * interaction.sway
                : 0.0

            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width - (contentPadding * 2), 1)
                let availableHeight = max(proxy.size.height - (contentPadding * 2), 1)
                let spriteWidth = CGFloat(bounds.width)
                let spriteHeight = CGFloat(bounds.height)
                let pixel = min(availableWidth / spriteWidth, availableHeight / spriteHeight)
                let xInset = contentPadding + ((availableWidth - (spriteWidth * pixel)) / 2)
                let yInset = contentPadding + ((availableHeight - (spriteHeight * pixel)) / 2)

                ForEach(pixels) { square in
                    RoundedRectangle(cornerRadius: pixel * 0.16, style: .continuous)
                        .fill(color(for: square))
                        .frame(width: pixel * 0.92, height: pixel * 0.92)
                        .position(
                            x: xInset + (CGFloat(square.x - bounds.minX) + 0.5) * pixel,
                            y: yInset + (CGFloat(square.y - bounds.minY) + 0.5) * pixel
                        )
                }
            }
            .scaleEffect(interaction.scale)
            .offset(x: swayOffset, y: interaction.yOffset)
            .animation(.spring(response: 0.24, dampingFraction: 0.76), value: interactionPhase)
        }
    }

    private func color(for pixel: PixelLobsterSprite.Pixel) -> Color {
        switch pixel.role {
        case .shell:
            let base = state == .error
                ? Color(.sRGB, red: 0.96, green: 0.34, blue: 0.31, opacity: 1)
                : Color(.sRGB, red: 1.0, green: 0.57, blue: 0.23, opacity: 1)
            return base.opacity(0.92)
        case .claw:
            let base = state == .success
                ? Color(.sRGB, red: 0.35, green: 0.85, blue: 0.56, opacity: 1)
                : Color(.sRGB, red: 1.0, green: 0.42, blue: 0.46, opacity: 1)
            return base.opacity(0.92)
        case .belly:
            return Color(.sRGB, white: 0.97, opacity: 0.94)
        case .eye:
            return Color.black.opacity(0.94)
        }
    }

    private func frameTick(for phase: TimeInterval) -> Int {
        guard animationsEnabled else { return 0 }
        return Int((phase * PixelLobsterSprite.tickRate(for: state)).rounded(.down))
    }
}
