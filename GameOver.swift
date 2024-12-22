

import SwiftUI
import AVFoundation

struct GameOver: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var isAnimating: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var shouldShowResults: Bool = false
    @State private var showTextView = false
    var userId: String
    
    @State private var audioPlayer: AVAudioPlayer?
    
    var audioURL: URL? {
        return Bundle.main.url(forResource: "gameover", withExtension: "mp3")
    }
    
    var dismissAction: (() -> Void)? // Optional dismiss action for previews
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    shouldShowResults = true
                }) {
                    Text("GAME OVER")
                        .scaledToFit()
                        .foregroundColor(Color.white)
                        .frame(width: 100, height: 100)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                if showTextView {
                    Text("CLICK HERE TO CONTINUE")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .cornerRadius(10)
                        .offset(y: -50)
                        .onTapGesture {
                            // Add action for the tap gesture
                        }
                }
                Spacer()
            }
            .fullScreenCover(isPresented: $shouldShowResults) {
                ResultadoCompeticion(userId: userId)
                    .onDisappear {
                        dismissAction?() // Use custom dismiss action for previews
                        presentationMode.wrappedValue.dismiss() // Runtime dismissal
                    }
            }
            
            .navigationBarHidden(true)
            .onAppear {
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
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.showTextView = true
                                }
                            }
                        }
                    }
                }
                
                playSound()
            }
            .onDisappear {
                print("GameOver screen disappeared")
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func playSound() {
        if let url = audioURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Couldn't load or play the 'gameover.mp3' file: \(error)")
            }
        } else {
            print("The 'gameover.mp3' file was not found in the bundle.")
        }
    }
    
    struct GameOver_Previews: PreviewProvider {
        static var previews: some View {
            GameOver(userId: "dummyUserId", dismissAction: {
                print("Mocked dismissal action in preview")
            })
                .previewDevice("iPhone 14")
                .previewDisplayName("Game Over Screen")
        }
    }
}




