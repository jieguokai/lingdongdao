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
            case outline
            case shellHighlight
            case shell
            case shellShadow
            case belly
            case bellyShadow
            case eyeWhite
            case eyePupil
        }

        let x: Int
        let y: Int
        let role: Role

        var id: String { "\(x),\(y),\(role)" }
    }

    private static let frameSize = 11
    private static let markerSize = 5
    private static let markerGap = 3
    // 让符号整体更靠近龙虾本体，但不改龙虾的像素坐标。
    private static let markerOffsetX = 2
    private static let markerMinX = -(markerSize + markerGap)
    private static let markerMinY = 3
    static let gridSize = frameSize
    static let markerOriginX = markerMinX + markerOffsetX
    static let markerOriginY = markerMinY
    static let markerGridSize = markerSize
    static let renderBounds = Bounds(minX: markerMinX, maxX: frameSize - 1, minY: 0, maxY: frameSize - 1)

    static func pixels(for state: CodexState, tick: Int) -> [Pixel] {
        let track = tracksByState[state] ?? idleTrack
        let frameIndex = track.sequence[normalizedIndex(for: tick, count: track.sequence.count)]
        let sprite = track.frames[normalizedIndex(for: frameIndex, count: track.frames.count)]
        return markerPixels(for: state) + sprite
    }

    static func tickRate(for state: CodexState) -> Double {
        switch state {
        case .idle:
            1.2
        case .typing:
            3.8
        case .running:
            5.0
        case .awaitingReply:
            2.0
        case .awaitingApproval:
            1.8
        case .success:
            4.2
        case .error:
            3.3
        }
    }

    private static let idleTrack = AnimationTrack(
        frames: [
            frame([
                "...X...X...",
                "..XHXXXHX..",
                ".XHHSSSHHX.",
                "XHSSSSSSSHX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X.SBBBBBS.X",
                ".XSTTTTTSX.",
                "..XDDDDDX..",
                "...XDDDXX..",
                "....XXX...."
            ]),
            frame([
                "....X.X....",
                "...HXXXH...",
                "..XHSSSHX..",
                ".XSSSSSSSX.",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                ".XSBBBBBSX.",
                "..XTTTTTX..",
                "...XDDDX...",
                "...XXDXX...",
                "....XXX...."
            ])
        ],
        sequence: [0, 0, 1, 0]
    )

    private static let typingTrack = AnimationTrack(
        frames: [
            frame([
                "X..X...X..X",
                ".XHXXXXXHX.",
                "XHHSSSSSHHX",
                "XHSSSSSSSHX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X.SBBBBBS.X",
                "..XTTTTTX..",
                "...XDDDX...",
                "...XXDXX...",
                "....XXX...."
            ]),
            frame([
                "XX.......XX",
                ".XHXXXXXHX.",
                "XHHSSSSSHHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X.SBBBBBS.X",
                "..XTTTTTX..",
                "..XXDDDXX..",
                "...XDDD....",
                "....XXX...."
            ]),
            frame([
                ".XX..X..XX.",
                "XHXXXXXXXHX",
                ".XHSSSSSHX.",
                "XHSSSSSSSHX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                ".XSBBBBBSX.",
                "...XTTTX...",
                "..XXDDDXX..",
                "...XDDD....",
                "....XXX...."
            ])
        ],
        sequence: [0, 1, 2, 1]
    )

    private static let runningTrack = AnimationTrack(
        frames: [
            frame([
                "X...X.X...X",
                ".XHXXXXXHX.",
                "XHHSSSSSHHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                "XSSSBBBSSSX",
                ".XSBBBBBSX.",
                "..XTTTTTX..",
                ".XXDDDDDXX.",
                "..XDDXDDX..",
                "...XX.XX..."
            ]),
            frame([
                ".X.......X.",
                "XHHX...XHHX",
                "XHSSSSSSSHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X.SBBBBBS.X",
                "..XTTTTTX..",
                ".XXDDDDDXX.",
                "...XDDDXX..",
                "...X.X.X..."
            ]),
            frame([
                "X...X.X...X",
                ".HHX...XHH.",
                "XHSSSSSSSHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                ".XSBBBBBSX.",
                "..XTTTTTX..",
                "..XXDDDXX..",
                ".XXD...DXX.",
                "...XX.XX..."
            ])
        ],
        sequence: [0, 1, 2, 1]
    )

    private static let awaitingReplyTrack = AnimationTrack(
        frames: [
            frame([
                "...X...X...",
                "..XHXXXH...",
                ".XHHSSSHX..",
                "XHSSSSSSSX.",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                ".XSBBBBBSX.",
                "..XTTTTTX..",
                "...XDDDX...",
                "...XXDXX...",
                "....XXX...."
            ]),
            frame([
                "....X...X..",
                "...HXXXHX..",
                "..XHSSSHHX.",
                ".XSSSSSSSX.",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "..XSBBBBSX.",
                "...XTTTTX..",
                "...XDDDX...",
                "...XXDXX...",
                "....XXX...."
            ]),
            frame([
                "..X...X....",
                "..XHXXXH...",
                ".XHHSSSHX..",
                "XHSSSSSSSX.",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                ".XSBBBBBSX.",
                "...XTTTTX..",
                "...XDDDX...",
                "..XXDXX....",
                "....XXX...."
            ])
        ],
        sequence: [0, 1, 0, 2, 0]
    )

    private static let awaitingApprovalTrack = AnimationTrack(
        frames: [
            frame([
                "..XX...XX..",
                ".XHXXXXXHX.",
                "XHHSSSSSHHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "..XBBBBBX..",
                "..XTTTTTX..",
                "...XDDDX...",
                "...XDDDX...",
                "....XXX...."
            ]),
            frame([
                ".XHX...XHX.",
                "XHXXXXXXXHX",
                ".XHSSSSSHX.",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "..XBBBBBX..",
                "..XTTTTTX..",
                "...XDDDX...",
                "...XDDDX...",
                "....XXX...."
            ])
        ],
        sequence: [0, 1, 0, 1]
    )

    private static let successTrack = AnimationTrack(
        frames: [
            frame([
                "XX..X.X..XX",
                ".XHXXXXXHX.",
                "XHHSSSSSHHX",
                "XHSSSSSSSHX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X.SBBBBBS.X",
                "..XTTTTTX..",
                "..XXDDDXX..",
                ".XX.XDX.XX.",
                "....XXX...."
            ]),
            frame([
                "XHX.....XHX",
                ".HHX...XHH.",
                "XHHSSSSSHHX",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "..XBBBBBX..",
                "...TTTTT...",
                "..XXDDDXX..",
                "...XXDXX...",
                "....XXX...."
            ]),
            frame([
                ".XX.X.X.XX.",
                "XHXXXXXXXHX",
                ".XHSSSSSHX.",
                "XHSSSSSSSHX",
                "XSSEP.PESSX",
                "XSSSBBBSSSX",
                ".XSBBBBBSX.",
                "..XTTTTTX..",
                ".XXDDDDDXX.",
                "..XDDXDDX..",
                "...XX.XX..."
            ])
        ],
        sequence: [0, 1, 2, 1]
    )

    private static let errorTrack = AnimationTrack(
        frames: [
            frame([
                "....X.X....",
                "...HXXXH...",
                "..XHSSSHX..",
                ".XSSSSSSSX.",
                "XSSEP.PESSX",
                "X.SSBBBSS.X",
                "..XBBBBBX..",
                "..XTTTTTX..",
                ".XXDDDDD...",
                "...XDDDX...",
                "...XXXXX..."
            ]),
            frame([
                "...X...X...",
                "..H.....H..",
                ".XHSSSSSHX.",
                "XSSSSSSSSSX",
                "XSSEP.PESSX",
                "X.SSBBBSS.X",
                "..XBBBBBX..",
                "...TTTTT...",
                "..XXDDDXX..",
                "...XDDDX...",
                "...XXXXX..."
            ]),
            frame([
                "....X.X....",
                ".H.......H.",
                "..XHSSSHX..",
                ".XSSSSSSSX.",
                "XSSEP.PESSX",
                ".XSSBBBSSX.",
                "X..BBBBB..X",
                "..XTTTTTX..",
                "...XDDDX...",
                "..XXDDDXX..",
                "...XXXXX..."
            ])
        ],
        sequence: [0, 1, 2, 1]
    )

    private static let tracksByState: [CodexState: AnimationTrack] = [
        .idle: idleTrack,
        .typing: typingTrack,
        .running: runningTrack,
        .awaitingReply: awaitingReplyTrack,
        .awaitingApproval: awaitingApprovalTrack,
        .success: successTrack,
        .error: errorTrack
    ]

    private static func frame(_ rows: [String]) -> [Pixel] {
        precondition(rows.count == frameSize, "PixelLobsterSprite frame must contain \(frameSize) rows.")
        return rows.enumerated().flatMap { y, row in
            precondition(row.count == frameSize, "PixelLobsterSprite row must contain \(frameSize) columns.")
            return Array(row).enumerated().compactMap { element -> Pixel? in
                let x = element.offset
                let character = element.element
                guard let role = role(for: character) else { return nil }
                return Pixel(x: x, y: y, role: role)
            }
        }
    }

    private static func role(for character: Character) -> Pixel.Role? {
        switch character {
        case "X":
            return .outline
        case "H":
            return .shellHighlight
        case "S":
            return .shell
        case "D":
            return .shellShadow
        case "B":
            return .belly
        case "T":
            return .bellyShadow
        case "E":
            return .eyeWhite
        case "P":
            return .eyePupil
        default:
            return nil
        }
    }

    private static func normalizedIndex(for tick: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = tick % count
        return remainder >= 0 ? remainder : remainder + count
    }

    private static func markerPixels(for state: CodexState) -> [Pixel] {
        let rows: [String] = switch state {
        case .idle:
            [
                "SSS..",
                "...S.",
                "..S..",
                ".....",
                "....."
            ]
        case .typing:
            [
                ".....",
                ".....",
                ".S.S.",
                ".....",
                "....."
            ]
        case .running:
            [
                "..SS.",
                ".S...",
                "..S..",
                "...S.",
                ".SS.."
            ]
        case .awaitingReply:
            [
                "..S..",
                "...S.",
                "..S..",
                ".....",
                "..S.."
            ]
        case .awaitingApproval:
            [
                "..S..",
                "..S..",
                "..S..",
                ".....",
                "..S.."
            ]
        case .success:
            [
                "..S..",
                ".S.S.",
                "..S..",
                ".S.S.",
                "..S.."
            ]
        case .error:
            [
                "S...S",
                "..S..",
                "..S..",
                "..S..",
                "S...S"
            ]
        }

        return rows.enumerated().flatMap { rowIndex, row in
            Array(row).enumerated().compactMap { element -> Pixel? in
                guard let role = role(for: element.element) else { return nil }
                return Pixel(
                    x: markerMinX + markerOffsetX + element.offset,
                    y: markerMinY + rowIndex,
                    role: role
                )
            }
        }
    }
}
