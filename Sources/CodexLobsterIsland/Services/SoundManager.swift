import AppKit
import AVFoundation
import Observation

@MainActor
@Observable
final class SoundManager {
    var isMuted = false
    private var audioPlayers: [String: AVAudioPlayer] = [:]

    func play(for state: CodexState) {
        guard !isMuted else { return }
        guard let resourceName = state.soundResourceName else { return }
        playResource(named: resourceName)
    }

    private func playResource(named name: String) {
        if let cached = audioPlayers[name] {
            cached.currentTime = 0
            cached.play()
            return
        }

        guard let url = AppAudioResourceLocator.url(forResource: name) else {
            NSSound.beep()
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[name] = player
            player.play()
        } catch {
            NSSound.beep()
        }
    }
}
