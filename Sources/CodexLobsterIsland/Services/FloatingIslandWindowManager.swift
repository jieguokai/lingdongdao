import AppKit
import SwiftUI

@MainActor
final class FloatingIslandWindowManager {
    private var panel: FloatingIslandPanel?
    private var hostingController: NSHostingController<AnyView>?
    private weak var statusService: CodexStatusService?
    private weak var settingsStore: SettingsStore?
    private(set) var isExpanded = false
    private(set) var isVisible = true

    func install(statusService: CodexStatusService, settingsStore: SettingsStore) {
        self.statusService = statusService
        self.settingsStore = settingsStore
        ensurePanel()
        refresh()
    }

    func refresh() {
        guard let statusService, let settingsStore else { return }
        ensurePanel()
        hostingController?.rootView = AnyView(
            FloatingIslandRootView(
                statusService: statusService,
                settingsStore: settingsStore,
                isExpanded: isExpanded,
                onToggleExpanded: { [weak self] in
                    self?.toggleExpanded()
                }
            )
        )
        updateFrame(animated: true)
        setVisible(settingsStore.settings.showsIsland)
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        guard let panel else { return }
        if visible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    func toggleExpanded() {
        isExpanded.toggle()
        refresh()
    }

    private func ensurePanel() {
        guard panel == nil else { return }
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
        self.panel = panel
        self.hostingController = controller
    }

    private func updateFrame(animated: Bool) {
        guard let panel else { return }
        let targetSize = isExpanded ? AppConstants.expandedIslandSize : AppConstants.compactIslandSize
        let screen = activeScreen()
        let origin = CGPoint(
            x: screen.frame.midX - (targetSize.width / 2),
            y: screen.frame.maxY - AppConstants.islandTopMargin - targetSize.height
        )
        let nextFrame = CGRect(origin: origin, size: targetSize)
        panel.setFrame(nextFrame, display: true, animate: animated)
    }

    private func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
    }
}

private final class FloatingIslandPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
