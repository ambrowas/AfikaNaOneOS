import SwiftUI
import Combine
import AVFoundation

class QuizState: ObservableObject {
    let  dbHelper = QuizDBHelper.shared
    var randomQuestions: [QuizQuestion]
    private var rightSoundEffect: AVAudioPlayer?
    private var wrongSoundEffect: AVAudioPlayer?
    private var countdownSound: AVAudioPlayer?
    private var timer: Timer? // Declare timer here
    @Published var showAlert = false
    @Published var alertMessage = "Atención"
    @Published var currentQuestionIndex = 0
    @Published var selectedOptionIndex = -1
    @Published var timeRemaining = 15
    @Published var isAnswered = false
    @Published var score = 0
    @Published var totalScore = 0
    @Published var preguntaCounter = 1
    @Published var isShowingResultadoView = false
    @Published var buttonText = "CONFIRM"
    @Published var displayMessage = "Fear not, make a choice"
    @Published var isOptionSelected = false
    @Published var mistakes = 0
    @Published var answerIsCorrect: Bool? = nil
    @Published var isQuizCompleted = false
    @Published var selectedIncorrectAnswer = false
    @Published var questionTextColor = Color.black
    @Published var shouldFlashCorrectAnswer = false
    @Binding var player: AVAudioPlayer?
    @Published var selectedAnswerIsIncorrect = false
    @Published var resetFlashingSignal = false
    @Published var answerStatusMessage: String = ""
    @Published var questionsShownCount = 0
    @Published var hasBeenPenalized: Bool = false
    @Published var activeAlert: ActiveAlert?
    var swooshSoundEffect: AVAudioPlayer?
    @Published var hasPlayedSoundForAlert = false
    

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
    
    init(player: Binding<AVAudioPlayer?> = .constant(nil)) {
        self._player = player
        self.randomQuestions = dbHelper.getRandomQuestions(count: 10) ?? []
        loadSoundEffects(player: player)
        print("Fetched \(randomQuestions.count) random questions.")
    }

    init(player: Binding<AVAudioPlayer?>? = nil) {
        self._player = player ?? .constant(nil) // Provide a default Binding
        self.randomQuestions = dbHelper.getRandomQuestions(count: 10) ?? []
        self.rightSoundEffect = nil
        self.wrongSoundEffect = nil
        self.countdownSound = nil
        self.timer = nil
        self.currentQuestionIndex = 0
        self.selectedOptionIndex = -1
        self.timeRemaining = 15
        self.isAnswered = false
        self.score = 0
        self.totalScore = 0
        self.preguntaCounter = 1
        self.buttonText = "CONFIRM"
        self.answerStatusMessage = ""
        self.mistakes = 0
        self.hasBeenPenalized = false
        self.questionTextColor = Color.black
        self.activeAlert = nil

        print("Fetched \(randomQuestions.count) random questions.")
    }
     var isLastQuestion: Bool {
         currentQuestionIndex >= randomQuestions.count - 1
     }

     var currentQuestion: QuizQuestion {
         randomQuestions[currentQuestionIndex]
     }
    
    func startCountdownTimer() {
        timer?.invalidate() // Stop any existing timer
        if currentQuestionIndex < randomQuestions.count {
            timeRemaining = 15
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    // Play countdown sound for the last 5 seconds
                    if (1...5).contains(self.timeRemaining) {
                        DispatchQueue.main.async {
                            self.playCountdownSound()
                        }
                    }
                } else {
                    // Timer expired
                    self.timer?.invalidate()
                    self.timer = nil
                    self.handleTimeout()
                }
            }
        }
    }
    
    private func handleTimeout() {
        guard !isAnswered else { return }
        print("Handling timeout for question.")

        // Stop the timer
        timer?.invalidate()
        timer = nil

        // Mark question as incorrect
        mistakes += 1
        wrongSoundEffect?.play()
        answerStatusMessage = "SORRY, YOUR TIME IS UP!"
        questionTextColor = Color(hue: 1.0, saturation: 0.984, brightness: 0.699)
        buttonText = "NEXT"
        isAnswered = true

        print("Timeout handled. Mistakes: \(mistakes). Question text color updated to dark red.")
    }
    
    func checkAnswer(isTimeout: Bool = false) {
        guard !isAnswered else { return }
        isAnswered = true
        timer?.invalidate()

        if isTimeout {
            handleTimeout()
            return
        }

        if selectedOptionIndex == -1 { // No selection case
            print("No option selected, triggering alert.")
            activeAlert = .noSelection // Trigger the alert
            return
        }

        // Proceed with answer validation
        let currentQuestion = randomQuestions[currentQuestionIndex]
        let optionKeys = Array(currentQuestion.options.keys)
        guard selectedOptionIndex >= 0, selectedOptionIndex < optionKeys.count else {
            print("Error: selectedOptionIndex (\(selectedOptionIndex)) is out of bounds.")
            return
        }

        let selectedOptionKey = optionKeys[selectedOptionIndex]
        guard let correctKey = currentQuestion.correctAnswerKey else {
            print("Error: Correct answer key is missing for question ID \(currentQuestion.id).")
            return
        }

        print("Question ID: \(currentQuestion.id), Selected Option Key: \(selectedOptionKey), Correct Option Key: \(correctKey)")

        if selectedOptionKey == correctKey {
            handleCorrectAnswer()
        } else {
            handleIncorrectAnswer()
        }

        // Check if this is the last question
        buttonText = currentQuestionIndex == randomQuestions.count - 1 ? "FINISH" : "NEXT"
    }
   
    func handleTimerExpiry() {
        print("Timer expired. Marking question as incorrect.")

        // Mark the current question as incorrect due to timeout
        handleIncorrectAnswer(isTimeout: true)

        // Move to the next question or finish the quiz
        if currentQuestionIndex < randomQuestions.count - 1 {
            showNextQuestion()
        } else {
            finishQuiz()
        }
    }
    
    func playCountdownSound() {
        countdownSound?.play()
    }
   
    private func handleCorrectAnswer() {
        score += 1
        totalScore += 500
        rightSoundEffect?.play()
        print("Played correct sound.") // Debugging log
        answerStatusMessage = "YEP, YOU'RE RIGHT"
        answerIsCorrect = true
        selectedIncorrectAnswer = false
        questionTextColor = Color(hue: 0.315, saturation: 0.953, brightness: 0.335) // Green for correct
        print("Correct answer handled. Text color updated to green.")
    }
    
    func handleIncorrectAnswer(isTimeout: Bool = false) {
        mistakes += 1
        wrongSoundEffect?.play()
        print("Played incorrect sound.") // Debugging log
        answerStatusMessage = isTimeout ? "SORRY, YOUR TIME IS UP!" : "NOPE, THAT'S NOT IT"
        answerIsCorrect = false
        selectedIncorrectAnswer = true
        shouldFlashCorrectAnswer = true
        questionTextColor =  Color(hue: 1.0, saturation: 0.984, brightness: 0.699) // Dark red for both
        print("Mistake count updated to \(mistakes). Timeout: \(isTimeout). Text color updated to dark red.")
    }
   
    func penalizeForLeavingApp() {
          guard !isAnswered else { return }
          guard !hasBeenPenalized else { return }
          
          print("Penalizing for leaving the app.")
          timer?.invalidate()
          timer = nil
          mistakes += 1
          wrongSoundEffect?.play()
          answerStatusMessage = "PENALTY FOR LEAVING."
          questionTextColor = .red
          buttonText = "NEXT"
          isAnswered = true
          hasBeenPenalized = true
      }

    private func updateButtonTextForNextAction() {
        buttonText = preguntaCounter < randomQuestions.count ? "NEXT" : "FINISH"
    }
    
    private func updateButtonTextPostAnswer() {
        if preguntaCounter >= 10 {
            buttonText = "FINISH"
        } else {
            buttonText = "NEXT"
        }
    }
    
    func showNextQuestion() {
           guard currentQuestionIndex < randomQuestions.count - 1 else {
               print("No more questions. Completing the quiz.")
               return
           }

           currentQuestionIndex += 1
           selectedOptionIndex = -1
           preguntaCounter = currentQuestionIndex + 1
           isAnswered = false
           hasBeenPenalized = false
           answerStatusMessage = ""
           questionTextColor = .black
           buttonText = "CONFIRM"
            hasPlayedSoundForAlert = false
           startCountdownTimer()

           print("Moved to question \(preguntaCounter).")
       }
   
    private func resetForNewQuestion() {
        timeRemaining = 15
        answerIsCorrect = nil
        buttonText = "CONFIRM"
        startCountdownTimer()
        selectedIncorrectAnswer = false
        shouldFlashCorrectAnswer = false
        questionTextColor = Color.black
    
    }
    
    private func showAlertCompletedQuestions() {
        print("All questions completed. Showing completion alert.")
        alertMessage = "ATTENTION"
        displayMessage = "Congrats champ. You have completed the Single Mode. U should try Competition Mode"
        showAlert = true
    }
 
    func handleAppLeftDuringQuestion() {
        guard !isAnswered else { return } // Do nothing if the question is already answered

        print("App left during the question. Penalizing the user.")

        // Mark the question as incorrect for leaving the app
        handleIncorrectAnswer(isTimeout: true)

        // Set the button text to "NEXT" instead of moving to the next question
        updateButtonTextPostAnswer()
    }

    func finishQuiz() {
        let aciertos = score
        let errores = mistakes
        totalScore = aciertos * 500 // Remove penalty for mistakes

        // Save the results to UserDefaults
        UserDefaults.standard.set(aciertos, forKey: "aciertos")
        UserDefaults.standard.set(totalScore, forKey: "puntuacion")
        UserDefaults.standard.set(errores, forKey: "errores")
        isQuizCompleted = true

        // Mark questions as shown
        let roundQuestionIDs = randomQuestions.map { $0.id }
        QuizDBHelper.shared.markQuestionsAsShown(with: roundQuestionIDs)

        print("Quiz finished. Correct Answers: \(aciertos), Total Score: \(totalScore), Mistakes: \(errores), Quiz Completed: \(isQuizCompleted)")
    }

    private func loadSoundEffects(player: Binding<AVAudioPlayer?>) {
        rightSoundEffect = loadSoundEffect(named: "right")
        wrongSoundEffect = loadSoundEffect(named: "notright")
        countdownSound = loadSoundEffect(named: "countdown")
        swooshSoundEffect = loadSoundEffect(named: "swoosh")
        self.player = player.wrappedValue
    }

    private func loadSoundEffect(named name: String) -> AVAudioPlayer? {
        if let path = Bundle.main.path(forResource: name, ofType: "wav") {
            let url = URL(fileURLWithPath: path)
            do {
                let soundEffect = try AVAudioPlayer(contentsOf: url)
                soundEffect.prepareToPlay()
                print("\(name).wav loaded successfully.") // Debugging log
                return soundEffect
            } catch {
                print("Error loading sound effect \(name): \(error.localizedDescription)")
            }
        } else {
            print("Sound file \(name).wav not found in bundle.") // Debugging log
        }
        return nil
    }

    private func prepareCountdownSound() {
        guard let url = Bundle.main.url(forResource: "countdown", withExtension: "wav") else {
            fatalError("Countdown sound file not found")
        }
        do {
            countdownSound = try AVAudioPlayer(contentsOf: url)
            countdownSound?.prepareToPlay()
        } catch {
            print("Failed to prepare countdown sound: \(error)")
        }
    }

    private func showAlertForNoSelection() {
        showAlert = true
    }
}

