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

        switch state {
        case .success:
            playResource(named: "success")
        case .error:
            playResource(named: "error")
        default:
            break
        }
    }

    private func playResource(named name: String) {
        if let cached = audioPlayers[name] {
            cached.currentTime = 0
            cached.play()
            return
        }

        guard let url = Bundle.module.url(forResource: name, withExtension: "wav", subdirectory: "Audio") else {
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
