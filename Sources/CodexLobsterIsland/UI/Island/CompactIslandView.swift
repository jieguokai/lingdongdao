import SwiftUI

struct CompactIslandView: View {
    let statusService: CodexStatusService
    let settingsStore: SettingsStore
    let interactionPhase: InteractivePhase
    var isExpanded: Bool = false
    let onToggleExpanded: () -> Void

    @State private var statusDotBreathing = false

    var body: some View {
        let state = statusService.effectiveDisplayState

        Button(action: onToggleExpanded) {
            HStack(spacing: 0) {
                LobsterAvatarView(
                    state: state,
                    animationsEnabled: settingsStore.settings.animationsEnabled,
                    interactionPhase: interactionPhase,
                    contentPadding: 0
                )
                .frame(width: 36, height: 26)
                .offset(x: -9)

                Spacer(minLength: 6)

                ZStack {
                    Circle()
                        .fill(IslandStyle.accent(for: state))
                        .frame(width: 7, height: 7)
                        .scaleEffect(settingsStore.settings.animationsEnabled ? (statusDotBreathing ? 2.15 : 1.0) : 1.0)
                        .opacity(settingsStore.settings.animationsEnabled ? (statusDotBreathing ? 0.05 : 0.22) : 0.0)

                    Circle()
                        .fill(IslandStyle.statusDotFill(for: state))
                        .frame(width: 7, height: 7)
                        .scaleEffect(settingsStore.settings.animationsEnabled ? (statusDotBreathing ? 1.08 : 0.88) : 1.0)
                        .opacity(settingsStore.settings.animationsEnabled ? (statusDotBreathing ? 0.94 : 0.74) : 1.0)
                        .shadow(color: IslandStyle.accent(for: state).opacity(statusDotBreathing ? 0.26 : 0.12), radius: statusDotBreathing ? 5 : 2)
                }
                .offset(x: -7)
            }
            .padding(.horizontal, 10)
            .frame(width: AppConstants.compactIslandContentSize.width, height: AppConstants.compactIslandContentSize.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            applyStatusDotBreathing(for: state)
        }
        .onChange(of: state) { _, newState in
            applyStatusDotBreathing(for: newState)
        }
        .onChange(of: settingsStore.settings.animationsEnabled) { _, _ in
            applyStatusDotBreathing(for: state)
        }
    }

    private func applyStatusDotBreathing(for state: CodexState) {
        guard settingsStore.settings.animationsEnabled else {
            statusDotBreathing = false
            return
        }

        statusDotBreathing = false
        withAnimation(statusDotAnimation(for: state).repeatForever(autoreverses: true)) {
            statusDotBreathing = true
        }
    }

    private func statusDotAnimation(for state: CodexState) -> Animation {
        switch state {
        case .idle:
            .easeInOut(duration: 1.25)
        case .typing:
            .easeInOut(duration: 0.62)
        case .running:
            .easeInOut(duration: 0.46)
        case .awaitingReply:
            .easeInOut(duration: 0.78)
        case .awaitingApproval:
            .easeInOut(duration: 0.9)
        case .success:
            .easeInOut(duration: 0.42)
        case .error:
            .easeInOut(duration: 0.54)
        }
    }
}
