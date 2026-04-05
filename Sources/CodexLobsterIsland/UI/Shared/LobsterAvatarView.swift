import SwiftUI

struct LobsterAvatarView: View {
    let state: CodexState
    let animationsEnabled: Bool
    var interactionPhase: InteractivePhase = .resting
    var contentPadding: CGFloat = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let timelinePhase = context.date.timeIntervalSinceReferenceDate
            let renderedSprite = reducedSprite(
                from: PixelLobsterSprite.pixels(for: state, tick: frameTick(for: timelinePhase)),
                bounds: PixelLobsterSprite.renderBounds,
                factor: 2
            )
            let interaction = InteractionStyle.lobster(
                for: interactionPhase,
                animationsEnabled: animationsEnabled
            )
            let swayOffset = animationsEnabled
                ? CGFloat(sin(timelinePhase * 6.0)) * interaction.sway
                : 0.0

            ZStack {
                Circle()
                    .fill(IslandStyle.avatarGlow(for: state))
                    .scaleEffect(interactionPhase == .hovered ? 1.0 : 0.94)
                    .blur(radius: interactionPhase == .pressed ? 4 : 5)
                    .opacity(interactionPhase == .resting ? 0.10 : 0.16)

                GeometryReader { proxy in
                    let availableWidth = max(proxy.size.width - (contentPadding * 2), 1)
                    let availableHeight = max(proxy.size.height - (contentPadding * 2), 1)
                    let spriteWidth = CGFloat(renderedSprite.bounds.width)
                    let spriteHeight = CGFloat(renderedSprite.bounds.height)
                    let pixel = min(availableWidth / spriteWidth, availableHeight / spriteHeight)
                    let xInset = contentPadding + ((availableWidth - (spriteWidth * pixel)) / 2)
                    let yInset = contentPadding + ((availableHeight - (spriteHeight * pixel)) / 2)
                    // 整体降一档分辨率后，再把单个像素块略微缩小，保留像素之间的缝隙。
                    let pixelBlock = pixel * 0.82

                    ForEach(renderedSprite.pixels) { square in
                        Rectangle()
                            .fill(color(for: square))
                            .frame(width: pixelBlock, height: pixelBlock)
                            .position(
                                x: xInset + (CGFloat(square.x - renderedSprite.bounds.minX) + 0.5) * pixel,
                                y: yInset + (CGFloat(square.y - renderedSprite.bounds.minY) + 0.5) * pixel
                            )
                    }
                }
            }
            .scaleEffect(interaction.scale)
            .offset(x: swayOffset, y: interaction.yOffset - 0.2)
            .animation(.spring(response: 0.24, dampingFraction: 0.76), value: interactionPhase)
        }
    }

    private func color(for pixel: PixelLobsterSprite.Pixel) -> Color {
        switch pixel.role {
        case .outline:
            return Color(.sRGB, red: 0.07, green: 0.04, blue: 0.05, opacity: 0.99)
        case .shellHighlight:
            return palette.shellHighlight
        case .shell:
            return palette.shell
        case .shellShadow:
            return palette.shellShadow
        case .belly:
            return palette.belly
        case .bellyShadow:
            return palette.bellyShadow
        case .eyeWhite:
            return Color.white.opacity(0.98)
        case .eyePupil:
            return Color.white.opacity(0.98)
        }
    }

    private var palette: LobsterPalette {
        switch state {
        case .idle:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 0.72, green: 0.83, blue: 1.0, opacity: 1),
                shell: Color(.sRGB, red: 0.46, green: 0.61, blue: 0.97, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.18, green: 0.29, blue: 0.56, opacity: 1),
                belly: Color(.sRGB, red: 0.60, green: 0.73, blue: 1.0, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.29, green: 0.41, blue: 0.72, opacity: 1)
            )
        case .typing:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 1.0, green: 0.87, blue: 0.49, opacity: 1),
                shell: Color(.sRGB, red: 0.95, green: 0.72, blue: 0.26, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.59, green: 0.40, blue: 0.10, opacity: 1),
                belly: Color(.sRGB, red: 1.0, green: 0.80, blue: 0.39, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.76, green: 0.55, blue: 0.16, opacity: 1)
            )
        case .running:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 0.56, green: 0.92, blue: 1.0, opacity: 1),
                shell: Color(.sRGB, red: 0.13, green: 0.73, blue: 0.91, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.04, green: 0.34, blue: 0.50, opacity: 1),
                belly: Color(.sRGB, red: 0.34, green: 0.84, blue: 1.0, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.07, green: 0.47, blue: 0.62, opacity: 1)
            )
        case .awaitingReply:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 1.0, green: 0.88, blue: 0.50, opacity: 1),
                shell: Color(.sRGB, red: 0.98, green: 0.76, blue: 0.26, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.63, green: 0.46, blue: 0.08, opacity: 1),
                belly: Color(.sRGB, red: 1.0, green: 0.83, blue: 0.38, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.79, green: 0.59, blue: 0.14, opacity: 1)
            )
        case .awaitingApproval:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 1.0, green: 0.79, blue: 0.43, opacity: 1),
                shell: Color(.sRGB, red: 0.99, green: 0.64, blue: 0.22, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.67, green: 0.39, blue: 0.07, opacity: 1),
                belly: Color(.sRGB, red: 1.0, green: 0.73, blue: 0.34, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.82, green: 0.51, blue: 0.12, opacity: 1)
            )
        case .success:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 0.60, green: 0.92, blue: 0.72, opacity: 1),
                shell: Color(.sRGB, red: 0.24, green: 0.79, blue: 0.55, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.07, green: 0.42, blue: 0.27, opacity: 1),
                belly: Color(.sRGB, red: 0.42, green: 0.88, blue: 0.64, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.12, green: 0.54, blue: 0.35, opacity: 1)
            )
        case .error:
            return LobsterPalette(
                shellHighlight: Color(.sRGB, red: 1.0, green: 0.64, blue: 0.56, opacity: 1),
                shell: Color(.sRGB, red: 0.95, green: 0.43, blue: 0.36, opacity: 1),
                shellShadow: Color(.sRGB, red: 0.60, green: 0.19, blue: 0.17, opacity: 1),
                belly: Color(.sRGB, red: 1.0, green: 0.54, blue: 0.47, opacity: 1),
                bellyShadow: Color(.sRGB, red: 0.77, green: 0.28, blue: 0.24, opacity: 1)
            )
        }
    }

    private func frameTick(for phase: TimeInterval) -> Int {
        guard animationsEnabled else { return 0 }
        return Int((phase * PixelLobsterSprite.tickRate(for: state)).rounded(.down))
    }

    private func reducedSprite(
        from pixels: [PixelLobsterSprite.Pixel],
        bounds: PixelLobsterSprite.Bounds,
        factor: Int
    ) -> ReducedSprite {
        let safeFactor = max(factor, 1)
        var reduced: [BucketKey: PixelLobsterSprite.Pixel] = [:]

        for pixel in pixels {
            let bucket = BucketKey(
                x: (pixel.x - bounds.minX) / safeFactor,
                y: (pixel.y - bounds.minY) / safeFactor
            )

            if let current = reduced[bucket] {
                if rolePriority(pixel.role) >= rolePriority(current.role) {
                    reduced[bucket] = pixel
                }
            } else {
                reduced[bucket] = pixel
            }
        }

        let reducedPixels = reduced.map { entry in
            PixelLobsterSprite.Pixel(
                x: entry.key.x,
                y: entry.key.y,
                role: entry.value.role
            )
        }

        let reducedBounds = PixelLobsterSprite.Bounds(
            minX: 0,
            maxX: max((bounds.width - 1) / safeFactor, 0),
            minY: 0,
            maxY: max((bounds.height - 1) / safeFactor, 0)
        )

        return ReducedSprite(
            pixels: reducedPixels.sorted { lhs, rhs in
                lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
            },
            bounds: reducedBounds
        )
    }

    private func rolePriority(_ role: PixelLobsterSprite.Pixel.Role) -> Int {
        switch role {
        case .outline:
            return 7
        case .eyeWhite:
            return 6
        case .eyePupil:
            return 5
        case .shellHighlight:
            return 4
        case .shell:
            return 3
        case .shellShadow:
            return 2
        case .belly:
            return 1
        case .bellyShadow:
            return 0
        }
    }
}

private struct LobsterPalette {
    let shellHighlight: Color
    let shell: Color
    let shellShadow: Color
    let belly: Color
    let bellyShadow: Color
}

private struct ReducedSprite {
    let pixels: [PixelLobsterSprite.Pixel]
    let bounds: PixelLobsterSprite.Bounds
}

private struct BucketKey: Hashable {
    let x: Int
    let y: Int
}
