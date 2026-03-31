import Foundation

#if canImport(Sparkle)
import Sparkle

@MainActor
final class SparkleAppUpdateDriver: NSObject, AppUpdateDriving {
    private let bundle: Bundle
    private let controller: SPUStandardUpdaterController?
    private var didStart = false
    private(set) var lastErrorMessage: String?

    init(bundle: Bundle = .main) {
        self.bundle = bundle

        let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        let hasFeedURL = !(feedURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasPublicKey = !(publicKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        if hasFeedURL, hasPublicKey {
            self.controller = SPUStandardUpdaterController(
                startingUpdater: false,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            self.controller = nil
        }

        super.init()

        if !hasFeedURL {
            lastErrorMessage = "缺少 SUFeedURL，应用更新未启用。"
        } else if !hasPublicKey {
            lastErrorMessage = "缺少 SUPublicEDKey，应用更新未启用。"
        }
    }

    var isAvailable: Bool {
        controller != nil
    }

    var canCheckForUpdates: Bool {
        controller?.updater.canCheckForUpdates ?? false
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { controller?.updater.automaticallyDownloadsUpdates ?? false }
        set { controller?.updater.automaticallyDownloadsUpdates = newValue }
    }

    var allowsAutomaticUpdates: Bool {
        controller?.updater.allowsAutomaticUpdates ?? false
    }

    var feedURLString: String? {
        controller?.updater.feedURL?.absoluteString
            ?? (bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String)
    }

    var publicEDKeyConfigured: Bool {
        let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        return !(publicKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var statusDescription: String {
        guard controller != nil else { return "未配置 Sparkle 更新源" }
        if let feedURLString {
            return "Sparkle 已启用：\(feedURLString)"
        }
        return "Sparkle 已启用"
    }

    func start() {
        guard let controller, !didStart else { return }
        didStart = true
        controller.startUpdater()
        _ = controller.updater.clearFeedURLFromUserDefaults()
        lastErrorMessage = nil
    }

    func checkForUpdates() {
        guard let controller else { return }
        controller.checkForUpdates(nil)
    }
}

#else

@MainActor
final class SparkleAppUpdateDriver: AppUpdateDriving {
    var isAvailable: Bool { false }
    var canCheckForUpdates: Bool { false }
    var automaticallyChecksForUpdates: Bool = false
    var automaticallyDownloadsUpdates: Bool = false
    var allowsAutomaticUpdates: Bool { false }
    var feedURLString: String? { nil }
    var publicEDKeyConfigured: Bool { false }
    var statusDescription: String { "Sparkle 不可用" }
    var lastErrorMessage: String? { "当前构建未链接 Sparkle。" }

    func start() {}
    func checkForUpdates() {}
}

#endif
