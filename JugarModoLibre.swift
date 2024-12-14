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
              Image("neon")
                  .resizable()
                  .edgesIgnoringSafeArea(.all)
              
              VStack(spacing: 5) {
                  // Score Section
                  HStack {
                      Text("CORRECT ANSWERS: \(quizState.score)")
                          .foregroundColor(.black)
                          .fontWeight(.bold)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .padding([.top, .leading], 20)
                  }
                  HStack {
                      Text("SCORE: \(quizState.totalScore)")
                          .foregroundColor(.black)
                          .fontWeight(.bold)
                          .padding(.leading, 21.0)
                          .frame(maxWidth: .infinity, alignment: .leading)
                  }
                  HStack {
                      Text("QUESTION: \(quizState.preguntaCounter)/\(quizState.randomQuestions.count)")
                          .foregroundColor(.black)
                          .fontWeight(.bold)
                          .padding(.leading, 20)
                          .frame(maxWidth: .infinity, alignment: .leading)
                  }
                  
                  Spacer()
                  
                  // Timer
                  HStack {
                      Spacer()
                      Text("\(quizState.timeRemaining)")
                          .foregroundColor(quizState.timeRemaining <= 5 ? Color(hue: 1.0, saturation: 0.984, brightness: 0.699) : .black)
                          .fontWeight(.bold)
                          .font(.system(size: 60))
                          .padding(.trailing, 20.0)
                          .shadow(color: .black, radius: 1, x: 1, y: 1)
                  }
                  .padding(.top, -250)
             // Logo under the timer
                  Image("logo")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 80, height: 80)
                      .padding(.top, -150)
                      .rotation3DEffect(
                              .degrees(rotationAngle),
                              axis: (x: 0, y: 1, z: 0) // Rotate along the Y-axis
                          )
                      

                  // Question text under the logo
                  Text(quizState.isAnswered ? quizState.answerStatusMessage : quizState.currentQuestion.question)
                      .foregroundColor(quizState.questionTextColor)
                      .font(.headline)
                      .padding(.horizontal, 20)
                      .padding(.top, -50)
                      .padding(.bottom, 20)
                     
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
                  .padding(.bottom, 200)
                  
                  // Action Button
                  Button(action: handleButtonTap) {
                      Text(quizState.buttonText)
                          .font(.headline)
                          .foregroundColor(.black)
                          .padding()
                          .frame(width: 300, height: 75)
                          .background(Color.white)
                          .cornerRadius(10)
                          .overlay(
                              RoundedRectangle(cornerRadius: 10)
                                  .stroke(Color.black, lineWidth: 3)
                          )
                  }
                  .padding(.top, -180)
                  .fullScreenCover(isPresented: $isShowingResultadoView) {
                      ResultadoView(aciertos: quizState.score, puntuacion: quizState.totalScore, errores: quizState.mistakes)
                  }
              }
              .padding(.horizontal, 12)
          }
          .onChange(of: scenePhase) { newPhase in
              if newPhase == .active && !quizState.isAnswered && !quizState.hasBeenPenalized {
                  activeAlert = .resumeWarning // Show the alert
              } else if newPhase == .active && quizState.hasBeenPenalized {
                  print("User returned after already being penalized. No further action.")
              }
          }
          .onAppear {
              quizState.startCountdownTimer()
          }
          .alert(item: $activeAlert) { alert in
              switch alert {
              case .noSelection:
                  resetSoundFlag() // Reset sound flag when alert is triggered
                  return Alert(
                      title: Text("WARNING"),
                      message: Text("Fear not, make a choice"),
                      dismissButton: .default(Text("OK"))
                  )
              case .resumeWarning:
                  resetSoundFlag() // Reset sound flag when alert is triggered
                  return Alert(
                      title: Text("Attention!"),
                      message: Text("Don't leave the app while the timer is running. You will be penalized."),
                      dismissButton: .default(Text("OK")) {
                          quizState.penalizeForLeavingApp()
                      }
                  )
              }
          }
          .onChange(of: activeAlert) { newAlert in
              if let _ = newAlert, !hasPlayedSoundForAlert {
                  SoundManager.shared.playWarningSound()
                  hasPlayedSoundForAlert = true // Mark sound as played
              }
          }
      }

      // Reset the sound flag whenever a new alert is triggered
      private func resetSoundFlag() {
          hasPlayedSoundForAlert = false
      }
    
    private func flipImage() {
        withAnimation(.easeInOut(duration: 0.6)) {
            rotationAngle += 360 // Rotate the image by 360 degrees
        }
    }

      // MARK: - Handle Button Tap
      private func handleButtonTap() {
          switch quizState.buttonText {
          case "CONFIRM":
              if quizState.selectedOptionIndex == -1 {
                  print("No option selected, showing alert.")
                  activeAlert = .noSelection // Show the no selection alert
                  return
              }
              quizState.checkAnswer()
              quizState.buttonText = "NEXT"
          case "NEXT":
              SoundManager.shared.playSoundEffect(quizState.swooshSoundEffect, name: "Swoosh")
              if quizState.currentQuestionIndex < quizState.randomQuestions.count - 1 {
                  flipImage()
                  quizState.showNextQuestion()
              } else {
                  quizState.finishQuiz()
                  isShowingResultadoView = true
              }
          case "FINISH":
              quizState.finishQuiz()
              isShowingResultadoView = true
          default:
              break
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
                print("Selected option index is now \(self.selectedOptionIndex)")
            }) {
                Text(text.uppercased())
                    .font(.headline)
                    .foregroundColor(.white)  // White text for better contrast
                    .padding()
                    .frame(width: 300, height: 75)
                    .background(backgroundForOption())
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
                    startFlashing()
                } else {
                    stopFlashing()
                }
            }
        }

        private func backgroundForOption() -> Color {
            if selectedOptionIndex == optionIndex {
                return Color(hue: 0.315, saturation: 0.953, brightness: 0.335)  // Green when selected
            } else {
                return Color(hue: 0.69, saturation: 0.89, brightness: 0.706)  // Default blue background
            }
        }
        
        private func startFlashing() {
            guard !isFlashing else { return }
            isFlashing = true
            flashCount = 6  // Set the desired number of flashes

            // After flashes are complete, reset isFlashing
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {  // 3 seconds, adjust as needed
                self.isFlashing = false
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
                startFlashing()
            } else {
                stopFlashing()
            }
        }
    }



