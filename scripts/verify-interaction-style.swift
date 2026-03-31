import Foundation

@main
struct VerifyInteractionStyle {
    static func main() throws {
        let resting = InteractionStyle.surface(for: .resting, prominence: .primary, animationsEnabled: true)
        let hovered = InteractionStyle.surface(for: .hovered, prominence: .primary, animationsEnabled: true)
        let pressed = InteractionStyle.surface(for: .pressed, prominence: .primary, animationsEnabled: true)
        let reduced = InteractionStyle.surface(for: .hovered, prominence: .secondary, animationsEnabled: false)
        let subtleHovered = InteractionStyle.surface(for: .hovered, prominence: .subtle, animationsEnabled: true)
        let badgeHovered = InteractionStyle.badge(for: .hovered, animationsEnabled: true)
        let badgePressed = InteractionStyle.badge(for: .pressed, animationsEnabled: true)

        guard hovered.scale > resting.scale else {
            throw VerificationError("Expected hovered primary surface to scale above resting")
        }

        guard hovered.yOffset < resting.yOffset else {
            throw VerificationError("Expected hovered primary surface to lift upward")
        }

        guard hovered.glowOpacity > resting.glowOpacity else {
            throw VerificationError("Expected hovered primary surface to glow more than resting")
        }

        guard hovered.sheenOpacity > resting.sheenOpacity else {
            throw VerificationError("Expected hovered primary surface to reveal a stronger internal sheen")
        }

        guard hovered.rotationDegrees < 0 else {
            throw VerificationError("Expected hovered primary surface to lean slightly for a more alive feel")
        }

        guard subtleHovered.rotationDegrees == 0 else {
            throw VerificationError("Expected subtle hovered surfaces to avoid extra tilt")
        }

        guard pressed.scale < hovered.scale else {
            throw VerificationError("Expected pressed primary surface to compress relative to hovered")
        }

        guard pressed.highlightOpacity > hovered.highlightOpacity else {
            throw VerificationError("Expected pressed primary surface to brighten more than hovered")
        }

        guard pressed.sheenOpacity >= hovered.sheenOpacity else {
            throw VerificationError("Expected pressed primary surface to keep or intensify the sheen response")
        }

        guard pressed.rotationDegrees > hovered.rotationDegrees else {
            throw VerificationError("Expected pressed primary surface to rebound away from the hover lean")
        }

        guard badgeHovered.scale > 1.0 else {
            throw VerificationError("Expected hovered badge to grow for stronger island presence")
        }

        guard badgePressed.glowOpacity > badgeHovered.glowOpacity else {
            throw VerificationError("Expected pressed badge to flash brighter than hovered badge")
        }

        guard reduced.scale > 1.0 else {
            throw VerificationError("Expected reduced-motion hover to preserve subtle scale feedback")
        }

        guard reduced.highlightOpacity > 0.0 else {
            throw VerificationError("Expected reduced-motion hover to preserve highlight feedback")
        }

        guard reduced.yOffset > hovered.yOffset else {
            throw VerificationError("Expected reduced-motion hover to lift less than animated hover")
        }

        print("interaction style verification passed")
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
