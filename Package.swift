// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CodexLobsterIsland",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexLobsterIsland", targets: ["CodexLobsterIsland"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.3")
    ],
    targets: [
        .executableTarget(
            name: "CodexLobsterIsland",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
