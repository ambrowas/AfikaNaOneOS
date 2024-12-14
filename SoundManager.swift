import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() { }
    
    func playSoundEffect(_ sound: AVAudioPlayer?, name: String) {
           guard let sound = sound else {
               print("\(name) sound effect is not initialized.")
               return
           }
           if sound.isPlaying {
               sound.stop() // Stop any existing playback
           }
           sound.currentTime = 0 // Start from the beginning
           sound.play()
           print("\(name) sound effect played.")
       }
    
    func playTransitionSound() {
        // Get the URL of the sound file in the app bundle
        if let soundURL = Bundle.main.url(forResource: "swoosh", withExtension: "wav") {
            do {
                // Initialize and play the audio player
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch let error as NSError {
                // Handle and print the error
                print("Failed to play transition sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file 'swoosh.wav' not found in the app bundle.")
        }
    }
    
    func playMagicalSound() {
        // Get the URL of the sound file in the app bundle
        if let soundURL = Bundle.main.url(forResource: "magic", withExtension: "mp3") {
            do {
                // Initialize and play the audio player
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch let error as NSError {
                // Handle and print the error
                print("Failed to play transition sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file 'swoosh.wav' not found in the app bundle.")
        }
    }
    
    func playWarningSound() {
        // Get the URL of the sound file in the app bundle
        if let soundURL = Bundle.main.url(forResource: "warning", withExtension: "mp3") {
            do {
                // Initialize and play the audio player
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch let error as NSError {
                // Handle and print the error
                print("Failed to play transition sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file 'swoosh.wav' not found in the app bundle.")
        }
    }
}
