import Foundation

@main
struct VerifyPixelLobster {
    static func main() throws {
        let idleFrameZero = PixelLobsterSprite.pixels(for: .idle, tick: 0)
        let idleFrameOne = PixelLobsterSprite.pixels(for: .idle, tick: 1)
        let runningFrameZero = PixelLobsterSprite.pixels(for: .running, tick: 0)
        let successFrameZero = PixelLobsterSprite.pixels(for: .success, tick: 0)
        let errorFrameZero = PixelLobsterSprite.pixels(for: .error, tick: 0)

        guard idleFrameZero != idleFrameOne else {
            throw VerificationError("Expected idle animation to advance between local frames")
        }

        let idleBodyPixels = idleFrameZero.filter(\.isBodyPixel)
        let idleNextBodyPixels = idleFrameOne.filter(\.isBodyPixel)
        guard idleBodyPixels == idleNextBodyPixels else {
            throw VerificationError("Expected body pixels to remain stable across idle frames")
        }

        guard idleFrameZero != runningFrameZero else {
            throw VerificationError("Expected running frame to differ from idle frame")
        }

        guard successFrameZero != errorFrameZero else {
            throw VerificationError("Expected success and error local poses to differ")
        }

        let idleHeldFrame = PixelLobsterSprite.pixels(for: .idle, tick: 2)
        guard idleFrameOne == idleHeldFrame else {
            throw VerificationError("Expected idle animation to hold local frames for a calmer cadence")
        }

        let runningFrameOne = PixelLobsterSprite.pixels(for: .running, tick: 1)
        let runningFrameTwo = PixelLobsterSprite.pixels(for: .running, tick: 2)
        guard runningFrameZero != runningFrameOne, runningFrameOne != runningFrameTwo else {
            throw VerificationError("Expected running animation to cycle rapidly through distinct local poses")
        }

        let successFrameOne = PixelLobsterSprite.pixels(for: .success, tick: 1)
        let successFrameTwo = PixelLobsterSprite.pixels(for: .success, tick: 2)
        guard successFrameZero != successFrameOne, successFrameOne != successFrameTwo else {
            throw VerificationError("Expected success animation to include a visible celebration burst")
        }

        guard changedCoordinateCount(between: idleFrameZero, and: idleFrameOne) <= 6 else {
            throw VerificationError("Expected idle animation to move only a few pixels per step")
        }

        guard changedCoordinateCount(between: successFrameZero, and: successFrameOne) <= 10 else {
            throw VerificationError("Expected success animation to celebrate without teleporting large pixel groups")
        }

        try verifyVerticalOnlyMotion(for: .idle, ticks: 0...5)
        try verifyVerticalOnlyMotion(for: .running, ticks: 0...5)
        try verifyVerticalOnlyMotion(for: .success, ticks: 0...5)
        try verifyVerticalOnlyMotion(for: .error, ticks: 0...5)
        try verifyIdleClawsStayAnchored(ticks: 0...5)
        try verifyLayeredRhythms()

        print("pixel lobster verification passed")
    }

    private static func changedCoordinateCount(
        between lhs: [PixelLobsterSprite.Pixel],
        and rhs: [PixelLobsterSprite.Pixel]
    ) -> Int {
        let lhsCoordinates = Set(lhs.map { "\($0.x),\($0.y),\($0.role)" })
        let rhsCoordinates = Set(rhs.map { "\($0.x),\($0.y),\($0.role)" })
        return lhsCoordinates.symmetricDifference(rhsCoordinates).count
    }

    private static func verifyVerticalOnlyMotion(for state: CodexState, ticks: ClosedRange<Int>) throws {
        let frames = ticks.map { PixelLobsterSprite.pixels(for: state, tick: $0) }
        guard let firstFrame = frames.first else { return }
        let baseline = animatedXSignature(for: firstFrame)

        for frame in frames.dropFirst() {
            let signature = animatedXSignature(for: frame)
            guard signature == baseline else {
                throw VerificationError("Expected \(state.rawValue) animation to move animated pixels vertically only")
            }
        }
    }

    private static func animatedXSignature(for pixels: [PixelLobsterSprite.Pixel]) -> [String] {
        pixels
            .filter { $0.source == .animated }
            .map { "\($0.role)-\($0.x)" }
            .sorted()
    }

    private static func verifyIdleClawsStayAnchored(ticks: ClosedRange<Int>) throws {
        let frames = ticks.map { PixelLobsterSprite.pixels(for: .idle, tick: $0) }
        guard let firstFrame = frames.first else { return }
        let baseline = clawCoordinates(in: firstFrame)

        for frame in frames.dropFirst() {
            guard clawCoordinates(in: frame) == baseline else {
                throw VerificationError("Expected idle claws to stay anchored while only subtle parts breathe")
            }
        }
    }

    private static func clawCoordinates(in pixels: [PixelLobsterSprite.Pixel]) -> [String] {
        pixels
            .filter { $0.source == .animated && $0.role == .claw && $0.y >= 8 }
            .map { "\($0.x),\($0.y)" }
            .sorted()
    }

    private static func verifyLayeredRhythms() throws {
        let idle0 = PixelLobsterSprite.pixels(for: .idle, tick: 0)
        let idle1 = PixelLobsterSprite.pixels(for: .idle, tick: 1)
        let idle3 = PixelLobsterSprite.pixels(for: .idle, tick: 3)

        guard antennaMinY(in: idle1) < antennaMinY(in: idle0) else {
            throw VerificationError("Expected idle rhythm to start with antenna motion")
        }
        guard tailMinY(in: idle1) == tailMinY(in: idle0), tailMinY(in: idle3) > tailMinY(in: idle1) else {
            throw VerificationError("Expected idle tail motion to follow the antenna beat")
        }

        let running0 = PixelLobsterSprite.pixels(for: .running, tick: 0)
        let running1 = PixelLobsterSprite.pixels(for: .running, tick: 1)
        let running2 = PixelLobsterSprite.pixels(for: .running, tick: 2)

        guard leftClawMinY(in: running0) < leftClawMinY(in: running1) else {
            throw VerificationError("Expected running rhythm to lead with the left claw")
        }
        guard tailMinY(in: running1) > tailMinY(in: running0) else {
            throw VerificationError("Expected running tail motion to follow the first claw beat")
        }
        guard rightClawMinY(in: running2) < rightClawMinY(in: running1) else {
            throw VerificationError("Expected running rhythm to alternate to the right claw")
        }

        let success0 = PixelLobsterSprite.pixels(for: .success, tick: 0)
        let success1 = PixelLobsterSprite.pixels(for: .success, tick: 1)
        let success2 = PixelLobsterSprite.pixels(for: .success, tick: 2)
        let success3 = PixelLobsterSprite.pixels(for: .success, tick: 3)
        let success4 = PixelLobsterSprite.pixels(for: .success, tick: 4)

        guard eyesMinY(in: success1) < eyesMinY(in: success0) else {
            throw VerificationError("Expected success rhythm to begin with an eye lift")
        }
        guard leftClawMinY(in: success1) == leftClawMinY(in: success0),
              rightClawMinY(in: success1) == rightClawMinY(in: success0) else {
            throw VerificationError("Expected success claws to wait for the second beat")
        }
        guard leftClawMinY(in: success2) < leftClawMinY(in: success1),
              rightClawMinY(in: success2) < rightClawMinY(in: success1) else {
            throw VerificationError("Expected success rhythm to lift both claws after the eye cue")
        }
        guard leftClawMinY(in: success2) == rightClawMinY(in: success2),
              leftClawMinY(in: success3) == rightClawMinY(in: success3) else {
            throw VerificationError("Expected success claws to celebrate symmetrically")
        }
        guard leftClawMinY(in: success3) <= leftClawMinY(in: success2) else {
            throw VerificationError("Expected success to peak with a higher second claw lift")
        }
        guard tailMinY(in: success4) > tailMinY(in: success3) else {
            throw VerificationError("Expected success tail motion to rebound after the celebration peak")
        }

        let error0 = PixelLobsterSprite.pixels(for: .error, tick: 0)
        let error1 = PixelLobsterSprite.pixels(for: .error, tick: 1)
        let error2 = PixelLobsterSprite.pixels(for: .error, tick: 2)
        let error3 = PixelLobsterSprite.pixels(for: .error, tick: 3)
        let error4 = PixelLobsterSprite.pixels(for: .error, tick: 4)

        guard leftClawMinY(in: error0) > leftClawMinY(in: error1) else {
            throw VerificationError("Expected error rhythm to start with a left-claw drop")
        }
        guard rightClawMinY(in: error2) > rightClawMinY(in: error1) else {
            throw VerificationError("Expected error rhythm to answer with a right-claw drop")
        }
        guard leftClawMinY(in: error1) != rightClawMinY(in: error1),
              leftClawMinY(in: error2) != rightClawMinY(in: error2) else {
            throw VerificationError("Expected error claws to stay asymmetric during the alarm beat")
        }
        guard antennaCoordinates(in: error3) != antennaCoordinates(in: error2) else {
            throw VerificationError("Expected error antenna to react after the claw sequence")
        }
        guard tailMinY(in: error4) >= tailMinY(in: error3) else {
            throw VerificationError("Expected error tail to stay low or lower during the defensive settle")
        }
    }

    private static func leftClawMinY(in pixels: [PixelLobsterSprite.Pixel]) -> Int {
        componentMinY(in: pixels, xValues: [3, 4], role: .claw)
    }

    private static func rightClawMinY(in pixels: [PixelLobsterSprite.Pixel]) -> Int {
        componentMinY(in: pixels, xValues: [11, 12], role: .claw)
    }

    private static func antennaMinY(in pixels: [PixelLobsterSprite.Pixel]) -> Int {
        componentMinY(in: pixels, xValues: [5, 10], role: .claw)
    }

    private static func antennaCoordinates(in pixels: [PixelLobsterSprite.Pixel]) -> [String] {
        componentCoordinates(in: pixels, xValues: [5, 10], role: .claw)
    }

    private static func tailMinY(in pixels: [PixelLobsterSprite.Pixel]) -> Int {
        componentMinY(in: pixels, xValues: [7, 8], role: .shell)
    }

    private static func eyesMinY(in pixels: [PixelLobsterSprite.Pixel]) -> Int {
        componentMinY(in: pixels, xValues: [6, 9], role: .eye)
    }

    private static func componentMinY(
        in pixels: [PixelLobsterSprite.Pixel],
        xValues: [Int],
        role: PixelLobsterSprite.Pixel.Role
    ) -> Int {
        pixels
            .filter { $0.source == .animated && $0.role == role && xValues.contains($0.x) }
            .map(\.y)
            .min() ?? .max
    }

    private static func componentCoordinates(
        in pixels: [PixelLobsterSprite.Pixel],
        xValues: [Int],
        role: PixelLobsterSprite.Pixel.Role
    ) -> [String] {
        pixels
            .filter { $0.source == .animated && $0.role == role && xValues.contains($0.x) }
            .map { "\($0.x),\($0.y)" }
            .sorted()
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
