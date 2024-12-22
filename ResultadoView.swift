import SwiftUI
import AVFoundation

extension UserDefaults {
    var isNewHighScore: Bool {
        get { bool(forKey: "IsNewHighScore") }
        set { set(newValue, forKey: "IsNewHighScore") }
    }
}

struct ResultadoView: View {
    let aciertos: Int
    let puntuacion: Int
    let errores: Int
    @State private var imageName = "placeholder-image"
    @State private var textFieldText = "Welcome to the Quiz!"
    @State private var isShowingImage = false
    @State private var isAnimating = false
    @State private var forceRefresh = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var jugarModoLibreActive: Bool = false
    @State private var showMenuModoLibre: Bool = false
    @State private var showNoQuestionsLeftAlert: Bool = false
    @State private var dbHelper = QuizDBHelper.shared
    
    
    
    var body: some View {
        ZStack {
            // Background
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Image Section
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 250)
                    .padding(.top, -100)
                    .opacity(isShowingImage ? 1 : 0)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.5)) { isShowingImage = true }
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                
                // Dynamic Text
                Text(textFieldText)
                    .id(forceRefresh)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 10)
                
                // Score Boxes
                scoreBox(title: "CORRECT ANSWERS", value: aciertos)
                scoreBox(title: "WRONG ANSWERS", value: errores)
                scoreBox(title: "SCORE", value: puntuacion)
                
                // Buttons Section
                HStack {
                    Button("PLAY") {
                        SoundManager.shared.playTransitionSound()
                        checkForQuestionsBeforePlaying()
                    }
                    .buttonStyle(GameButtonStyle(color: Color(hue: 0.69, saturation: 0.89, brightness: 0.706)))
                    
                    Button("EXIT") {
                        SoundManager.shared.playTransitionSound()
                        showMenuModoLibre = true
                    }
                    .buttonStyle(GameButtonStyle(color: Color(hue: 1.0, saturation: 0.984, brightness: 0.699)))
                }
                .padding(.top, 30)
            }
        }
        .onAppear {
            handleAciertos()
            saveLastScore() // Save the last score
               saveHighScore() // Update the high score
        }
        .fullScreenCover(isPresented: $jugarModoLibreActive) {
            JugarModoLibre(player: .constant(nil))
        }
        .fullScreenCover(isPresented: $showMenuModoLibre) {
            MenuModoLibre()
        }
        .alert(isPresented: $showNoQuestionsLeftAlert) {
            Alert(
                title: Text("CONGRATS CHAMP"),
                message: Text("You've completed Single Mode. How about you try Competition Mode"),
                dismissButton: .default(Text("OK")) {
                    print("Alert dismissed")
                    dbHelper.resetShownQuestions()
                }
            )
        }
        .onChange(of: showNoQuestionsLeftAlert) { newValue in
            if newValue {
                SoundManager.shared.playMagicalSound()
            }
        }
    }
    // MARK: - Helper Methods
    private func handleAciertos() {
        var updatedImageName = ""
        var updatedTextFieldText = ""
        var audioFileName = ""

        if aciertos >= 9 {
            updatedImageName = "expert"
            updatedTextFieldText = "FANTASTIC. WE NEED MORE (PAN)AFRICANS LIKE YOU"
            audioFileName = "expert.mp3"
        } else if aciertos >= 5 {
            updatedImageName = "average"
            updatedTextFieldText = "NOT BAD, BUT YOU COULD DO BETTER FOR THE CONTINENT"
            audioFileName = "average.mp3"
        } else {
            updatedImageName = "beginer"
            updatedTextFieldText = "IT'S PEOPLE LIKE YOU HOLDING AFRICA BACK"
            audioFileName = "beginner.mp3"
        }

        DispatchQueue.main.async {
            self.imageName = updatedImageName
            self.textFieldText = updatedTextFieldText
            self.forceRefresh.toggle()
        }
        playSound(named: audioFileName)
    }
    
    private func saveLastScore() {
        UserDefaults.standard.set(puntuacion, forKey: "LastScore")
        UserDefaults.standard.synchronize()
        print("saveLastScore: Last Score Saved: \(puntuacion)")
    }

    
    private func saveHighScore() {
        let currentHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        print("Current High Score Before Update: \(currentHighScore)") // Debug log

        if puntuacion > currentHighScore {
            UserDefaults.standard.set(puntuacion, forKey: "HighScore")
            UserDefaults.standard.isNewHighScore = true // Mark it as a new high score
            print("New High Score Saved: \(puntuacion)") // Debug log
        } else {
            print("No new high score. High Score remains: \(currentHighScore)") // Debug log
        }
    }
    
    

    private func checkForQuestionsBeforePlaying() {
        let unusedQuestions = dbHelper.getRandomQuestions(count: 10)
        if !unusedQuestions!.isEmpty {
            jugarModoLibreActive = true
        } else {
            showNoQuestionsLeftAlert = true
        }
    }
    
    private func playSound(named fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Sound file \(fileName) not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }

    // MARK: - Reusable Score Box
    private func scoreBox(title: String, value: Int) -> some View {
        let textColor: Color
        switch title {
        case "CORRECT ANSWERS": textColor = Color(hue: 0.617, saturation: 0.831, brightness: 0.591) // Blue
        case "WRONG ANSWERS": textColor = Color(hue: 0.994, saturation: 0.963, brightness: 0.695) // Red
        case "SCORE": textColor = Color(hue: 0.404, saturation: 0.934, brightness: 0.334) // Green
        default: textColor = .black
        }
        return Text("\(title): \(value)")
            .font(.headline)
            .foregroundColor(textColor)
            .padding()
            .frame(width: 300, height: 65)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 10))
            .cornerRadius(10)
            .padding(.top, 10)
        
    }
}

// MARK: - Custom Button Style
struct GameButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 180, height: 60)
            .background(color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 3)
            )
            .shadow(radius: 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
struct ResultadoView_Previews: PreviewProvider {
    static var previews: some View {
        ResultadoView(aciertos: 8, puntuacion: 4000, errores: 2)
            .previewLayout(.sizeThatFits)
    }
}
