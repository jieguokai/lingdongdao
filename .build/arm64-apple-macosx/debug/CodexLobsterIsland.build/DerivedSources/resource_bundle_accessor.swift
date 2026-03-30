import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("CodexLobsterIsland_CodexLobsterIsland.bundle").path
        let buildPath = "/Users/kevin/Documents/01_开发项目/lingdongdao/.build/arm64-apple-macosx/debug/CodexLobsterIsland_CodexLobsterIsland.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}