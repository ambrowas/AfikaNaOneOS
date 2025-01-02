import AVFoundation


class SoundManager: NSObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    
    private override init() { }
    
    private func prepareAndPlaySound(fileName: String, fileExtension: String) {
        // Ensure only one sound plays at a time
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
            print("\(fileName).\(fileExtension) sound is now playing.")
        } catch let error as NSError {
            print("Failed to play sound \(fileName).\(fileExtension): \(error.localizedDescription)")
        }
    }
    
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
        audioPlayer = nil
        isPlaying = false
        print("Current sound stopped.")
    }
}

// MARK: - AVAudioPlayerDelegate
extension SoundManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("Sound playback finished.")
    }
}
