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
                    .frame(width: 500, height: 350)
                    .padding(.top, -100)
                    .opacity(isShowingImage ? 1 : 0)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.5)) { isShowingImage = true }
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                
                Text(textFieldText)
                    .id(forceRefresh)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold)) // ✅ Adjust dynamically
                    .lineLimit(2) // ✅ Allow up to 2 lines
                    .minimumScaleFactor(0.5) // ✅ Shrink text if needed
                    .truncationMode(.tail) // ✅ Add "..." if text is too long
                    .padding(.top, 10)
                    .padding(.horizontal, 20) // ✅ Add margin on both sides
                    .frame(maxWidth: .infinity, alignment: .center) // ✅ Ensures text stays centered
                VStack(spacing: 0) { // ✅ No extra spacing between rows
             

                    TableRowView(title: "CORRECT ANSWERS", value: "\(aciertos)")
                    TableRowView(title: "WRONG ANSWERS", value: "\(errores)")
                    TableRowView(title: "SCORE", value: "\(puntuacion)")
                }
                .padding()
                .background(
                    Color(red: 121/255, green: 125/255, blue: 98/255).opacity(0.50) // ✅ 50% Transparent Background
                        .blur(radius: 5) // ✅ Soft Blur for a Modern Look
                )
                .cornerRadius(15) // ✅ More Rounded Corners
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.7), lineWidth: 2) // ✅ Soft White Border
                )
                .shadow(color: Color.white.opacity(0.15), radius: 5, x: 0, y: 5) // ✅ Subtle Glow Effect
                .frame(width: 320)
                // Buttons Section
                HStack {
                    Button("PLAY") {
                        SoundManager.shared.playTransitionSound()
                        checkForQuestionsBeforePlaying()
                    }
                    .buttonStyle(GameButtonStyle(color: Color(red: 121/255, green: 125/255, blue: 98/255)))
                    
                    Button("EXIT") {
                        SoundManager.shared.playTransitionSound()
                        showMenuModoLibre = true
                    }
                    .buttonStyle(GameButtonStyle(color: Color(red: 121/255, green: 125/255, blue: 98/255)))
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
                message: Text("You've completed Single Mode. You should try Competition Mode"),
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
        let scorePercentage = Double(aciertos) / 10.0 * 100.0
        var updatedImageName = ""
        var updatedTextFieldText = ""
        var audioFileName = ""

        if scorePercentage >= 90 {
            updatedImageName = "expert"  // 🏆 Expert trophy image
            updatedTextFieldText = LevelMessages.randomSuccessMessage()
            audioFileName = "expert.mp3"
        } else if scorePercentage >= 51 {
            updatedImageName = "average"  // 🏅 Average trophy image
            updatedTextFieldText = LevelMessages.randomAverageMessage()
            audioFileName = "average.mp3"
        } else {
            updatedImageName = "beginer"  // 🎖 Beginner trophy image
            updatedTextFieldText = LevelMessages.randomFailureMessage()
            audioFileName = "beginner.mp3"
        }

        DispatchQueue.main.async {
            self.imageName = updatedImageName // ✅ Assign trophy image
            self.textFieldText = updatedTextFieldText
            self.forceRefresh.toggle()
        }
        playSound(named: audioFileName) // ✅ Play relevant sound
    }
    
    private func saveLastScore() {
        UserDefaults.standard.set(puntuacion, forKey: "LastScore")
        UserDefaults.standard.synchronize()
       // print("saveLastScore: Last Score Saved: \(puntuacion)")
    }

    
    private func saveHighScore() {
        let currentHighScore = UserDefaults.standard.integer(forKey: "HighScore")
     //   print("Current High Score Before Update: \(currentHighScore)") // Debug log

        if puntuacion > currentHighScore {
            UserDefaults.standard.set(puntuacion, forKey: "HighScore")
            UserDefaults.standard.isNewHighScore = true // Mark it as a new high score
        //    print("New High Score Saved: \(puntuacion)") // Debug log
        } else {
         //   print("No new high score. High Score remains: \(currentHighScore)") // Debug log
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
          //  print("Sound file \(fileName) not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
           // print("Error playing sound: \(error)")
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
