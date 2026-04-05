import AppKit
import ApplicationServices
import Foundation

struct CodexDesktopWindowSnapshot: Equatable {
    struct ActionCandidate: Equatable {
        let label: String
        let role: CodexApprovalAction.Role
    }

    let windowAvailable: Bool
    let threadTitle: String?
    let promptText: String
    let promptFocused: Bool
    let focusedElementRole: String?
    let focusedElementValue: String?
    let threadContextLines: [String]
    let threadFingerprint: String?
    let actionCandidates: [ActionCandidate]
    let frame: CGRect?
}

@MainActor
final class CodexDesktopActionBridge {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    var isCodexRunning: Bool {
        activeCodexApplication() != nil
    }

    func snapshot() -> CodexDesktopWindowSnapshot? {
        guard let application = activeCodexApplication() else { return nil }
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let window = axElement(appElement, kAXFocusedWindowAttribute as String) ?? axElement(appElement, kAXMainWindowAttribute as String) else {
            return nil
        }

        let promptElement = axElement(appElement, kAXFocusedUIElementAttribute as String)
        let focusedElementRole = promptElement.flatMap { optionalStringAttribute($0, kAXRoleAttribute as String) }
        let focusedElementValue = promptElement.flatMap { optionalStringAttribute($0, kAXValueAttribute as String) }
        let promptText = focusedElementValue ?? ""
        let promptFocused = focusedElementRole == "AXTextArea"

        let frame = resolveFrame(for: window)
        let threadTitle = resolveThreadTitle(in: window)
        let threadContextLines = resolveThreadContextLines(in: window, windowFrame: frame)
        let threadFingerprint = resolveThreadFingerprint(
            threadTitle: threadTitle,
            threadContextLines: threadContextLines,
            frame: frame
        )
        let actionCandidates = resolveActionCandidates(in: window)

        return CodexDesktopWindowSnapshot(
            windowAvailable: true,
            threadTitle: threadTitle,
            promptText: promptText,
            promptFocused: promptFocused,
            focusedElementRole: focusedElementRole,
            focusedElementValue: focusedElementValue,
            threadContextLines: threadContextLines,
            threadFingerprint: threadFingerprint,
            actionCandidates: actionCandidates,
            frame: frame
        )
    }

    func perform(action: CodexApprovalAction) -> Bool {
        guard let application = activeCodexApplication() else { return false }
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let window = axElement(appElement, kAXFocusedWindowAttribute as String) ?? axElement(appElement, kAXMainWindowAttribute as String) else {
            return false
        }

        return pressMatchingAction(in: window, action: action)
    }

    private func activeCodexApplication() -> NSRunningApplication? {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex")
        if let frontmost = running.first(where: { $0.bundleIdentifier == workspace.frontmostApplication?.bundleIdentifier }) {
            return frontmost
        }
        return running.first(where: { !$0.isTerminated })
    }

    private func resolveThreadTitle(in window: AXUIElement) -> String? {
        let blacklist = Set(["新线程", "技能和应用", "自动化", "设置", "提交", "打开"])
        for button in recursiveElements(in: window) where stringAttribute(button, kAXRoleAttribute as String) == "AXButton" {
            let title = normalizedLabel(titleOrDescription(for: button))
            guard let title, !title.isEmpty, !blacklist.contains(title), title.count <= 64 else { continue }
            return title
        }
        return nil
    }

    private func resolveThreadContextLines(in window: AXUIElement, windowFrame: CGRect?) -> [String] {
        recursiveElements(in: window)
            .compactMap { element -> (CGFloat, String)? in
                let role = stringAttribute(element, kAXRoleAttribute as String)
                guard role == "AXStaticText" || role == "AXTextField" else { return nil }
                let value = normalizedLabel(optionalStringAttribute(element, kAXValueAttribute as String) ?? titleOrDescription(for: element))
                guard let value, shouldKeepThreadContextLine(value, element: element, windowFrame: windowFrame) else { return nil }
                let verticalPosition = resolveFrame(for: element)?.midY ?? .zero
                return (verticalPosition, value)
            }
            .sorted { $0.0 > $1.0 }
            .map(\.1)
            .reduce(into: [String]()) { result, line in
                guard result.contains(line) == false else { return }
                result.append(line)
            }
            .prefix(3)
            .map { $0 }
    }

    private func shouldKeepThreadContextLine(_ line: String, element: AXUIElement, windowFrame: CGRect?) -> Bool {
        let blacklist = [
            "Codex", "技能和应用", "自动化", "设置", "提交", "打开", "返回", "前进", "终端", "Open in Popout Window"
        ]
        guard line.count >= 2, line.count <= 80 else { return false }
        guard blacklist.contains(where: { line == $0 }) == false else { return false }
        if let windowFrame, let elementFrame = resolveFrame(for: element) {
            let topThreshold = windowFrame.minY + (windowFrame.height * 0.58)
            guard elementFrame.midY >= topThreshold else { return false }
        }
        return true
    }

    private func resolveThreadFingerprint(
        threadTitle: String?,
        threadContextLines: [String],
        frame: CGRect?
    ) -> String? {
        let frameSeed = frame.map { "\(Int($0.width.rounded()))x\(Int($0.height.rounded()))" }
        let seed = ([threadTitle] + Array(threadContextLines.prefix(2)) + [frameSeed])
            .compactMap(normalizedLabel)
            .joined(separator: " | ")
        return seed.isEmpty ? nil : seed
    }

    private func resolveActionCandidates(in window: AXUIElement) -> [CodexDesktopWindowSnapshot.ActionCandidate] {
        recursiveElements(in: window)
            .filter { stringAttribute($0, kAXRoleAttribute as String) == "AXButton" }
            .compactMap { button in
                guard let label = normalizedLabel(titleOrDescription(for: button)) else { return nil }
                guard let role = actionRole(for: label) else { return nil }
                return CodexDesktopWindowSnapshot.ActionCandidate(label: label, role: role)
            }
    }

    private func pressMatchingAction(in window: AXUIElement, action: CodexApprovalAction) -> Bool {
        let normalizedTargets = [action.label, action.actionPayload]
            .map(normalizedLabel)
            .compactMap { $0 }

        for button in recursiveElements(in: window) where stringAttribute(button, kAXRoleAttribute as String) == "AXButton" {
            guard let label = normalizedLabel(titleOrDescription(for: button)) else { continue }
            let role = actionRole(for: label)
            if normalizedTargets.contains(label) || role == action.role {
                if AXUIElementPerformAction(button, kAXPressAction as CFString) == .success {
                    return true
                }
            }
        }
        return false
    }

    private func resolveFrame(for element: AXUIElement) -> CGRect? {
        guard
            let positionRef = rawAttribute(element, kAXPositionAttribute as String),
            let sizeRef = rawAttribute(element, kAXSizeAttribute as String)
        else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    private func recursiveElements(in root: AXUIElement) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var stack: [AXUIElement] = [root]
        while let current = stack.popLast() {
            result.append(current)
            stack.append(contentsOf: childElements(of: current).reversed())
        }
        return result
    }

    private func childElements(of element: AXUIElement) -> [AXUIElement] {
        guard let raw = rawAttribute(element, kAXChildrenAttribute as String) as? [AnyObject] else {
            return []
        }
        return raw.map { unsafeDowncast($0, to: AXUIElement.self) }
    }

    private func rawAttribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return error == .success ? value : nil
    }

    private func axElement(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let raw = rawAttribute(element, name) else { return nil }
        return unsafeDowncast(raw, to: AXUIElement.self)
    }

    private func stringAttribute(_ element: AXUIElement, _ name: String) -> String {
        guard let raw = rawAttribute(element, name) else { return "" }
        return raw as? String ?? ""
    }

    private func optionalStringAttribute(_ element: AXUIElement, _ name: String) -> String? {
        let value = stringAttribute(element, name)
        return value.isEmpty ? nil : value
    }

    private func titleOrDescription(for element: AXUIElement) -> String {
        let title = stringAttribute(element, kAXTitleAttribute as String)
        if !title.isEmpty { return title }
        return stringAttribute(element, kAXDescriptionAttribute as String)
    }

    private func normalizedLabel(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let label = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        return label.isEmpty ? nil : label
    }

    private func actionRole(for label: String) -> CodexApprovalAction.Role? {
        let lowercased = label.lowercased()
        if ["允许", "继续", "确认", "批准", "approve", "allow", "continue", "yes"].contains(where: lowercased.contains) {
            return .approve
        }
        if ["取消", "拒绝", "停止", "reject", "deny", "cancel", "no"].contains(where: lowercased.contains) {
            return .reject
        }
        if ["查看", "原因", "详情", "details", "why", "review"].contains(where: lowercased.contains) {
            return .neutral
        }
        return nil
    }
}
