// AudioManager.swift
import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var currentMusicFile: String?

    private init() {}

    func playMusic(fileName: String, volume: Float = 0.7) {
        if !AppSettingsStore.musicEnabled {
            stopMusic()
            return
        }

        if currentMusicFile == fileName, let player = musicPlayer, player.isPlaying {
            return
        }

        stopMusic()
        currentMusicFile = fileName

        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        let name = parts.first ?? fileName
        let ext = (parts.count == 2) ? parts[1] : nil

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("AudioManager: missing music file \(fileName)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            player.play()

            musicPlayer = player
        } catch {
            print("AudioManager: failed to play \(fileName). Error: \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicFile = nil
    }
}
