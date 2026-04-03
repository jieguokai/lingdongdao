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
        let cornerRadius = isExpanded ? 30.0 : 19.0
        let islandShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let interactionPhase: InteractivePhase = {
            if !isExpanded && isPressed {
                return .pressed
            }
            return isHovered ? .hovered : .resting
        }()
        let scale: CGFloat = isExpanded ? 1.0 : (interactionPhase == .pressed ? 0.994 : (interactionPhase == .hovered ? 1.002 : 1.0))
        let yOffset: CGFloat = isExpanded ? 0.0 : (interactionPhase == .pressed ? 0.65 : (interactionPhase == .hovered ? -0.45 : 0.0))
        let auraOpacity: Double = {
            switch interactionPhase {
            case .resting: 0.14
            case .hovered: 0.23
            case .pressed: 0.27
            }
        }()
        let auraScale: CGFloat = interactionPhase == .pressed ? 1.08 : (interactionPhase == .hovered ? 1.16 : 1.02)
        let auraYOffset: CGFloat = interactionPhase == .pressed ? 2.5 : (interactionPhase == .hovered ? -2.0 : 0.0)

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
        .padding(isExpanded ? 18 : 4)
        .background {
            islandShape
                .fill(IslandStyle.glow(for: state).opacity(auraOpacity))
                .scaleEffect(auraScale)
                .offset(y: auraYOffset)
                .blur(radius: interactionPhase == .pressed ? 14 : 22)
        }
        .background(
            islandShape
                .fill(IslandStyle.shellGradient(for: state))
                .overlay {
                    islandShape
                        .fill(IslandStyle.materialWash(for: state))
                }
                .overlay(alignment: .top) {
                    islandShape
                        .fill(IslandStyle.topSheen)
                        .mask {
                            Rectangle()
                                .frame(height: isExpanded ? 120 : 42)
                                .offset(y: isExpanded ? -8 : -2)
                        }
                }
                .overlay {
                    islandShape
                        .strokeBorder(IslandStyle.edgeHighlight, lineWidth: 0.85)
                }
                .overlay {
                    islandShape
                        .strokeBorder(IslandStyle.innerStroke, lineWidth: 0.7)
                        .padding(1.3)
                }
        )
        .shadow(color: Color.black.opacity(isExpanded ? 0.34 : 0.28), radius: isExpanded ? 22 : 14, y: isExpanded ? 14 : 9)
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
