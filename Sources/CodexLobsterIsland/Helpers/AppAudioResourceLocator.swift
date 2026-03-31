import Foundation

enum AppAudioResourceLocator {
    static func url(forResource name: String) -> URL? {
        if let packagedResourceURL = Bundle.main.resourceURL?
            .appendingPathComponent("Audio", isDirectory: true)
            .appendingPathComponent("\(name).wav"),
           FileManager.default.fileExists(atPath: packagedResourceURL.path) {
            return packagedResourceURL
        }

        return Bundle.module.url(forResource: name, withExtension: "wav", subdirectory: "Audio")
    }
}
