import SwiftUI
import AVFAudio
import AVFoundation

extension Notification.Name {
    static let newHighScore = Notification.Name("newHighScore")
}

struct MenuModoLibre: View {
    @State private var playerName: String = ""
    @State private var jugadorGuardado: String = ""
    @State private var jugarModoLibreActive: Bool = false
    @State private var highScore: Int = 0
    @State private var colorIndex: Int = 0
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var glowColor = Color.blue
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isShowingMenuPrincipal = false
    @State private var showNoQuestionsLeftAlert = false
    @State private var dbHelper = QuizDBHelper.shared
    @State private var showHighScoreAlert = false
    private let playerNameKey = "PlayerName"
    private let highScoreKey = "HighScore"
    @State private var isNewHighScore: Bool = false //
    @State private var highScoreMessage: String = "No high score yet"
    
    init() {
        loadPlayerName()
        loadHighScore()
    }
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 150)
                    .padding(.top, 40)
                    .shadow(color: glowColor.opacity(0.8), radius: 10, x: 0.0, y: 0.0)
                    .onReceive(timer) { _ in updateGlowColor() }
       


                if jugadorGuardado.isEmpty {
                    // When no player is saved, show the input field
                    TextField("ENTER YOUR NAME", text: $playerName)
                        .foregroundColor(.black)
                        .font(.system(size: 18))
                        .frame(width: 220, height: 50)
                        .multilineTextAlignment(.center)
                        .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.black, lineWidth: 2))
                        .background(RoundedRectangle(cornerRadius: 1).fill(Color.white))
                } else {
                    // Show a greeting if a player name is saved
                    Text("Ambolan \(jugadorGuardado)!")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 200)
                }

                Text(highScoreMessage)
                    .foregroundColor(getFlashingColor())
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                Button(action: {
                    if jugadorGuardado.isEmpty {
                        // Play magical sound only when saving the name for the first time
                        SoundManager.shared.playMagicalSound()
                    } else {
                        // Play transition sound if changing the player
                        SoundManager.shared.playTransitionSound()
                        UserDefaults.standard.removeObject(forKey: "HighScore") // Clear high score
                        print("High Score cleared for previous user: \(jugadorGuardado).") // Debug log
                    }
                    savePlayerName()
                    jugadorGuardado = playerName // Update the saved player name
                    playerName = "" // Clear the text field after saving
                    print("Player name saved/changed to: \(jugadorGuardado).") // Debug log
                }) {
                    Text(jugadorGuardado.isEmpty ? "SAVE" : "CHANGE PLAYER")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .multilineTextAlignment(.center)
                        .background(Color(hue: 0.664, saturation: 0.935, brightness: 0.604))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    checkForQuestionsBeforePlaying()
                }) {
                    Text("PLAY")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 0.315, saturation: 0.953, brightness: 0.335))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    isShowingMenuPrincipal = true
                }) {
                    Text("EXIT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .fullScreenCover(isPresented: $isShowingMenuPrincipal) {
                    MenuPrincipal(player: .constant(nil))
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $jugarModoLibreActive) {
            JugarModoLibre(player: .constant(nil))
        }
        .alert(isPresented: Binding(
            get: { showNoQuestionsLeftAlert || showHighScoreAlert },
            set: { _ in
                showNoQuestionsLeftAlert = false
                showHighScoreAlert = false
            }
        )) {
            if showNoQuestionsLeftAlert {
                return Alert(
                    title: Text("Congrats champ"),
                    message: Text("You have completed the Single Mode. You should try Competition?"),
                    dismissButton: .default(Text("OK"), action: {
                        dbHelper.resetShownQuestions()
                        DispatchQueue.main.async {
                            isShowingMenuPrincipal = true
                        }
                    })
                )
            } else {
                return Alert(
                              title: Text("Congratulations !"),
                              message: Text("You set a new HighScore of : \(highScore)"),
                              dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            // Ensure the correct high score message is set when the view appears
                   if isNewHighScore {
                       showHighScoreAlert = true // Trigger the alert for new high score
                   }
               }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadPlayerName()
            loadHighScore()

            let lastScore = UserDefaults.standard.integer(forKey: "LastScore")
                   print("onAppear: Last Score Loaded: \(lastScore)") // Debug log

                   if UserDefaults.standard.isNewHighScore {
                       // Update the high score and message
                       highScore = lastScore
                       highScoreMessage = "New HighScore is \(highScore) points"
                       isNewHighScore = true
                       showHighScoreAlert = true // Trigger the alert
                       UserDefaults.standard.isNewHighScore = false // Reset the flag
                       print("onAppear: Detected new high score in MenuModoLibre.") // Debug log
                   } else {
                       // Default to current high score
                       highScoreMessage = "Current HighScore is \(highScore) points"
                       isNewHighScore = false
                       print("onAppear: No new high score in MenuModoLibre. High Score remains: \(highScore)") // Debug log
                   }
               }
    }
    private func updateHighScore(newScore: Int) {
        if newScore > highScore {
            highScore = newScore
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
            print("New high score: \(highScore)")
        }
    }
    
    private func checkForQuestionsBeforePlaying() {
        if let unusedQuestions = dbHelper.getRandomQuestions(count: 10), !unusedQuestions.isEmpty {
            jugarModoLibreActive = true
            print("Enough questions available. Starting Single Mode.")
        } else {
            showNoQuestionsLeftAlert = true
            print("No questions available. Triggering alert.")
        }
    }
    
    private func savePlayerName() {
        UserDefaults.standard.set(playerName, forKey: playerNameKey)
    }
    
    private func loadPlayerName() {
        if let savedPlayerName = UserDefaults.standard.string(forKey: playerNameKey) {
            jugadorGuardado = savedPlayerName
            print("Player Name Loaded: \(jugadorGuardado)")
        } else {
            print("No Player Name Found in UserDefaults.")
        }
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        print("High Score Loaded: \(highScore)") // Debug print
    }
    
    private func getFlashingColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .white]
        return colors[colorIndex]
    }
    
    private func updateGlowColor() {
        switch glowColor {
        case .blue: glowColor = .green
        case .green: glowColor = .red
        case .red: glowColor = .white
        default: glowColor = .blue
        }
    }
}

struct MenuModoLibre_Previews: PreviewProvider {
    static var previews: some View {
        MenuModoLibre()
    }
}
