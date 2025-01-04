import SwiftUI
import AVFAudio



struct JugarModoLibre: View {
    @StateObject private var quizState = QuizState()
    @State private var isShowingResultadoView = false
    @Binding var player: AVAudioPlayer?
    @Environment(\.scenePhase) private var scenePhase
    @State private var activeAlert: ActiveAlert? // Local state to manage alerts
    @State private var hasPlayedSoundForAlert = false // Tracks if sound has been played
    @State private var rotationAngle: Double = 0
    @State private var isConfirmed: Bool = false // New state variable to track if "CONFIRM" is
    var shouldFlashConfirm = false // Tracks if CONFIRM should flashpressed
    @State private var scale: CGFloat = 1.0
    @State private var finishButtonTiltAngle: Double = 0 // 🔄 Tracks tilt rotation
    @State private var shouldTiltFinish = false // ✅ Ensures tilt runs once
   
    // Enum for alerts
    enum ActiveAlert: Identifiable {
        case noSelection
        case resumeWarning

        var id: String {
            switch self {
            case .noSelection: return "noSelection"
            case .resumeWarning: return "resumeWarning"
            }
        }
    }

    init(player: Binding<AVAudioPlayer?>) {
        _player = player
    }

    var body: some View {
        ZStack {
            // Background Image
            Image("libre")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 5) {
                // Score Section with Timer
                HStack {
                    // Left-aligned Score Texts
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CORRECT ANSWERS: \(quizState.score)")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                        Text("SCORE: \(quizState.totalScore)")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                        Text("QUESTION: \(quizState.preguntaCounter)/\(quizState.randomQuestions.count)")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .padding(.leading, 10)
                    
                    Spacer() // Pushes the timer to the right
                    
                    // Timer Section
                    Text("\(quizState.timeRemaining)")
                        .foregroundColor(quizState.timeRemaining <= 5
                                ? Color(red: 84/255, green: 8/255, blue: 4/255)
                                : .black)
                        .fontWeight(.bold)
                        .font(.system(size: 60))
                        .padding(.trailing, 20)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
              
              
                
                // Logo Under Timer
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 1, y: 0, z: 0) // ✅ Rotate along the X-axis instead of Y-axis
                    )
                
                // Question Text Section
                Text(quizState.isAnswered ? quizState.answerStatusMessage : quizState.currentQuestion.question)
                    .foregroundColor(quizState.questionTextColor)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Conditional Section for Radio Buttons or Explanation
                VStack {
                    if !isConfirmed {
                        // Options Section
                        VStack(alignment: .leading, spacing: 10) {
                            let optionValues = Array(quizState.currentQuestion.options.values)
                            ForEach(0..<optionValues.count, id: \.self) { index in
                                RadioButton(
                                    text: optionValues[index],
                                    selectedOptionIndex: $quizState.selectedOptionIndex,
                                    optionIndex: index,
                                    quizState: quizState
                                )
                            }
                        }
                        .frame(height: 200) // Fixed height for radio buttons
                    } else {
                        // Explanation Section
                        Text(quizState.currentQuestion.explanation)
                            .foregroundColor(.black)
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .frame(height: 200) // Fixed height for explanation
                    }
                }
                .padding(.bottom, 200) // Maintain consistent padding
                Button(action: {
                    handleButtonTap() // ✅ Handles all button logic
                }) {
                    Text(quizState.buttonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .scaleEffect(quizState.shouldFlashConfirm && quizState.buttonText == "CONFIRM" ? quizState.scale : 1.0) // ✅ Flash only CONFIRM
                        .opacity(quizState.shouldFlashConfirm && quizState.buttonText == "CONFIRM" ? 0.5 : 1.0) // ✅ Flash only CONFIRM
                        .rotationEffect(.degrees(quizState.shouldTiltFinish && quizState.buttonText == "FINISH" ? quizState.finishButtonTiltAngle : 0)) // ✅ Tilt only FINISH
                        .animation(quizState.shouldFlashConfirm && quizState.buttonText == "CONFIRM" ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : nil, value: quizState.shouldFlashConfirm)
                }
                              .padding(.top, -120)
                              .fullScreenCover(isPresented: $isShowingResultadoView) {
                                  ResultadoView(aciertos: quizState.score, puntuacion: quizState.totalScore, errores: quizState.mistakes)
                              }
                          }
                          .padding(.horizontal, 12)
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            quizState.startCountdownTimer()
        }
        .alert(item: $activeAlert) { alert in
            alertView(for: alert)
        }
        .onChange(of: activeAlert) { newAlert in
            handleAlertSound(for: newAlert)
        }
    }

    // MARK: - Helper Methods
    

    private func resetSoundFlag() {
        hasPlayedSoundForAlert = false
    }

    private func flipImage() {
        withAnimation(.easeInOut(duration: 0.6)) {
            rotationAngle += 360 // ✅ Keep full rotation
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active && !quizState.isAnswered && !quizState.hasBeenPenalized {
            activeAlert = .resumeWarning // Show the alert
        } else if newPhase == .active && quizState.hasBeenPenalized {
            //print("User returned after already being penalized. No further action.")
        }
    }

    private func handleButtonTap() {
        switch quizState.buttonText {
        case "CONFIRM":
            if quizState.selectedOptionIndex == -1 {
                print("No option selected, showing alert.")
                activeAlert = .noSelection
                return
            }
            quizState.checkAnswer()
            quizState.shouldFlashConfirm = false // ✅ STOP FLASHING ON CONFIRM PRESS
            quizState.scale = 1.0 // ✅ RESET SCALE
            quizState.buttonText = quizState.isLastQuestion ? "FINISH" : "NEXT"
            isConfirmed = true // Show explanation

            if quizState.buttonText == "FINISH" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    quizState.tiltFinishButton() // ✅ Start tilting "FINISH"
                }
            }

        case "NEXT":
            SoundManager.shared.playTransitionSound()
            flipImage()
            quizState.shouldFlashConfirm = false // ✅ STOP FLASHING ON NEXT
            quizState.scale = 1.0 // ✅ RESET SCALE

            if quizState.currentQuestionIndex < quizState.randomQuestions.count - 1 {
                quizState.showNextQuestion()
                isConfirmed = false
            } else {
                quizState.buttonText = "FINISH"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    quizState.tiltFinishButton() // ✅ Start tilting "FINISH"
                }
            }

        case "FINISH":
            quizState.shouldFlashConfirm = false // ✅ STOP FLASHING
            quizState.scale = 1.0 // ✅ RESET SCALE
            quizState.shouldTiltFinish = false // ✅ STOP TILTING
            withAnimation(.easeOut(duration: 0.3)) {
                quizState.finishButtonTiltAngle = 0 // ✅ RESET TILT TO 0
            }
            quizState.finishQuiz()
            isShowingResultadoView = true

            default:
                print("Unhandled button text: \(quizState.buttonText)")
        }
    }

    private func handleAlertSound(for alert: ActiveAlert?) {
        if alert != nil, !hasPlayedSoundForAlert {
            SoundManager.shared.playWarningSound()
            hasPlayedSoundForAlert = true // Mark sound as played
        }
    }
    
    private func alertView(for alert: ActiveAlert) -> Alert {
        resetSoundFlag() // Ensure the sound can be played again when the alert appears
        switch alert {
        case .noSelection:
            return Alert(
                title: Text("WARNING"),
                message: Text("Fear not, make a choice"),
                dismissButton: .default(Text("OK")) {
                    resetSoundFlag() // Reset sound flag on dismissal
                }
            )
        case .resumeWarning:
            return Alert(
                title: Text("Attention!"),
                message: Text("Don't leave the app while the timer is running. You will be penalized."),
                dismissButton: .default(Text("OK")) {
                    quizState.penalizeForLeavingApp()
                    resetSoundFlag() // Reset sound flag on dismissal
                }
            )
        }
    }
}

struct JugarModoLibre_Previews: PreviewProvider {
    @State static var mockPlayer: AVAudioPlayer? = nil // Provide a mock AVAudioPlayer

    static var previews: some View {
        JugarModoLibre(player: $mockPlayer)
            .previewDevice("iPhone 13") // Specify a device for the preview
    }
}

struct RadioButton: View {
    var text: String
    @Binding var selectedOptionIndex: Int
    var optionIndex: Int
    @ObservedObject var quizState: QuizState
    @State private var isFlashing = false
    @State private var flashCount = 0  // To manage the number of flashes

    var body: some View {
        Button(action: {
            self.selectedOptionIndex = self.optionIndex
            quizState.shouldFlashConfirm = true
            quizState.startFlashingConfirmButton()
        }) {
            Text(text.uppercased())
                .font(.headline)
                .foregroundColor(.white)  // White text for better contrast
                .padding()
                .frame(width: 300, height: 75)
                .background(backgroundForOption()) // Updated colors
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
        }
        .opacity(isFlashing ? 0.5 : 1) // Apply flashing effect
        .animation(isFlashing ? Animation.easeInOut(duration: 0.5).repeatCount(6, autoreverses: true) : nil, value: isFlashing)
        .onChange(of: selectedOptionIndex) { _ in
            updateFlashing()
        }
        .onAppear {
            stopFlashing()
        }
        .onReceive(quizState.$shouldFlashCorrectAnswer) { shouldFlash in
            if shouldFlash && shouldFlashCondition {
                quizState.startFlashingConfirmButton()
            } else {
                stopFlashing()
            }
        }
    }
    
    

    // **Updated Background Colors**
    private func backgroundForOption() -> Color {
        if selectedOptionIndex == optionIndex {
            return Color(red: 84/255, green: 8/255, blue: 4/255)  // **Selected: #540804**
        } else {
            return Color(red: 88/255, green: 81/255, blue: 35/255)  // **Normal: #585123**
        }
    }
    
    
    private var shouldFlashCondition: Bool {
        guard let correctAnswerKey = quizState.currentQuestion.correctAnswerKey else {
            print("Error: Correct answer key is missing.")
            return false
        }

        guard quizState.selectedOptionIndex >= 0 else {
            print("No option selected. Flashing condition not met.")
            return false // Return false directly for no selection
        }

        let optionKeys = Array(quizState.currentQuestion.options.keys)
        guard quizState.selectedOptionIndex < optionKeys.count else {
            print("Error: selectedOptionIndex (\(quizState.selectedOptionIndex)) is out of bounds.")
            return false
        }

        let selectedOptionKey = optionKeys[quizState.selectedOptionIndex]
        return selectedOptionKey == correctAnswerKey && quizState.selectedIncorrectAnswer
    }
    
    private func stopFlashing() {
        isFlashing = false
        flashCount = 0
    }
    
    private func updateFlashing() {
        if shouldFlashCondition {
            quizState.startFlashingConfirmButton()
        } else {
            stopFlashing()
        }
    }
}

// **Confirm/Next Button**
struct ConfirmNextButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("NEXT")
                .font(.headline)
                .padding()
                .frame(width: 200, height: 50)
                .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // **#797D62**
                .cornerRadius(10)
        }
    }
}

