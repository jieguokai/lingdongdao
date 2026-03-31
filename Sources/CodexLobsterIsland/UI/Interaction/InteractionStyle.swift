import CoreGraphics

struct InteractionSurfaceStyle: Equatable {
    let scale: CGFloat
    let yOffset: CGFloat
    let rotationDegrees: Double
    let sheenOpacity: Double
    let sheenOffset: CGFloat
    let glowOpacity: Double
    let highlightOpacity: Double
    let shadowOpacity: Double
    let shadowRadius: CGFloat
}

struct LobsterInteractionStyle: Equatable {
    let scale: CGFloat
    let yOffset: CGFloat
    let sway: CGFloat
}

struct BadgeInteractionStyle: Equatable {
    let scale: CGFloat
    let yOffset: CGFloat
    let glowOpacity: Double
}

enum InteractionStyle {
    static func surface(
        for phase: InteractivePhase,
        prominence: InteractionProminence,
        animationsEnabled: Bool
    ) -> InteractionSurfaceStyle {
        let base = baseSurface(for: prominence)

        switch phase {
        case .resting:
            return base
        case .hovered:
            if animationsEnabled {
                return InteractionSurfaceStyle(
                    scale: base.scale + scaleDelta(for: prominence, hovered: true),
                    yOffset: base.yOffset - liftDelta(for: prominence, hovered: true),
                    rotationDegrees: base.rotationDegrees + rotationDelta(for: prominence, hovered: true),
                    sheenOpacity: base.sheenOpacity + sheenOpacityDelta(for: prominence, hovered: true),
                    sheenOffset: sheenOffset(for: prominence, hovered: true),
                    glowOpacity: base.glowOpacity + glowDelta(for: prominence, hovered: true),
                    highlightOpacity: base.highlightOpacity + highlightDelta(for: prominence, hovered: true),
                    shadowOpacity: base.shadowOpacity + shadowDelta(for: prominence, hovered: true),
                    shadowRadius: base.shadowRadius + radiusDelta(for: prominence, hovered: true)
                )
            }

            return InteractionSurfaceStyle(
                scale: base.scale + scaleDelta(for: prominence, hovered: false),
                yOffset: base.yOffset - liftDelta(for: prominence, hovered: false),
                rotationDegrees: base.rotationDegrees + rotationDelta(for: prominence, hovered: false),
                sheenOpacity: base.sheenOpacity + sheenOpacityDelta(for: prominence, hovered: false),
                sheenOffset: sheenOffset(for: prominence, hovered: false),
                glowOpacity: base.glowOpacity + glowDelta(for: prominence, hovered: false),
                highlightOpacity: base.highlightOpacity + highlightDelta(for: prominence, hovered: false),
                shadowOpacity: base.shadowOpacity + shadowDelta(for: prominence, hovered: false),
                shadowRadius: base.shadowRadius + radiusDelta(for: prominence, hovered: false)
            )
        case .pressed:
            if animationsEnabled {
                return InteractionSurfaceStyle(
                    scale: base.scale - pressedScaleDelta(for: prominence, reduced: false),
                    yOffset: base.yOffset + pressedOffsetDelta(for: prominence, reduced: false),
                    rotationDegrees: pressedRotationDelta(for: prominence, reduced: false),
                    sheenOpacity: base.sheenOpacity + pressedSheenOpacityDelta(for: prominence, reduced: false),
                    sheenOffset: pressedSheenOffset(for: prominence, reduced: false),
                    glowOpacity: base.glowOpacity + pressedGlowDelta(for: prominence, reduced: false),
                    highlightOpacity: base.highlightOpacity + pressedHighlightDelta(for: prominence, reduced: false),
                    shadowOpacity: max(base.shadowOpacity - 0.04, 0.0),
                    shadowRadius: max(base.shadowRadius - 2.0, 0.0)
                )
            }

            return InteractionSurfaceStyle(
                scale: base.scale - pressedScaleDelta(for: prominence, reduced: true),
                yOffset: base.yOffset + pressedOffsetDelta(for: prominence, reduced: true),
                rotationDegrees: pressedRotationDelta(for: prominence, reduced: true),
                sheenOpacity: base.sheenOpacity + pressedSheenOpacityDelta(for: prominence, reduced: true),
                sheenOffset: pressedSheenOffset(for: prominence, reduced: true),
                glowOpacity: base.glowOpacity + pressedGlowDelta(for: prominence, reduced: true),
                highlightOpacity: base.highlightOpacity + pressedHighlightDelta(for: prominence, reduced: true),
                shadowOpacity: max(base.shadowOpacity - 0.02, 0.0),
                shadowRadius: max(base.shadowRadius - 1.0, 0.0)
            )
        }
    }

    static func lobster(
        for phase: InteractivePhase,
        animationsEnabled: Bool
    ) -> LobsterInteractionStyle {
        switch phase {
        case .resting:
            return LobsterInteractionStyle(scale: 1.0, yOffset: 0.0, sway: 0.0)
        case .hovered:
            return animationsEnabled
                ? LobsterInteractionStyle(scale: 1.04, yOffset: -1.5, sway: 1.0)
                : LobsterInteractionStyle(scale: 1.01, yOffset: -0.5, sway: 0.2)
        case .pressed:
            return animationsEnabled
                ? LobsterInteractionStyle(scale: 0.97, yOffset: 1.0, sway: -0.8)
                : LobsterInteractionStyle(scale: 0.99, yOffset: 0.5, sway: -0.15)
        }
    }

    static func badge(
        for phase: InteractivePhase,
        animationsEnabled: Bool
    ) -> BadgeInteractionStyle {
        switch phase {
        case .resting:
            return BadgeInteractionStyle(scale: 1.0, yOffset: 0.0, glowOpacity: 0.12)
        case .hovered:
            return animationsEnabled
                ? BadgeInteractionStyle(scale: 1.06, yOffset: -0.8, glowOpacity: 0.26)
                : BadgeInteractionStyle(scale: 1.02, yOffset: -0.2, glowOpacity: 0.16)
        case .pressed:
            return animationsEnabled
                ? BadgeInteractionStyle(scale: 0.98, yOffset: 0.9, glowOpacity: 0.34)
                : BadgeInteractionStyle(scale: 0.995, yOffset: 0.4, glowOpacity: 0.18)
        }
    }

    private static func baseSurface(for prominence: InteractionProminence) -> InteractionSurfaceStyle {
        switch prominence {
        case .primary:
            InteractionSurfaceStyle(
                scale: 1.0,
                yOffset: 0.0,
                rotationDegrees: 0.0,
                sheenOpacity: 0.06,
                sheenOffset: -40.0,
                glowOpacity: 0.04,
                highlightOpacity: 0.09,
                shadowOpacity: 0.14,
                shadowRadius: 10.0
            )
        case .secondary:
            InteractionSurfaceStyle(
                scale: 1.0,
                yOffset: 0.0,
                rotationDegrees: 0.0,
                sheenOpacity: 0.04,
                sheenOffset: -30.0,
                glowOpacity: 0.03,
                highlightOpacity: 0.08,
                shadowOpacity: 0.10,
                shadowRadius: 8.0
            )
        case .subtle:
            InteractionSurfaceStyle(
                scale: 1.0,
                yOffset: 0.0,
                rotationDegrees: 0.0,
                sheenOpacity: 0.02,
                sheenOffset: -20.0,
                glowOpacity: 0.02,
                highlightOpacity: 0.06,
                shadowOpacity: 0.08,
                shadowRadius: 6.0
            )
        }
    }

    private static func scaleDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> CGFloat {
        switch (prominence, expressive) {
        case (.primary, true): 0.012
        case (.secondary, true): 0.008
        case (.subtle, true): 0.004
        case (.primary, false): 0.006
        case (.secondary, false): 0.004
        case (.subtle, false): 0.002
        }
    }

    private static func liftDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> CGFloat {
        switch (prominence, expressive) {
        case (.primary, true): 2.0
        case (.secondary, true): 1.2
        case (.subtle, true): 0.7
        case (.primary, false): 0.8
        case (.secondary, false): 0.5
        case (.subtle, false): 0.2
        }
    }

    private static func glowDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> Double {
        switch (prominence, expressive) {
        case (.primary, true): 0.03
        case (.secondary, true): 0.02
        case (.subtle, true): 0.01
        case (.primary, false): 0.015
        case (.secondary, false): 0.01
        case (.subtle, false): 0.005
        }
    }

    private static func rotationDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> Double {
        switch (prominence, expressive) {
        case (.primary, true): -0.42
        case (.secondary, true): -0.18
        case (.subtle, true): 0.0
        case (.primary, false): -0.10
        case (.secondary, false): -0.05
        case (.subtle, false): 0.0
        }
    }

    private static func sheenOpacityDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> Double {
        switch (prominence, expressive) {
        case (.primary, true): 0.24
        case (.secondary, true): 0.15
        case (.subtle, true): 0.08
        case (.primary, false): 0.08
        case (.secondary, false): 0.05
        case (.subtle, false): 0.03
        }
    }

    private static func sheenOffset(for prominence: InteractionProminence, hovered expressive: Bool) -> CGFloat {
        switch (prominence, expressive) {
        case (.primary, true): 44.0
        case (.secondary, true): 32.0
        case (.subtle, true): 18.0
        case (.primary, false): 16.0
        case (.secondary, false): 12.0
        case (.subtle, false): 8.0
        }
    }

    private static func highlightDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> Double {
        switch (prominence, expressive) {
        case (.primary, true): 0.10
        case (.secondary, true): 0.07
        case (.subtle, true): 0.04
        case (.primary, false): 0.04
        case (.secondary, false): 0.03
        case (.subtle, false): 0.02
        }
    }

    private static func shadowDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> Double {
        switch (prominence, expressive) {
        case (.primary, true): 0.04
        case (.secondary, true): 0.03
        case (.subtle, true): 0.02
        case (.primary, false): 0.02
        case (.secondary, false): 0.015
        case (.subtle, false): 0.01
        }
    }

    private static func radiusDelta(for prominence: InteractionProminence, hovered expressive: Bool) -> CGFloat {
        switch (prominence, expressive) {
        case (.primary, true): 4.0
        case (.secondary, true): 2.5
        case (.subtle, true): 1.5
        case (.primary, false): 1.0
        case (.secondary, false): 0.8
        case (.subtle, false): 0.5
        }
    }

    private static func pressedScaleDelta(for prominence: InteractionProminence, reduced: Bool) -> CGFloat {
        switch (prominence, reduced) {
        case (.primary, false): 0.008
        case (.secondary, false): 0.006
        case (.subtle, false): 0.004
        case (.primary, true): 0.004
        case (.secondary, true): 0.003
        case (.subtle, true): 0.002
        }
    }

    private static func pressedOffsetDelta(for prominence: InteractionProminence, reduced: Bool) -> CGFloat {
        switch (prominence, reduced) {
        case (.primary, false): 1.2
        case (.secondary, false): 0.8
        case (.subtle, false): 0.5
        case (.primary, true): 0.5
        case (.secondary, true): 0.4
        case (.subtle, true): 0.25
        }
    }

    private static func pressedGlowDelta(for prominence: InteractionProminence, reduced: Bool) -> Double {
        switch (prominence, reduced) {
        case (.primary, false): 0.03
        case (.secondary, false): 0.02
        case (.subtle, false): 0.01
        case (.primary, true): 0.015
        case (.secondary, true): 0.01
        case (.subtle, true): 0.005
        }
    }

    private static func pressedHighlightDelta(for prominence: InteractionProminence, reduced: Bool) -> Double {
        switch (prominence, reduced) {
        case (.primary, false): 0.12
        case (.secondary, false): 0.08
        case (.subtle, false): 0.05
        case (.primary, true): 0.06
        case (.secondary, true): 0.04
        case (.subtle, true): 0.025
        }
    }

    private static func pressedRotationDelta(for prominence: InteractionProminence, reduced: Bool) -> Double {
        switch (prominence, reduced) {
        case (.primary, false): 0.18
        case (.secondary, false): 0.08
        case (.subtle, false): 0.0
        case (.primary, true): 0.04
        case (.secondary, true): 0.02
        case (.subtle, true): 0.0
        }
    }

    private static func pressedSheenOpacityDelta(for prominence: InteractionProminence, reduced: Bool) -> Double {
        switch (prominence, reduced) {
        case (.primary, false): 0.28
        case (.secondary, false): 0.18
        case (.subtle, false): 0.10
        case (.primary, true): 0.10
        case (.secondary, true): 0.06
        case (.subtle, true): 0.03
        }
    }

    private static func pressedSheenOffset(for prominence: InteractionProminence, reduced: Bool) -> CGFloat {
        switch (prominence, reduced) {
        case (.primary, false): 18.0
        case (.secondary, false): 14.0
        case (.subtle, false): 10.0
        case (.primary, true): 8.0
        case (.secondary, true): 6.0
        case (.subtle, true): 4.0
        }
    }
}
