@preconcurrency import ApplicationServices
import Foundation

@MainActor
final class CodexDesktopPermissionManager {
    enum RequestMode {
        case silentCheck
        case autoPromptAllNeeded
        case manualPromptFull
    }

    private(set) var state = CodexDesktopPermissionState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        inputMonitoringGranted: false,
        phase: .unauthorized
    )

    @discardableResult
    func refresh(mode: RequestMode) -> CodexDesktopPermissionState {
        let shouldPromptAccessibility = mode != .silentCheck
        let shouldPromptOptionalPermissions = mode == .autoPromptAllNeeded || mode == .manualPromptFull

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: shouldPromptAccessibility] as CFDictionary
        let accessibilityGranted = AXIsProcessTrustedWithOptions(options)

        let screenRecordingGranted: Bool
        if #available(macOS 11.0, *) {
            screenRecordingGranted = CGPreflightScreenCaptureAccess()
            if shouldPromptOptionalPermissions && !screenRecordingGranted {
                _ = CGRequestScreenCaptureAccess()
            }
        } else {
            screenRecordingGranted = true
        }

        let inputMonitoringGranted: Bool
        if #available(macOS 10.15, *) {
            inputMonitoringGranted = CGPreflightListenEventAccess()
            if shouldPromptOptionalPermissions && !inputMonitoringGranted {
                _ = CGRequestListenEventAccess()
            }
        } else {
            inputMonitoringGranted = true
        }

        state = CodexDesktopPermissionState(
            accessibilityGranted: accessibilityGranted,
            screenRecordingGranted: screenRecordingGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            phase: accessibilityGranted ? .readyInactive : .unauthorized
        )
        return state
    }
}
