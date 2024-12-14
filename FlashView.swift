//
//  ContentView.swift
//  AfrikaNaOne
//
//  Created by ELEBI on 11/30/24.
//
import SwiftUI
import AVFoundation
import Firebase

struct FlashView: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var player: AVAudioPlayer?
    @State private var isAnimating: Bool = false
    @State private var showNextView = false
    @State private var shouldNavigateToMenuPrincipal = false
    @State private var showTextView = false
    @State private var randomProverb: String = ""
    @State private var showProverb = false
    @State private var isFlashing = false // Add this state variable at the top of your view

    enum NavigationDestination {
        case none
        case menuPrincipal
    }

    var audioURL: URL? {
        return Bundle.main.url(forResource: "bikutsi", withExtension: "mp3")
    }

    @State private var navigationTarget: NavigationDestination = .none

    var body: some View {
        ZStack {
            // Background Image
            Image("darkblue")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)

            VStack() { // Adjust spacing as needed
                // Logo Image
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .offset(y: -50)

                // Proverb Text
                if showProverb {
                    Text(randomProverb)
                        .font(.headline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center) // Center text
                        .lineLimit(nil) // Allow multiple lines
                        .frame(maxWidth: 300) // Restrict the width for text wrapping
                        .padding(.horizontal, 20) // Add horizontal margin
                }

                // Flashing Navigation Text
                          if showTextView {
                              Text("CLICK HERE, LET'S GO")
                                  .font(.headline)
                                  .foregroundColor(.black)
                                  .multilineTextAlignment(.center)
                                  .opacity(isFlashing ? 1.0 : 0.2)
                                  .animation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true), value: isFlashing)
                                  .padding()
                                  .onTapGesture {
                                      SoundManager.shared.playTransitionSound()
                                      self.shouldNavigateToMenuPrincipal = true
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Keep everything centered
            .padding(.horizontal, 20) // Extra horizontal margin if needed
        }
        .fullScreenCover(isPresented: $shouldNavigateToMenuPrincipal) {
            MenuPrincipal(player: .constant(nil))
        }
        .onAppear {
            loadAudio()
            startAnimations()
            isFlashing = true // Start the flashing animation when the view appears
        }
    }
    func startFlashingText() {
        withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
            isFlashing.toggle()
        }
    }
    
    private func loadAudio() {
        DispatchQueue.global().async {
            if let url = self.audioURL {
                do {
                    self.player = try AVAudioPlayer(contentsOf: url)
                    self.player?.prepareToPlay()
                    DispatchQueue.main.async {
                        self.player?.play()
                        self.fadeOutAndStop(after: 10.0, fadeDuration: 2.0) // Play for 10 seconds, fade over 2 seconds
                    }
                } catch {
                    print("Could not create AVAudioPlayer: \(error)")
                }
            } else {
                print("Could not find URL for audio file")
            }
        }
    }

    private func fadeOutAndStop(after totalDuration: TimeInterval, fadeDuration: TimeInterval) {
        guard let player = self.player else { return }

        let fadeInterval: TimeInterval = 0.1 // Interval to decrease the volume
        let fadeSteps = Int(fadeDuration / fadeInterval) // Total steps for fading
        let volumeStep = player.volume / Float(fadeSteps) // Volume decrement per step

        // Schedule fade-out to begin at totalDuration - fadeDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + (totalDuration - fadeDuration)) {
            var currentStep = 0
            Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: true) { timer in
                if currentStep < fadeSteps {
                    player.volume -= volumeStep
                    currentStep += 1
                } else {
                    timer.invalidate()
                    player.stop()
                    player.currentTime = 0 // Reset playback to the start
                    player.volume = 1.0 // Reset volume for the next playback
                }
            }
        }
    }

    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 3.0)) {
            self.scale = 3.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(Animation.linear(duration: 1.0)) {
                self.rotation = 360.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(Animation.easeInOut(duration: 3.0)) {
                    self.scale = 2.0

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            self.isAnimating = true
                        }

                        // Fetch a random proverb after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            fetchRandomProverb()

                            // Show "PULSA AQUI" text after the proverb appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.showTextView = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func fetchRandomProverb() {
        let db = Firestore.firestore()
        db.collection("PROVERBS").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching proverbs: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No proverbs found.")
                return
            }

            let randomDocument = documents.randomElement()
            if let proverb = randomDocument?.data()["text"] as? String {
                DispatchQueue.main.async {
                    self.randomProverb = proverb
                    self.showProverb = true
                }
            } else {
                print("No 'text' field found in the random document.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FlashView()
            .previewDevice("iPhone 14")
    }
}
