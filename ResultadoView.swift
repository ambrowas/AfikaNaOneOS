import SwiftUI
import AVFoundation

struct ResultadoView: View {
    let aciertos: Int
    let puntuacion: Int
    let errores: Int
    @State private var imageName = ""
    @State private var textFieldText = ""
    @State private var isShowingImage = false
    @State private var isTextVisible = false
    @State private var player: AVAudioPlayer?
    @Environment(\.presentationMode) var presentationMode
    @State private var showMenuModoLibre = false
    @State private var playerName: String = ""
    @State private var highScore: Int = 0
    @State private var isNewHighScore: Bool = false
    @State private var showAlert = false
    @State private var isAnimating: Bool = false
    @State private var dbHelper = QuizDBHelper.shared
    @State private var navigateToMenuPrincipal = false
    @State private var jugarModoLibreActive: Bool = false
    @State private var showNoQuestionsLeftAlert = false // Initialize the state variable
    @State private var showCustomPopup = false

    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.top, -100.0)
                    .frame(width: 300, height: 250)
                    .opacity(isShowingImage ? 1 : 0)
                    .scaleEffect(isAnimating ? 1.1 : 1.0) // Pulse animation
                    .onAppear {
                        withAnimation(.easeIn(duration: 2.0)) {
                            isShowingImage = true
                        }
                        // Pulse Animation
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                
                
                if #available(iOS 16.0, *) {
                    Text(textFieldText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.top, -50)
                        .opacity(isTextVisible ? 1 : 0)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                self.isTextVisible.toggle()
                            }
                        }
                } else {
                    // Fallback on earlier versions
                };if #available(iOS 16.0, *) {
                    Text(textFieldText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.top, -50)
                        .opacity(isTextVisible ? 1 : 0)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                self.isTextVisible.toggle()
                            }
                        }
                } else {
                    // Fallback on earlier versions
                }
                
                TextField("", text: $playerName)
                    .font(.title)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .frame(width: 300, height: 65)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        Text("CORRECT ANSWERS: \(aciertos)")
                            .font(.headline)
                            .foregroundColor(Color(hue: 0.617, saturation: 0.831, brightness: 0.591))
                            .padding(.horizontal)
                    )
                
                TextField("", text: .constant(""))
                    .font(.title)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .frame(width: 300, height: 65)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        Text("WRONG ANSWERS: \(errores)")
                            .font(.headline)
                            .foregroundColor(Color(hue: 0.994, saturation: 0.963, brightness: 0.695))
                            .padding(.horizontal)
                    )
                
                TextField("", text: .constant(""))
                    .font(.title)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .frame(width: 300, height: 65)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .overlay(
                        Text("SCORE: \(puntuacion)")
                            .font(.headline)
                            .foregroundColor(Color(hue: 0.404, saturation: 0.934, brightness: 0.334))
                            .padding(.horizontal)
                    )
                HStack {
                    Button(action: {
                        SoundManager.shared.playTransitionSound()
                        print("JUGAR button tapped")
                        checkForQuestionsBeforePlaying()
                        
                    }) {
                        Text("PLAY")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 180, height: 60)
                            .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .padding(.top, 30)
                    .fullScreenCover(isPresented: $jugarModoLibreActive) {
                        JugarModoLibre(player: .constant(nil))
                    }
                    
                    Button(action: {
                        SoundManager.shared.playTransitionSound()
                        showMenuModoLibre = true
                        
                    }) {
                        Text("EXIT")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 180, height: 60)
                            .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .padding(.top, 30)
                    .fullScreenCover(isPresented: $showMenuModoLibre) {
                        MenuModoLibre()
                    }
                    .alert(isPresented: $showNoQuestionsLeftAlert) {
                        print("Showing No Questions Left Alert")
                        return Alert(
                            title: Text("Atención"),
                            message: Text("Congratulations champ, you've completed Single Mode. How about you try Competition Mode"),
                            dismissButton: .default(Text("OK"), action: {
                                print("Alert dismiss button tapped.") // Debugging print
                                dbHelper.resetShownQuestions()
                            })
                        )
                    }
                    
                    
                }
            }
        }
        .onAppear {
            print("ResultadoView appeared")
            handleAciertos()
            checkHighScore()
            let unusedQuestionsCount = dbHelper.getNumberOfUnusedQuestions()
                       print("Number of unused questions: \(unusedQuestionsCount)")
            
        }
        .navigationBarHidden(true)
        
    }
    
    struct ResultadoView_Previews: PreviewProvider {
        static var previews: some View {
            ResultadoView(aciertos: 8, puntuacion: 4000, errores: 2)
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

    private func checkHighScore() {
        let userDefaults = UserDefaults.standard
        let previousHighScore = userDefaults.integer(forKey: "HighScore")
        
        if puntuacion > previousHighScore {
            highScore = puntuacion
            isNewHighScore = true
            userDefaults.set(highScore, forKey: "HighScore")
          showAlert = true
        } else {
            highScore = previousHighScore
            isNewHighScore = false
        }
    }
    
    
    private func handleAciertos() {
        var audioFileName = ""
        var imageName = ""
        var textFieldText = ""
        
        if aciertos >= 9 {
            audioFileName = "expert.mp3"
            imageName = "expert"
            textFieldText = "FANTASTIC. WE NEED MORE (PAN)AFRICANS LIKE YOU"
        } else if aciertos >= 5 && aciertos <= 8 {
            audioFileName = "average.mp3"
            imageName = "average"
            textFieldText = "NOT BAD, BUT YOU COULD DO BETTER FOR THE CONTINENT"
        } else {
            audioFileName = "beginner.mp3"
            imageName = "beginer"
            textFieldText = "IT'S PEOPLE LIKE YOU HOLDING AFRICA BACK"
        }
        
        if let soundURL = Bundle.main.url(forResource: audioFileName, withExtension: nil) {
            do {
                self.player = try AVAudioPlayer(contentsOf: soundURL)
                self.player?.play()
            } catch {
                print("Could not create AVAudioPlayer: \(error)")
            }
        } else {
            print("Could not find URL for audio file: \(audioFileName)")
        }
        
        // Set the image and text based on the conditions
        self.imageName = imageName
        self.textFieldText = textFieldText
    }

}

