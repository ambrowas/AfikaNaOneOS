import AVFoundation

class SoundManager: NSObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private let loopedSounds = ["alpha", "beta", "gama", "delta", "kapa", "epsilon"] // ✅ Added "epsilon"
    private var isLooping = false // ✅ Tracks if looping is active
    var isPlaying: Bool = false
    private var selectedLoopedSound: String? // ✅ Store the sound chosen for the session

    // MARK: - 🔹 Play Random Looped Sound
    func playRandomLoopedSound() {
        stopLoopedSound() // ✅ Ensure no duplicate loops
        isLooping = true
        
        // ✅ Choose a random sound ONCE per session
        if selectedLoopedSound == nil {
            selectedLoopedSound = loopedSounds.randomElement() ?? "alpha"
        }
        
        guard let soundURL = Bundle.main.url(forResource: selectedLoopedSound, withExtension: "mp3") else {
            print("Error: Could not find \(selectedLoopedSound!).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1 // ✅ Infinite loop (no delay)
            audioPlayer?.play()
            isPlaying = true
            print("🔊 Now playing looped sound: \(selectedLoopedSound!).mp3")
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }

    // MARK: - 🔹 Stop Looped Sound
    func stopLoopedSound() {
        isLooping = false
        audioPlayer?.stop()
        audioPlayer = nil // ✅ Ensure cleanup
        selectedLoopedSound = nil // ✅ Reset selection when stopping
        isPlaying = false
        print("🔇 Looped sound stopped.")
    }

    private override init() { }

    // MARK: - 🔹 Play One-Time Sounds
    private func prepareAndPlaySound(fileName: String, fileExtension: String) {
        // ✅ Ensure only one sound plays at a time
        if isPlaying {
            print("A sound is already playing. Skipping playback for \(fileName).")
            return
        }

        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Sound file \(fileName).\(fileExtension) not found in the app bundle.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            print("▶️ \(fileName).\(fileExtension) sound is now playing.")
        } catch let error as NSError {
            print("❌ Failed to play sound \(fileName).\(fileExtension): \(error.localizedDescription)")
        }
    }

    // MARK: - 🔹 Other Sound Functions
    func playTransitionSound() {
        prepareAndPlaySound(fileName: "swoosh", fileExtension: "wav")
    }
    
    func playMagicalSound() {
        prepareAndPlaySound(fileName: "magic", fileExtension: "mp3")
    }
    
    func playWarningSound() {
        prepareAndPlaySound(fileName: "warning", fileExtension: "mp3")
    }

    func stopCurrentSound() {
        audioPlayer?.stop()
        isPlaying = false
        print("⏹️ Current sound stopped.")
    }
}

// MARK: - 🔹 AVAudioPlayerDelegate
extension SoundManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("🔁 Sound playback finished.")
        
        // ✅ If looping is enabled, restart immediately (no delay)
        if isLooping {
            self.playRandomLoopedSound()
        }
    }
}
