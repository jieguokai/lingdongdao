enum PixelLobsterSprite {
    private struct AnimationTrack {
        let frames: [[Pixel]]
        let sequence: [Int]
    }

    struct Bounds: Hashable {
        let minX: Int
        let maxX: Int
        let minY: Int
        let maxY: Int

        var width: Int { maxX - minX + 1 }
        var height: Int { maxY - minY + 1 }
    }

    struct Pixel: Identifiable, Hashable {
        enum Role: Hashable {
            case shell
            case claw
            case belly
            case eye
        }

        enum Source: Hashable {
            case body
            case animated
        }

        let x: Int
        let y: Int
        let role: Role
        let source: Source

        var id: String { "\(x),\(y)" }
        var isBodyPixel: Bool { source == .body }
    }

    static let gridSize = 16
    static let renderBounds = makeRenderBounds()

    static func pixels(for state: CodexState, tick: Int) -> [Pixel] {
        let track = tracksByState[state] ?? idleTrack
        let frameIndex = track.sequence[normalizedIndex(for: tick, count: track.sequence.count)]
        let frame = track.frames[normalizedIndex(for: frameIndex, count: track.frames.count)]
        return (bodyPixels + frame).sorted(by: pixelSort)
    }

    static func tickRate(for state: CodexState) -> Double {
        switch state {
        case .idle:
            2.6
        case .running:
            5.8
        case .success:
            4.6
        case .error:
            6.8
        }
    }

    private static let bodyPixels: [Pixel] = [
        pixel(5, 3, .shell, .body), pixel(6, 3, .shell, .body), pixel(7, 3, .shell, .body), pixel(8, 3, .shell, .body), pixel(9, 3, .shell, .body), pixel(10, 3, .shell, .body),
        pixel(4, 4, .shell, .body), pixel(5, 4, .shell, .body), pixel(7, 4, .shell, .body), pixel(8, 4, .shell, .body), pixel(10, 4, .shell, .body), pixel(11, 4, .shell, .body),
        pixel(4, 5, .shell, .body), pixel(5, 5, .shell, .body), pixel(6, 5, .shell, .body), pixel(7, 5, .shell, .body), pixel(8, 5, .shell, .body), pixel(9, 5, .shell, .body), pixel(10, 5, .shell, .body), pixel(11, 5, .shell, .body),
        pixel(5, 6, .belly, .body), pixel(6, 6, .belly, .body), pixel(7, 6, .belly, .body), pixel(8, 6, .belly, .body), pixel(9, 6, .belly, .body), pixel(10, 6, .belly, .body),
        pixel(5, 7, .belly, .body), pixel(6, 7, .belly, .body), pixel(9, 7, .belly, .body), pixel(10, 7, .belly, .body),
        pixel(6, 8, .shell, .body), pixel(9, 8, .shell, .body),
        pixel(5, 9, .shell, .body), pixel(10, 9, .shell, .body)
    ]

    private static let idleFrames: [[Pixel]] = [
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 7), (3, 8), (4, 9)],
            rightClaw: [(11, 7), (12, 8), (11, 9)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        )
    ]

    private static let idleTrack = AnimationTrack(
        frames: idleFrames,
        sequence: [0, 1, 1, 2, 2, 1, 1, 0, 0, 3, 3, 0]
    )

    private static let runningFrames: [[Pixel]] = [
        dynamicFrame(
            leftClaw: [(4, 7), (3, 8), (4, 9)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 7), (12, 8), (11, 9)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        )
    ]

    private static let runningTrack = AnimationTrack(
        frames: runningFrames,
        sequence: [0, 1, 2, 3, 4, 3, 2, 1]
    )

    private static let successFrames: [[Pixel]] = [
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 3), (9, 3)]
        ),
        dynamicFrame(
            leftClaw: [(4, 7), (3, 8), (4, 9)],
            rightClaw: [(11, 7), (12, 8), (11, 9)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 3), (9, 3)]
        ),
        dynamicFrame(
            leftClaw: [(4, 6), (3, 7), (4, 8)],
            rightClaw: [(11, 6), (12, 7), (11, 8)],
            antenna: [(5, 1), (10, 1)],
            tail: [(7, 8), (8, 8)],
            eyes: [(6, 3), (9, 3)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        )
    ]

    private static let successTrack = AnimationTrack(
        frames: successFrames,
        sequence: [0, 1, 2, 3, 4, 3, 2, 1, 0, 0]
    )

    private static let errorFrames: [[Pixel]] = [
        dynamicFrame(
            leftClaw: [(4, 9), (3, 10), (4, 11)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 3), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 7), (12, 8), (11, 9)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 9), (12, 10), (11, 11)],
            antenna: [(5, 2), (10, 3)],
            tail: [(7, 8), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 2), (10, 2)],
            tail: [(7, 8), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        ),
        dynamicFrame(
            leftClaw: [(4, 8), (3, 9), (4, 10)],
            rightClaw: [(11, 8), (12, 9), (11, 10)],
            antenna: [(5, 3), (10, 2)],
            tail: [(7, 9), (8, 9)],
            eyes: [(6, 4), (9, 4)]
        )
    ]

    private static let errorTrack = AnimationTrack(
        frames: errorFrames,
        sequence: [0, 1, 2, 3, 4, 3, 2, 1]
    )

    private static let tracksByState: [CodexState: AnimationTrack] = [
        .idle: idleTrack,
        .running: runningTrack,
        .success: successTrack,
        .error: errorTrack
    ]

    private static func dynamicFrame(
        leftClaw: [(Int, Int)],
        rightClaw: [(Int, Int)],
        antenna: [(Int, Int)],
        tail: [(Int, Int)],
        eyes: [(Int, Int)]
    ) -> [Pixel] {
        leftClaw.map { pixel($0.0, $0.1, .claw, .animated) }
        + rightClaw.map { pixel($0.0, $0.1, .claw, .animated) }
        + antenna.map { pixel($0.0, $0.1, .claw, .animated) }
        + tail.map { pixel($0.0, $0.1, .shell, .animated) }
        + eyes.map { pixel($0.0, $0.1, .eye, .animated) }
    }

    private static func pixel(_ x: Int, _ y: Int, _ role: Pixel.Role, _ source: Pixel.Source) -> Pixel {
        Pixel(x: x, y: y, role: role, source: source)
    }

    private static func normalizedIndex(for tick: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = tick % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private static func pixelSort(lhs: Pixel, rhs: Pixel) -> Bool {
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        if lhs.x != rhs.x { return lhs.x < rhs.x }
        return lhs.isBodyPixel && !rhs.isBodyPixel
    }

    private static func makeRenderBounds() -> Bounds {
        let allPixels = bodyPixels
            + idleFrames.flatMap { $0 }
            + runningFrames.flatMap { $0 }
            + successFrames.flatMap { $0 }
            + errorFrames.flatMap { $0 }

        let xs = allPixels.map(\.x)
        let ys = allPixels.map(\.y)

        return Bounds(
            minX: xs.min() ?? 0,
            maxX: xs.max() ?? 0,
            minY: ys.min() ?? 0,
            maxY: ys.max() ?? 0
        )
    }
}
