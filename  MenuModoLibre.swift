import SwiftUI
import AVFAudio
import AVFoundation

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
    
    private let playerNameKey = "PlayerName"
    private let highScoreKey = "HighScore"
    
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
                    TextField("ENTER YOUR NAME", text: $playerName)
                        .foregroundColor(.black)
                        .font(.system(size: 18))
                        .frame(width: 220, height: 50)
                        .multilineTextAlignment(.center)
                        .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.black, lineWidth: 2))
                        .background(RoundedRectangle(cornerRadius: 1).fill(Color.white))
                } else {
                    Text("Karibu \(jugadorGuardado)!")
                        .foregroundColor(.black)
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 200)
                    
                }
                
                Text("Current highscore is \(highScore) points")
                    .foregroundColor(getFlashingColor())
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                
                Button(action: {
                    if jugadorGuardado.isEmpty {
                        SoundManager.shared.playMagicalSound() // Play sound only when saving the name for the first time
                    } else {
                        SoundManager.shared.playTransitionSound() // Play transition sound if changing the player
                    }
                    savePlayerName()
                    jugadorGuardado = playerName
                    playerName = "" // Clear the text field after saving
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
        .alert(isPresented: $showNoQuestionsLeftAlert) {
            Alert(
                title: Text("Congrats champ"),
                message: Text("You have completed the Single Mode. How about you try Competition Mode?"),
                dismissButton: .default(Text("OK"), action: {
                    dbHelper.resetShownQuestions()
                    isShowingMenuPrincipal = true
                })
            )
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadPlayerName()
            loadHighScore()
        }
    }
    
    private func checkForQuestionsBeforePlaying() {
        if let unusedQuestions = dbHelper.getRandomQuestions(count: 10), !unusedQuestions.isEmpty {
            jugarModoLibreActive = true
        } else {
            showNoQuestionsLeftAlert = true
        }
    }
    
    private func savePlayerName() {
        UserDefaults.standard.set(playerName, forKey: playerNameKey)
    }
    
    private func loadPlayerName() {
        if let savedPlayerName = UserDefaults.standard.string(forKey: playerNameKey) {
            jugadorGuardado = savedPlayerName
        }
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
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
