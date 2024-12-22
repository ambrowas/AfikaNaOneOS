
import SwiftUI
import AVFoundation
import Combine
import FirebaseAuth
import FirebaseStorage



    struct JugarModoCompeticion: View {
        @StateObject private var viewModel: JugarModoCompeticionViewModel
        @State private var showAlert = false
        @State private var hasShownManyMistakesAlert = false
        @State private var navigationTag: Int? = nil
        @State private var userId: String = ""
        @ObservedObject private var userData: UserData
        @State private var shouldPresentGameOver: Bool = false
        @Environment(\.presentationMode) var presentationMode
        @State private var isAlertBeingDisplayed = false
        @State private var showAnswerStatus = false
        @State private var scale: CGFloat = 1.0
        @State private var isGrowing = true
        @State private var showAnswerStatusForMistakes: Bool = false
        let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        private var timerCancellable: AnyCancellable?

        enum ActiveAlert: Identifiable {
            case showAlert, showEndGameAlert, showGameOverAlert, showManyMistakesAlert, showReturnToAppAlert, showTimeIsUpAlert

            var id: Int {
                switch self {
                case .showAlert:
                    return 0
                case .showEndGameAlert:
                    return 1
                case .showGameOverAlert:
                    return 2
                case .showManyMistakesAlert:
                    return 3
                case .showReturnToAppAlert:
                    return 4
                case .showTimeIsUpAlert:
                    return 5
                }
            }
        }

        init(userId: String, userData: UserData) {
            _viewModel = StateObject(wrappedValue: JugarModoCompeticionViewModel(userId: userId, userData: userData))
            self.userData = userData
        }

        var body: some View {
            ZStack {
                Image("competicion")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Score Section
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                                Text("CORRECT ANSWERS:")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16)) // Explicit font size
                                    .fontWeight(.bold)
                                    .lineLimit(1) // Prevent wrapping
                                    .minimumScaleFactor(0.7) // Scale down text if needed
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(width: 180, alignment: .leading)

                                Text("WRONG ANSWERS:")
                                    .foregroundColor(viewModel.mistakes >= 4 ? Color.red : .black)
                                    .font(.system(size: 16)) // Explicit font size
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("SCORE:")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16)) // Explicit font size
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(alignment: .trailing, spacing: 5) {
                                Text("\(viewModel.score)")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text("\(viewModel.mistakes)")
                                    .foregroundColor(viewModel.mistakes >= 4 ? .red : .black)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text("\(viewModel.totalScore)")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)

                            Spacer()

                            // Timer Display
                            Text("\(viewModel.timeRemaining)")
                            .foregroundColor(viewModel.timeRemaining <= 10
                            ? Color(hue: 1.0, saturation: 0.984, brightness: 0.699) // Custom Red
                                : .black) // Default color
                                .font(.system(size: 60))
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 80, alignment: .center) // Fixed width to prevent movement
                                .padding(.trailing, 20)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                        }
                    // Icon, Category, and Question Section
                    if !viewModel.answerChecked {
                        VStack(spacing: 10) {
                            // Display the category
                            if let category = viewModel.currentQuestion?.category, !category.isEmpty {
                                Text(category.uppercased())
                                    .font(.headline)
                                    .foregroundColor(Color(hue: 0.664, saturation: 0.935, brightness: 0.604)) // Style as needed
                                    .padding(.bottom, 10)
                            }

                            // Display the icon/image
                            if let imageUrl = viewModel.currentQuestion?.image, !imageUrl.isEmpty {
                                if imageUrl.starts(with: "http") {
                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 80, height: 80)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 80, height: 80)
                                        case .failure:
                                            Image("logo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 80, height: 80)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else if imageUrl.starts(with: "gs://") {
                                    Image("logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .onAppear {
                                            // Resolve Firebase Storage URL
                                            let storageRef = Storage.storage().reference(forURL: imageUrl)
                                            storageRef.downloadURL { url, error in
                                                if let url = url {
                                                    print("Resolved Firebase URL: \(url)")
                                                    DispatchQueue.main.async {
                                                        viewModel.currentQuestion?.image = url.absoluteString
                                                    }
                                                } else {
                                                    print("Failed to resolve Firebase URL: \(error?.localizedDescription ?? "Unknown error")")
                                                }
                                            }
                                        }
                                } else {
                                    Image("logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                }
                            }

                            // Display the question text
                            Text(viewModel.currentQuestion?.questionText ?? "Loading question...")
                                .foregroundColor(.black)
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    } else {
                        // Show feedback for correct/incorrect answer
                        let answerStatus = viewModel.answerIsCorrect ?? false
                        Image(systemName: answerStatus ? "checkmark" : "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(answerStatus
                                ? Color(hue: 0.315, saturation: 0.953, brightness: 0.335) // Green for correct
                                : Color(hue: 1.0, saturation: 0.984, brightness: 0.699)) // Red for wrong
                            .frame(width: 120, height: 120)
                            .scaleEffect(viewModel.scale)
                            .onAppear {
                                viewModel.startGrowShrinkAnimation()
                            }
                            .onDisappear {
                                viewModel.stopGrowShrinkAnimation()
                            }
                            .transition(.opacity)
                    }
                    // Options Section
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.options.indices, id: \.self) { index in
                            Button(action: {
                                if !viewModel.questionProcessed {
                                    viewModel.selectedOptionIndex = index
                                    viewModel.resetButtonColors()
                                    viewModel.buttonBackgroundColors[index] = Color(hue: 0.315, saturation: 0.953, brightness: 0.335)
                                }
                            }) {
                                Text(viewModel.options[index])
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 300, height: 75)
                                    .background(viewModel.buttonBackgroundColors.indices.contains(index) ? viewModel.buttonBackgroundColors[index] : Color.clear)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                            }
                        }
                    }

                    // Action Buttons Section
                    VStack(spacing: 10) {
                        Button(action: {
                            if viewModel.buttonConfirmar == "CONFIRM" {
                                if viewModel.selectedOptionIndex == nil {
                                    viewModel.activeAlert = .showAlert
                                    viewModel.triggerMakeAChoiceAlert()
                                } else {
                                    viewModel.checkAnswer()
                                    showAnswerStatus = true
                                    viewModel.handleAlerts()
                                }
                            } else if viewModel.buttonConfirmar == "NEXT" {
                                viewModel.playSwooshSound()
                                showAnswerStatus = false
                                viewModel.questionProcessed = false
                                viewModel.fetchNextQuestion()
                                viewModel.answerChecked = false
                            }
                        }) {
                            Text(viewModel.buttonConfirmar)
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

                        if viewModel.buttonConfirmar == "NEXT" {
                            Button(action: {
                                viewModel.triggerEndGameAlert()
                            }) {
                                Text("FINISH")
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
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIApplication.didEnterBackgroundNotification,
                    object: nil, queue: .main) { _ in
                        viewModel.appMovedToBackground()
                }

                NotificationCenter.default.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil, queue: .main) { _ in
                        viewModel.appReturnsToForeground()
                }

                viewModel.setButtons()
                viewModel.fetchNextQuestion()
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .alert(item: $viewModel.activeAlert) { item -> Alert in
                switch item {
                case .showAlert:
                    return Alert(
                        title: Text("ATTENTION"),
                        message: Text("Fear not, make a choice"),
                        dismissButton: .default(Text("OK")) {
                            viewModel.isAlertBeingDisplayed = false // Reset after dismissal
                        }
                    )

                case .showEndGameAlert:
                    return Alert(
                        title: Text("JUST CHECKING"),
                        message: Text("Sure you want to end the game?"),
                        primaryButton: .destructive(Text("YEP")) {
                            viewModel.terminar(navigateToResults: true) {
                                SoundManager.shared.playMagicalSound()
                                print("Voluntary termination: Navigating to results.")
                            }
                        },
                        secondaryButton: .cancel(Text("NOPE")) {
                            viewModel.isAlertBeingDisplayed = false
                        }
                    )

                case .showGameOverAlert:
                    return Alert(
                        title: Text("GAME OVER"),
                        message: Text("That's it. Five mistakes. You're done."),
                        dismissButton: .default(Text("OK")) {
                            viewModel.terminar {
                                shouldPresentGameOver = true
                            }
                        }
                    )

                case .showManyMistakesAlert:
                    return Alert(
                        title: Text("WATCH OUT"),
                        message: Text("You're on your fourth error. One more and you're done."),
                        dismissButton: .default(Text("OK")) {
                            viewModel.isAlertBeingDisplayed = false
                        }
                    )

                case .showReturnToAppAlert:
                    return Alert(
                        title: Text("WARNING"),
                        message: Text("Do not leave the app while the timer is running. You will be penalized."),
                        dismissButton: .default(Text("OK")) {
                            viewModel.penalizeForLeavingApp() // Apply penalty
                            viewModel.isAlertBeingDisplayed = false // Reset alert state
                        }
                    )

                case .showTimeIsUpAlert:
                    return Alert(
                        title: Text("TIME'S UP"),
                        message: Text("You ran out of time."),
                        dismissButton: .default(Text("OK")) {
                            viewModel.penalizeForTimeExpiry()
                            viewModel.isAlertBeingDisplayed = false
                        }
                    )
                }
            }
            
            .fullScreenCover(isPresented: $viewModel.shouldNavigateToResults) {
                ResultadoCompeticion(userId: userId)
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
                    .fullScreenCover(isPresented: $shouldPresentGameOver){
                        GameOver(userId: userId)
                            .onDisappear{
                                presentationMode.wrappedValue.dismiss()
                            }
                    }
                    .onChange(of: viewModel.activeAlert) { newAlert in
                        if newAlert == nil {
                            print("Alert dismissed, resetting isAlertBeingDisplayed.")
                            viewModel.isAlertBeingDisplayed = false
                        }
                    }
                    .onDisappear {
                        NotificationCenter.default.removeObserver(
                            self,
                            name: UIApplication.didEnterBackgroundNotification,
                            object: nil
                        )
                        NotificationCenter.default.removeObserver(
                            self,
                            name: UIApplication.willEnterForegroundNotification,
                            object: nil
                        )
                    }

                    .onReceive(viewModel.timeExpired, perform: { newValue in
                        showAnswerStatusForMistakes = newValue
                        
                    })
                    
                }
            }

    struct GameOverPresented: Identifiable {
        var id = UUID() // changes
    }
    
    struct JugarModoCompeticion_Previews: PreviewProvider {
        static var previews: some View {
            JugarModoCompeticion(userId: "DummyuserId", userData: UserData())
        }
    }

struct IconView: View {
    @Binding var categoryImage: String
    @State private var downloadedImage: UIImage? = nil
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if let downloadedImage = downloadedImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            } else if isLoading {
                ProgressView()
            } else {
                Image("logo") // Default fallback
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
        }
        .onAppear {
            fetchImage()
        }
        .onChange(of: categoryImage) { newValue in
            print("IconView received new image URL: \(newValue)")
            fetchImage() // Fetch the new image when categoryImage changes
        }
    }

    private func fetchImage() {
        print("fetchImage called with categoryImage: \(categoryImage)")

        isLoading = true
        guard !categoryImage.isEmpty else {
            print("Category image is empty.")
            isLoading = false
            return
        }

        guard categoryImage.starts(with: "gs://") else {
            if let url = URL(string: categoryImage) {
                print("Downloading image from URL: \(url)")
                downloadImage(from: url)
            } else {
                print("Invalid URL: \(categoryImage)")
                isLoading = false
            }
            return
        }

        print("Fetching Firebase Storage URL for: \(categoryImage)")
        let storageRef = Storage.storage().reference(forURL: categoryImage)
        storageRef.downloadURL { url, error in
            if let url = url {
                print("Fetched download URL: \(url)")
                self.downloadImage(from: url)
            } else {
                print("Failed to fetch download URL: \(error?.localizedDescription ?? "Unknown error")")
                self.isLoading = false
            }
        }
    }

    private func downloadImage(from url: URL) {
        print("Downloading image from: \(url)")
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("Image downloaded successfully.")
                    self.downloadedImage = image
                    self.isLoading = false
                }
            } else {
                print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
