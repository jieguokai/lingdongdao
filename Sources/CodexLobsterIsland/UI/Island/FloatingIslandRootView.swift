import SwiftUI

struct FloatingIslandRootView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    @State private var isHovered = false
    @GestureState private var isPressed = false

    private let expandedPanelCornerRadius: CGFloat = 22
    private let headerOverlap: CGFloat = 8

    var body: some View {
        let state = statusService.currentState
        let interactionPhase: InteractivePhase = {
            if isPressed {
                return .pressed
            }
            return isHovered ? .hovered : .resting
        }()

        Group {
            if isExpanded {
                expandedShell(state: state, interactionPhase: interactionPhase)
            } else {
                compactShell(state: state, interactionPhase: interactionPhase)
            }
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.26, dampingFraction: 0.84), value: isExpanded)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: interactionPhase)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
    }

    private func compactShell(state: CodexState, interactionPhase: InteractivePhase) -> some View {
        let notchShape = NotchShellShape()
        let glowOpacity = interactionPhase == .resting ? 0.16 : 0.24
        let glowRadius = interactionPhase == .pressed ? 10.0 : 16.0
        let glowScale = interactionPhase == .hovered ? 1.05 : 1.0
        let glowOffset = interactionPhase == .pressed ? 1.0 : 0.0
        let content = CompactIslandView(
            statusService: statusService,
            settingsStore: settingsStore,
            interactionPhase: interactionPhase,
            isExpanded: false,
            onToggleExpanded: onToggleExpanded
        )
        let surface = notchShape
            .fill(IslandStyle.notchFill)
            .overlay {
                notchShape
                    .strokeBorder(IslandStyle.notchEdge, lineWidth: 0.8)
            }
            .overlay {
                notchShape
                    .strokeBorder(IslandStyle.notchInnerEdge, lineWidth: 0.55)
                    .padding(1.2)
            }
        let glow = notchShape
            .fill(IslandStyle.glow(for: state).opacity(glowOpacity))
            .blur(radius: glowRadius)
            .scaleEffect(glowScale)
            .offset(y: glowOffset)

        return content
        .background {
            glow
        }
        .background(surface)
        .clipShape(notchShape)
        .shadow(color: Color.black.opacity(0.32), radius: 16, y: 7)
        .frame(width: AppConstants.compactIslandSize.width, height: AppConstants.compactIslandSize.height)
    }

    private func expandedShell(state: CodexState, interactionPhase: InteractivePhase) -> some View {
        let panelHeight = AppConstants.expandedIslandSize.height - AppConstants.compactIslandSize.height + headerOverlap
        let panelShape = RoundedRectangle(cornerRadius: expandedPanelCornerRadius, style: .continuous)

        return VStack(spacing: -headerOverlap) {
            compactShell(state: state, interactionPhase: interactionPhase)
                .zIndex(1)

            ExpandedIslandView(
                statusService: statusService,
                settingsStore: settingsStore,
                interactionPhase: interactionPhase,
                onToggleExpanded: onToggleExpanded
            )
            .frame(width: AppConstants.expandedIslandSize.width, height: panelHeight, alignment: .topLeading)
            .background(
                panelShape
                    .fill(IslandStyle.codexPanelFill)
                    .overlay(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(Color(.sRGB, red: 0.046, green: 0.049, blue: 0.058, opacity: 1))
                            .frame(width: AppConstants.compactIslandSize.width - 28, height: 16)
                            .offset(y: -8)
                    }
                    .overlay {
                        panelShape
                            .strokeBorder(IslandStyle.codexPanelStroke, lineWidth: 0.85)
                    }
                    .overlay {
                        panelShape
                            .strokeBorder(IslandStyle.codexPanelInnerStroke, lineWidth: 0.6)
                            .padding(1.3)
                    }
            )
            .clipShape(panelShape)
            .shadow(color: Color.black.opacity(0.35), radius: 24, y: 12)
        }
        .frame(width: AppConstants.expandedIslandSize.width, height: AppConstants.expandedIslandSize.height, alignment: .top)
    }
}
