import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

class MenuModoCompeticionViewModel: ObservableObject {
    
    @Published var userFullName = ""
    @Published var highestScore = 0
    @Published var currentGameFallos = 0
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var colorIndex: Int = 0
    @Published var showCheckCodigo: Bool = false
    @Published var jugarModoCompeticionActive: Bool = false
    @Published var goToMenuPrincipal: Bool = false
    @Published var showIniciarSesion: Bool = false
    var showAlertJugar = false
    var showAlertClasificacion = false
    var showAlertPerfil = false
    var showClasificacion = false
    var showProfile = false
    var shouldPresentGameOver: Bool = false
    var shouldPresentResultado: Bool = false
    var shouldNavigateToProfile: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var currentBatchNumber: Int = 0
    @Published var questionManager: QuestionManager?


    
    
    
    init() {
           fetchCurrentUserData()
      
       }
    
    func fetchCurrentUserData() {
        

        guard let user = Auth.auth().currentUser else {
           // print("No user is logged in")
            self.isAuthenticated = false
            self.userFullName = ""
            self.highestScore = 0
            self.currentGameFallos = 0
            return
        }
        
        
        self.isAuthenticated = true
        setupQuestionManager()
        
        let ref = Database.database().reference().child("user").child(user.uid)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            // Fetch user details from Firebase
            if let data = snapshot.value as? [String: Any] {
                self.userFullName = data["fullname"] as? String ?? ""
                self.highestScore = data["highestScore"] as? Int ?? 0
                self.currentGameFallos = data["currentGameFallos"] as? Int ?? 0
            }
        }) { error in
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    func setupQuestionManager() {
           // Initialize the questionManager with the required parameters.
           // Assuming you have some method to obtain realTimeDatabaseReference, firestore, and userID
           let realTimeDatabaseReference = Database.database().reference()
           let firestore = Firestore.firestore()
           let userID = getCurrentUserID() // This should be a method that retrieves the current user ID
           
           questionManager = QuestionManager(realTimeDatabaseReference: realTimeDatabaseReference, firestore: firestore, userID: userID)
       }
    
    private func getCurrentUserID() -> String {
            // Access the authentication system of your app to get the user ID
            // For Firebase Auth, it might look like this:
            return Auth.auth().currentUser?.uid ?? ""
        }
    
    func checkAndStartBatchProcess() {
            // Ensure the QuestionManager is initialized
            guard let questionManager = questionManager else {
                print("QuestionManager is not initialized.")
                return
            }
            
            // Check the Firebase Authentication for a valid user ID
            guard let userID = Auth.auth().currentUser?.uid, userID == questionManager.userID else {
                print("Error: User is not authenticated or user ID mismatch.")
                // Handle the unauthenticated user situation here, such as showing a login prompt
                return
            }

            // Determine the count of unused questions in the local database
            let unusedQuestionsCount = DatabaseManager.shared.countUnusedQuestions()
            print("Checking unused questions count: \(unusedQuestionsCount)")

            if unusedQuestionsCount <= 5 {
                print("Not enough unused questions. Need to fetch more from the server.")

                // Fetch the current batch number for the user
                questionManager.fetchCurrentBatchForUser { [weak self] batchNumber in
                    guard self != nil else { return }
                    print("Fetched batch number: \(batchNumber). Fetching shuffled order.")

                    // Fetch the shuffled order for the current batch
                    questionManager.fetchShuffledOrderForBatch(batchNumber: batchNumber) { shuffledOrder in
                        // Log details about the fetched data
                        if shuffledOrder.isEmpty {
                            print("Shuffled order array is empty. This is unexpected.")
                            // Handle error appropriately
                        } else {
                            print("Fetched shuffled order: \(shuffledOrder)")
                        }
                        
                        // Ensure the shuffled order is not empty and is correctly formatted
                        guard let shuffledOrderFirstElement = shuffledOrder.first, !shuffledOrderFirstElement.isEmpty else {
                            print("Error: Shuffled order array is either empty or not in the expected format.")
                            // Handle the error scenario here
                            return
                        }

                        // Fetch questions using the shuffled order
                        questionManager.fetchQuestionsBasedOnShuffledOrder(shuffledOrder: shuffledOrder) { fetchedDocuments in
                            // Updating local database
                            DatabaseManager.shared.deleteAllButLastFiveUnusedQuestions()

                            let group = DispatchGroup()
                            var totalInsertedQuestions = 0

                            for document in fetchedDocuments {
                                group.enter()
                                if let question = QuestionII(document: document) {
                                    print("Inserting question with ID: \(question.number)")
                                    
                                    DatabaseManager.shared.insertQuestion(question: question) { success in
                                        if success {
                                            totalInsertedQuestions += 1
                                        } else {
                                            print("Failed to insert question with ID: \(question.number)")
                                        }
                                        group.leave()
                                    }
                                } else {
                                    print("Document conversion to Question failed.")
                                    group.leave()
                                }
                            }

                            group.notify(queue: .main) {
                                print("Insertion complete. Total inserted: \(totalInsertedQuestions)")
                                // Present the next available question
                                questionManager.presentNextAvailableQuestion()
                            }
                        }
                    }
                }
            } else {
                print("Adequate unused questions available.")
                // Present the next available question
                questionManager.presentNextAvailableQuestion()
            }
        }

    func validateCurrentGameFallos() -> Bool {
        return currentGameFallos >= 5
    }

    func getFlashingColor() -> Color {
       let colors: [Color] = [.red, .blue, .green, .white]
       return colors[colorIndex]
   }

    func startFlashing() {
       let flashingColors: [Color] = [.red, .blue, .green, .white]

       let flashingAnimation = Animation
           .linear(duration: 0.5)
           .repeatForever(autoreverses: true)

       withAnimation(flashingAnimation) {
           colorIndex = 0
       }

       for (index, _) in flashingColors.enumerated() {
           DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
               withAnimation(flashingAnimation) {
                   self.colorIndex = index
               }
           }
       }
   }
    
    func handlePlayButtonJugar() {
           if Auth.auth().currentUser != nil {
               print("User is authenticated. Setting jugarModoCompeticionActive to true.")
               self.jugarModoCompeticionActive = true
           } else {
               print("No authenticated user found. Showing alert.")
               self.alertMessage = "Debes iniciar sesión para poder jugar."
               self.showAlert = true
           }
       }
    
    func handleClasificacionButtonPressed() {
            if Auth.auth().currentUser != nil {
                print("Authenticated user found. Setting showClasificacion to true.")
                self.showClasificacion = true
            } else {
                print("No authenticated user found. Showing alert for Clasificacion.")
                self.alertMessage = "Debes iniciar sesión para poder acceder a la clasificación."
                self.showAlert = true
            }
        }
    
    func handlePerfilButtonPressed() {
            if Auth.auth().currentUser != nil {
                self.showProfile = true
            } else {
                self.alertMessage = "Debes iniciar sesión para poder acceder a tu perfil."
                self.showAlert = true
            }
        }
    
    func handleButtonIniciarSession() {
        if userFullName.isEmpty {
            print("User full name is empty. Showing Iniciar Sesion.")
            self.showIniciarSesion = true
        } else {
            print("Trying to logout user...")
            do {
                try Auth.auth().signOut()
                userFullName = ""
                highestScore = 0
                currentGameFallos = 0
                isAuthenticated = false
                UserDefaults.standard.set("", forKey: "fullname")
                UserDefaults.standard.set(0, forKey: "highestScore")
                UserDefaults.standard.set(0, forKey: "currentGameFallos")
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
                // Use the alert properties to show an error message to the user
                self.alertMessage = "Error signing out: \(signOutError.localizedDescription)"
                self.showAlert = true
            }
        }
    }

    func handleVolverButtonPressed() {
        goToMenuPrincipal = true
        }

   }

 
