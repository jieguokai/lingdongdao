import Foundation
import Observation

@MainActor
protocol AppUpdateDriving: AnyObject {
    var isAvailable: Bool { get }
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }
    var allowsAutomaticUpdates: Bool { get }
    var feedURLString: String? { get }
    var publicEDKeyConfigured: Bool { get }
    var statusDescription: String { get }
    var lastErrorMessage: String? { get }

    func start()
    func checkForUpdates()
}

@MainActor
@Observable
final class AppUpdateService {
    private let driver: AppUpdateDriving

    private(set) var isAvailable = false
    private(set) var canCheckForUpdates = false
    private(set) var allowsAutomaticUpdates = false
    private(set) var feedURLString: String?
    private(set) var publicEDKeyConfigured = false
    private(set) var statusDescription = "未配置应用更新"
    private(set) var lastErrorMessage: String?

    var automaticallyChecksForUpdates = false {
        didSet {
            guard automaticallyChecksForUpdates != oldValue else { return }
            driver.automaticallyChecksForUpdates = automaticallyChecksForUpdates
            refresh()
        }
    }

    var automaticallyDownloadsUpdates = false {
        didSet {
            guard automaticallyDownloadsUpdates != oldValue else { return }
            driver.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates
            refresh()
        }
    }

    init(driver: AppUpdateDriving = SparkleAppUpdateDriver()) {
        self.driver = driver
        refresh()
    }

    func start() {
        driver.start()
        refresh()
    }

    func checkForUpdates() {
        driver.checkForUpdates()
        refresh()
    }

    func refresh() {
        isAvailable = driver.isAvailable
        canCheckForUpdates = driver.canCheckForUpdates
        allowsAutomaticUpdates = driver.allowsAutomaticUpdates
        automaticallyChecksForUpdates = driver.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = driver.automaticallyDownloadsUpdates
        feedURLString = driver.feedURLString
        publicEDKeyConfigured = driver.publicEDKeyConfigured
        statusDescription = driver.statusDescription
        lastErrorMessage = driver.lastErrorMessage
    }
}

