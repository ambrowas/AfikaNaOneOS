
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
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Score Section
                HStack {
                    VStack(alignment: .leading) {
                        Text("CORRECT ANSWERS:")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                        Text("WRONG ANSWERS:")
                            .foregroundColor(viewModel.mistakes >= 4 ? Color(hue: 1.0, saturation: 0.984, brightness: 0.699) : .black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                        Text("SCORE:")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                    }
                    VStack(alignment: .leading) {
                        Text("\(viewModel.score)")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                        Text("\(viewModel.mistakes)")
                            .foregroundColor(viewModel.mistakes >= 4 ? Color(hue: 1.0, saturation: 0.984, brightness: 0.699) : .black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                        Text("\(viewModel.totalScore)")
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                    }
                    Spacer()
                    Text("\(viewModel.timeRemaining)")
                        .foregroundColor(viewModel.timeRemaining <= 10 ? Color(hue: 1.0, saturation: 0.984, brightness: 0.699) : .black)
                        .fontWeight(.bold)
                        .font(.system(size: 60))
                        .padding(.trailing, 20)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                }

                // Icon and Question Section
                if let imageUrl = viewModel.currentQuestion?.image, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show loading indicator
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                        case .failure:
                            Image("logo") // Fallback image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                if viewModel.answerChecked {
                    // Show Feedback Icon Instead of Question
                    let answerStatus = viewModel.answerIsCorrect ?? false
                    Image(systemName: answerStatus ? "checkmark" : "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(answerStatus
                            ? Color(hue: 0.315, saturation: 0.953, brightness: 0.335)
                            : Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scale = isGrowing ? 1.2 : 1.0
                                isGrowing.toggle()
                            }
                        }
                        .transition(.asymmetric(insertion: .scale, removal: .opacity))
                } else {
                    // Show Question Text
                    Text(viewModel.currentQuestion?.questionText ?? "Loading question...")
                        .foregroundColor(.black)
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
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

            viewModel.resetButtonColors()
            viewModel.fetchNextQuestion()
           }
           .navigationBarHidden(true)
           .navigationBarBackButtonHidden(true)
        .alert(item: $viewModel.activeAlert) { item -> Alert in
            switch item {
            case .showAlert:
                viewModel.playWarningSound()
                return Alert(title: Text("ATTENTION"), message: Text("Fear not, make a choice"), dismissButton: .default(Text("OK")))
                
            case .showEndGameAlert:
                print("Show End Game Alert")
                return Alert(
                    title: Text("JUST CHECKING"),
                    message: Text("Sure you want to end the game?"),
                    primaryButton: .destructive(Text("YEP")) {
                        viewModel.terminar {
                            shouldPresentGameOver = true
                        }
                    },
                    secondaryButton: .cancel(Text("NOPE"))
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
                return Alert(title: Text("WATCH OUT"), message: Text("This is your 4th error. One more and you're done."), dismissButton: .default(Text("OK")))
                
            case .showReturnToAppAlert:
                return Alert(
                    title: Text("WARNING"),
                    message: Text("Do not leave the app while the timer is running. You will be penalized."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.penalizeForLeavingApp() // Process as a wrong answer after dismissing the alert
                    }
                )

            case .showTimeIsUpAlert:
                return Alert(
                    title: Text("TIME'S UP"),
                    message: Text("You ran out of time."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.penalizeForTimeExpiry() // Apply penalty after dismissing the alert
                    }
                )
            }
        }
                .fullScreenCover(isPresented: $shouldPresentGameOver){
                    GameOver(userId: userId)
                        .onDisappear{
                            presentationMode.wrappedValue.dismiss()
                        }
                }
                .onChange(of: viewModel.activeAlert) { newAlert in
                    viewModel.isAlertBeingDisplayed = (newAlert != nil)
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
        isLoading = true // Set loading state
        guard !categoryImage.isEmpty else {
            print("Category image is empty.")
            isLoading = false
            return
        }

        guard categoryImage.starts(with: "gs://") else {
            if let url = URL(string: categoryImage) {
                downloadImage(from: url)
            } else {
                print("Invalid URL: \(categoryImage)")
                isLoading = false
            }
            return
        }

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
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
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


