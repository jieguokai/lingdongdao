import SwiftUI

struct FloatingIslandRootView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    @State private var isHovered = false
    @GestureState private var isPressed = false

    var body: some View {
        let state = statusService.currentState
        let cornerRadius = isExpanded ? 28.0 : 21.0
        let islandShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let interactionPhase: InteractivePhase = {
            if !isExpanded && isPressed {
                return .pressed
            }
            return isHovered ? .hovered : .resting
        }()
        let scale: CGFloat = isExpanded ? 1.0 : (interactionPhase == .pressed ? 0.992 : (interactionPhase == .hovered ? 1.003 : 1.0))
        let yOffset: CGFloat = isExpanded ? 0.0 : (interactionPhase == .pressed ? 0.8 : (interactionPhase == .hovered ? -0.6 : 0.0))
        let auraOpacity: Double = {
            switch interactionPhase {
            case .resting: 0.14
            case .hovered: 0.28
            case .pressed: 0.34
            }
        }()
        let auraScale: CGFloat = interactionPhase == .pressed ? 1.18 : (interactionPhase == .hovered ? 1.28 : 1.08)
        let auraYOffset: CGFloat = interactionPhase == .pressed ? 3.0 : (interactionPhase == .hovered ? -3.0 : 0.0)

        Group {
            if isExpanded {
                ExpandedIslandView(
                    statusService: statusService,
                    settingsStore: settingsStore,
                    interactionPhase: interactionPhase,
                    onToggleExpanded: onToggleExpanded
                )
            } else {
                CompactIslandView(
                    statusService: statusService,
                    settingsStore: settingsStore,
                    interactionPhase: interactionPhase,
                    onToggleExpanded: onToggleExpanded
                )
            }
        }
        .padding(isExpanded ? 18 : 5)
        .background {
            islandShape
                .fill(IslandStyle.accent(for: state).opacity(auraOpacity))
                .scaleEffect(auraScale)
                .offset(y: auraYOffset)
                .blur(radius: interactionPhase == .pressed ? 18 : 24)
        }
        .background(
            islandShape
                .fill(.ultraThinMaterial)
                .overlay {
                    islandShape
                        .fill(IslandStyle.tintOverlay(for: state))
                }
                .overlay {
                    islandShape
                        .strokeBorder(IslandStyle.edgeHighlight, lineWidth: 0.85)
                }
        )
        .clipShape(islandShape)
        .compositingGroup()
        .contentShape(islandShape)
        .scaleEffect(scale)
        .offset(y: yOffset)
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
}
