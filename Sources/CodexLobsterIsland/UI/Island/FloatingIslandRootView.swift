import SwiftUI

struct FloatingIslandRootView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    @State private var isHovered = false
    @GestureState private var isPressed = false

    private let panelInset: CGFloat = 16

    private func islandScale(for phase: InteractivePhase, isExpanded: Bool) -> CGFloat {
        switch phase {
        case .resting:
            return 1.0
        case .hovered:
            return isExpanded ? 1.025 : 1.065
        case .pressed:
            return isExpanded ? 1.01 : 1.03
        }
    }

    var body: some View {
        let state = statusService.effectiveDisplayState
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
        .scaleEffect(islandScale(for: interactionPhase, isExpanded: isExpanded))
        .frame(
            width: isExpanded ? AppConstants.expandedIslandSize.width : AppConstants.compactIslandSize.width,
            height: isExpanded ? AppConstants.expandedIslandSize.height : AppConstants.compactIslandSize.height,
            alignment: .center
        )
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
        compactHeaderSurface(state: state, interactionPhase: interactionPhase)
    }

    private func compactHeaderContent(interactionPhase: InteractivePhase, isExpanded: Bool) -> some View {
        CompactIslandView(
            statusService: statusService,
            settingsStore: settingsStore,
            interactionPhase: interactionPhase,
            isExpanded: isExpanded,
            onToggleExpanded: onToggleExpanded
        )
        .frame(width: AppConstants.compactIslandContentSize.width, height: AppConstants.compactIslandContentSize.height)
    }

    private func compactHeaderSurface(state: CodexState, interactionPhase: InteractivePhase) -> some View {
        let notchShape = NotchShellShape(topEdgeExtension: 0, topTransitionRadius: 0, bottomCornerRadius: 14)
        let content = compactHeaderContent(interactionPhase: interactionPhase, isExpanded: false)

        return content
            .background {
                notchShape
                    .fill(Color.black)
            }
            .clipShape(notchShape)
            .frame(width: AppConstants.compactIslandContentSize.width, height: AppConstants.compactIslandContentSize.height)
    }

    private func expandedShell(state: CodexState, interactionPhase: InteractivePhase) -> some View {
        let panelShape = NotchShellShape(topEdgeExtension: 0, topTransitionRadius: 0, bottomCornerRadius: 14)
        let panelWidth = AppConstants.expandedIslandContentSize.width - (panelInset * 2)
        let contentInsetTop: CGFloat = 10
        let contentInsetBottom: CGFloat = 14
        let contentHeight = AppConstants.expandedIslandContentSize.height - contentInsetTop - contentInsetBottom

        return ZStack(alignment: .top) {
            panelShape
                .fill(Color.black)

            ExpandedIslandView(
                statusService: statusService,
                settingsStore: settingsStore,
                interactionPhase: interactionPhase,
                onToggleExpanded: onToggleExpanded
            )
            .frame(width: panelWidth, height: contentHeight, alignment: .topLeading)
            .offset(y: contentInsetTop)
        }
        .frame(width: AppConstants.expandedIslandContentSize.width, height: AppConstants.expandedIslandContentSize.height, alignment: .top)
        .clipShape(panelShape)
    }
}
