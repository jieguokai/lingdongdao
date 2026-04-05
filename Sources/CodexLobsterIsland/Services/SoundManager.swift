import AppKit
import AVFoundation
import Observation

@MainActor
@Observable
final class SoundManager {
    var isMuted = false
    var isDoNotDisturbEnabled = false
    private(set) var isPreviewPlaying = false

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var typingCueArmed = true
    private var previewTask: Task<Void, Never>?

    func handleTransition(from previousSnapshot: CodexStatusSnapshot?, to newSnapshot: CodexStatusSnapshot) {
        let previousState = previousSnapshot?.state
        let newState = newSnapshot.state

        if newState == .running {
            typingCueArmed = true
        }

        if previousState == newState {
            return
        }

        switch newState {
        case .typing:
            if typingCueArmed {
                playTypingCue()
                typingCueArmed = false
            }
        case .running:
            playRunningCue()
        case .awaitingReply:
            playAwaitingReplyCue()
        case .awaitingApproval:
            playApprovalCue()
        case .success:
            playSuccessCue()
        case .error:
            playErrorCue()
        case .idle:
            break
        }
    }

    func playTypingCue() {
        play(.typing)
    }

    func playApprovalCue() {
        play(.approval)
    }

    func playRunningCue() {
        play(.running)
    }

    func playAwaitingReplyCue() {
        play(.awaitingReply)
    }

    func playSuccessCue() {
        play(.success)
    }

    func playErrorCue() {
        play(.error)
    }

    func playPreviewSequence() {
        guard !isPreviewPlaying, !isMuted, !isDoNotDisturbEnabled else {
            return
        }

        previewTask?.cancel()
        isPreviewPlaying = true

        previewTask = Task { [weak self] in
            guard let self else { return }

            for cue in Cue.previewSequence {
                if Task.isCancelled {
                    break
                }

                await MainActor.run {
                    self.play(cue)
                }

                let previewDelay = await MainActor.run {
                    self.previewDelay(for: cue)
                }
                let sleepDuration = UInt64((previewDelay * 1_000_000_000).rounded())
                try? await Task.sleep(nanoseconds: sleepDuration)
            }

            await MainActor.run {
                self.isPreviewPlaying = false
                self.previewTask = nil
            }
        }
    }

    private func play(_ cue: Cue) {
        if isMuted {
            return
        }
        if isDoNotDisturbEnabled, cue != .approval {
            return
        }

        if let resourceName = cue.resourceName {
            playResource(named: resourceName)
            return
        }

        NSSound.beep()
    }

    private func previewDelay(for cue: Cue) -> TimeInterval {
        guard let resourceName = cue.resourceName else {
            return Cue.previewSpacingPadding
        }
        return resourceDuration(named: resourceName) + Cue.previewSpacingPadding
    }

    private func playResource(named name: String) {
        if let player = audioPlayer(named: name) {
            player.currentTime = 0
            player.play()
            return
        }
    }

    private func resourceDuration(named name: String) -> TimeInterval {
        audioPlayer(named: name)?.duration ?? 0
    }

    private func audioPlayer(named name: String) -> AVAudioPlayer? {
        if let cached = audioPlayers[name] {
            return cached
        }

        guard let url = AppAudioResourceLocator.url(forResource: name) else {
            NSSound.beep()
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[name] = player
            return player
        } catch {
            NSSound.beep()
            return nil
        }
    }
}

private extension SoundManager {
    enum Cue {
        case typing
        case running
        case awaitingReply
        case approval
        case success
        case error

        var resourceName: String? {
            switch self {
            case .typing:
                return "typing"
            case .running:
                return "running"
            case .awaitingReply:
                return "awaitingReply"
            case .approval:
                return "approval"
            case .success:
                return "success"
            case .error:
                return "error"
            }
        }

        static let previewSequence: [Cue] = [
            .typing,
            .running,
            .awaitingReply,
            .approval,
            .success,
            .error
        ]

        static let previewSpacingPadding: TimeInterval = 0.18
    }
}
