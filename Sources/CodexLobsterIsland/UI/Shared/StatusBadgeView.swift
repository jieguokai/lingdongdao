import SwiftUI

struct StatusBadgeView: View {
    let state: CodexState
    var compact = false

    var body: some View {
        Label(state.displayName, systemImage: state.symbolName)
            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(backgroundColor, in: Capsule())
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            .blue.opacity(0.5)
        case .running:
            .teal.opacity(0.6)
        case .success:
            .green.opacity(0.7)
        case .error:
            .red.opacity(0.7)
        }
    }
}
