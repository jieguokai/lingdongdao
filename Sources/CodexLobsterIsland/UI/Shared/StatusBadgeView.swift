import SwiftUI

struct StatusBadgeView: View {
    let state: CodexState
    var compact = false
    var interactionPhase: InteractivePhase = .resting
    var animationsEnabled = true

    var body: some View {
        let style = InteractionStyle.badge(
            for: interactionPhase,
            animationsEnabled: animationsEnabled
        )

        Label(state.displayName, systemImage: state.symbolName)
            .font(compact ? .caption.weight(.medium) : .caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(compact ? IslandStyle.tertiaryText : IslandStyle.secondaryText)
            .scaleEffect(style.scale)
            .offset(y: style.yOffset)
            .animation(.spring(response: 0.22, dampingFraction: 0.76), value: interactionPhase)
    }
}
