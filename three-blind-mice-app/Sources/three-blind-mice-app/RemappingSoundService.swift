import AVFoundation
import Foundation

@MainActor
final class RemappingSoundService {
    static let shared = RemappingSoundService()

    private var onPlayer: AVAudioPlayer?
    private var offPlayer: AVAudioPlayer?

    private init() {
        onPlayer = loadPlayer(resourceName: "remapping-on")
        offPlayer = loadPlayer(resourceName: "remapping-off")
    }

    func playRemappingEnabled(_ enabled: Bool) {
        let player = enabled ? onPlayer : offPlayer
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private func loadPlayer(resourceName: String) -> AVAudioPlayer? {
        let url =
            Bundle.main.url(forResource: resourceName, withExtension: "mp3", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "mp3")
        guard let url else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }
}
