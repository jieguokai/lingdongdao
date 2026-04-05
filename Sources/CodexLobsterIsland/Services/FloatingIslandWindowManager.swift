import AppKit
import SwiftUI

@MainActor
final class FloatingIslandWindowManager {
    private struct WindowHandle {
        let panel: FloatingIslandPanel
        let hostingController: NSHostingController<AnyView>
    }

    private var windowsByScreenID: [Int: WindowHandle] = [:]
    private weak var statusService: CodexStatusService?
    private weak var settingsStore: SettingsStore?
    private(set) var isExpanded = false
    private(set) var isVisible = true
    private var autoCollapseTask: Task<Void, Never>?
    private var screenObserver: NSObjectProtocol?

    func install(statusService: CodexStatusService, settingsStore: SettingsStore) {
        self.statusService = statusService
        self.settingsStore = settingsStore
        ensureScreenObserver()
        syncWindowsToScreens()
        refresh()
    }

    func refresh() {
        guard let statusService, let settingsStore else { return }
        syncWindowsToScreens()

        for windowHandle in windowsByScreenID.values {
            windowHandle.hostingController.rootView = AnyView(
                FloatingIslandRootView(
                    statusService: statusService,
                    settingsStore: settingsStore,
                    isExpanded: isExpanded,
                    onToggleExpanded: { [weak self] in
                        self?.toggleExpanded()
                    }
                )
            )
        }

        updateFrame(animated: true)
        setVisible(settingsStore.settings.showsIsland)
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        for windowHandle in windowsByScreenID.values {
            if visible {
                windowHandle.panel.orderFrontRegardless()
            } else {
                windowHandle.panel.orderOut(nil)
            }
        }
    }

    func toggleExpanded() {
        isExpanded.toggle()
        refresh()
    }

    func handleDisplayStateChange(_ state: CodexState) {
        autoCollapseTask?.cancel()
        autoCollapseTask = nil

        guard state == .success else { return }

        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard
                    let self,
                    self.isExpanded,
                    self.statusService?.effectiveDisplayState == .success
                else {
                    return
                }
                self.isExpanded = false
                self.refresh()
            }
        }
    }

    private func ensureScreenObserver() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refresh()
            }
        }
    }

    private func makeWindowHandle() -> WindowHandle {
        let panel = FloatingIslandPanel(
            contentRect: NSRect(origin: .zero, size: AppConstants.compactIslandSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = false
        panel.animationBehavior = .utilityWindow

        let controller = NSHostingController(rootView: AnyView(EmptyView()))
        controller.view.wantsLayer = true
        controller.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = controller
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        return WindowHandle(panel: panel, hostingController: controller)
    }

    private func syncWindowsToScreens() {
        let screens = NSScreen.screens
        let liveScreenIDs = Set(screens.compactMap(screenID(for:)))
        let staleScreenIDs = windowsByScreenID.keys.filter { !liveScreenIDs.contains($0) }

        for screenID in staleScreenIDs {
            guard let windowHandle = windowsByScreenID[screenID] else { continue }
            windowHandle.panel.orderOut(nil)
            windowHandle.panel.close()
            windowsByScreenID.removeValue(forKey: screenID)
        }

        for screen in screens {
            guard let screenID = screenID(for: screen) else { continue }
            if windowsByScreenID[screenID] == nil {
                windowsByScreenID[screenID] = makeWindowHandle()
            }
        }
    }

    private func updateFrame(animated: Bool) {
        let targetSize = isExpanded ? AppConstants.expandedIslandSize : AppConstants.compactIslandSize

        for screen in NSScreen.screens {
            guard
                let screenID = screenID(for: screen),
                let windowHandle = windowsByScreenID[screenID]
            else {
                continue
            }

            let nextFrame = islandFrame(for: targetSize, on: screen)
            windowHandle.panel.setFrame(nextFrame, display: true, animate: animated)
        }
    }

    private func islandFrame(for size: CGSize, on screen: NSScreen) -> CGRect {
        let horizontalOrigin = screen.frame.midX - (size.width / 2)
        let verticalOrigin = screen.frame.maxY - AppConstants.islandTopMargin - size.height

        return CGRect(
            x: horizontalOrigin,
            y: verticalOrigin,
            width: size.width,
            height: size.height
        )
    }

    private func screenID(for screen: NSScreen) -> Int? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.intValue
    }

    deinit {
        autoCollapseTask?.cancel()
    }
}

private final class FloatingIslandPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
