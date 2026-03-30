// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CodexLobsterIsland",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexLobsterIsland", targets: ["CodexLobsterIsland"]),
        .executable(name: "CodexLobsterIslandVerify", targets: ["CodexLobsterIslandVerify"])
    ],
    targets: [
        .executableTarget(
            name: "CodexLobsterIsland",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "CodexLobsterIslandVerify",
            dependencies: ["CodexLobsterIsland"]
        )
    ]
)
