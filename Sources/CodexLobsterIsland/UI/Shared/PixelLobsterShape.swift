import SwiftUI

enum PixelLobsterShape {
    struct Pixel: Identifiable {
        enum Role {
            case shell
            case claw
            case belly
            case eye
        }

        let id = UUID()
        let x: Int
        let y: Int
        let role: Role
    }

    static let pixels: [Pixel] = [
        .init(x: 5, y: 1, role: .claw), .init(x: 10, y: 1, role: .claw),
        .init(x: 4, y: 2, role: .claw), .init(x: 11, y: 2, role: .claw),
        .init(x: 3, y: 3, role: .claw), .init(x: 12, y: 3, role: .claw),
        .init(x: 5, y: 3, role: .shell), .init(x: 6, y: 3, role: .shell), .init(x: 7, y: 3, role: .shell), .init(x: 8, y: 3, role: .shell), .init(x: 9, y: 3, role: .shell), .init(x: 10, y: 3, role: .shell),
        .init(x: 4, y: 4, role: .shell), .init(x: 5, y: 4, role: .shell), .init(x: 6, y: 4, role: .eye), .init(x: 7, y: 4, role: .shell), .init(x: 8, y: 4, role: .shell), .init(x: 9, y: 4, role: .eye), .init(x: 10, y: 4, role: .shell), .init(x: 11, y: 4, role: .shell),
        .init(x: 4, y: 5, role: .shell), .init(x: 5, y: 5, role: .shell), .init(x: 6, y: 5, role: .shell), .init(x: 7, y: 5, role: .shell), .init(x: 8, y: 5, role: .shell), .init(x: 9, y: 5, role: .shell), .init(x: 10, y: 5, role: .shell), .init(x: 11, y: 5, role: .shell),
        .init(x: 5, y: 6, role: .belly), .init(x: 6, y: 6, role: .belly), .init(x: 7, y: 6, role: .belly), .init(x: 8, y: 6, role: .belly), .init(x: 9, y: 6, role: .belly), .init(x: 10, y: 6, role: .belly),
        .init(x: 5, y: 7, role: .belly), .init(x: 6, y: 7, role: .belly), .init(x: 9, y: 7, role: .belly), .init(x: 10, y: 7, role: .belly),
        .init(x: 4, y: 8, role: .claw), .init(x: 6, y: 8, role: .shell), .init(x: 9, y: 8, role: .shell), .init(x: 11, y: 8, role: .claw),
        .init(x: 3, y: 9, role: .claw), .init(x: 5, y: 9, role: .shell), .init(x: 10, y: 9, role: .shell), .init(x: 12, y: 9, role: .claw),
        .init(x: 5, y: 10, role: .claw), .init(x: 10, y: 10, role: .claw)
    ]
}
