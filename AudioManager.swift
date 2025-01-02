import AVFoundation

class AudioManager {
    static let shared = AudioManager()

    private var swooshPlayer: AVAudioPlayer?
    private var isSoundPlaying = false

    private init() {
        // Load the swoosh sound file
        if let url = Bundle.main.url(forResource: "swoosh", withExtension: "wav") {
            do {
                swooshPlayer = try AVAudioPlayer(contentsOf: url)
                swooshPlayer?.prepareToPlay() // Preload the sound for faster playback
            } catch {
                print("Failed to initialize swooshPlayer: \(error.localizedDescription)")
            }
        } else {
            print("Swoosh sound file not found in the bundle.")
        }
    }

    /// Plays the swoosh sound with safeguards to prevent overlapping.
    func playSwooshSound() {
        guard let swooshPlayer = swooshPlayer, !isSoundPlaying else { return }

        isSoundPlaying = true
        swooshPlayer.stop() // Stop any ongoing playback
        swooshPlayer.currentTime = 0 // Reset to the start of the sound
        swooshPlayer.play() // Play the sound
        print("swoosh.wav sound is now playing.")

        // Reset `isSoundPlaying` after the sound finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + swooshPlayer.duration) {
            self.isSoundPlaying = false
            print("Sound playback finished.")
        }
    }

    /// Resets the audio session in case of audio system issues.
    func resetAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setActive(true)
            print("Audio session reset successfully.")
        } catch {
            print("Failed to reset audio session: \(error.localizedDescription)")
        }
    }

    /// Cleans up resources when no longer needed.
    deinit {
        swooshPlayer?.stop()
        swooshPlayer = nil
        print("AudioManager deinitialized.")
    }
}//
//  AudioManager.swift
//  AfrikaNaOne
//
//  Created by INICIATIVAS ELEBI on 1/2/25.
//

