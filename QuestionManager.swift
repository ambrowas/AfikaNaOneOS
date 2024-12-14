import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth 

class QuestionManager {
    // MARK: - Properties
    var currentBatchNumber = 1
    var totalNumberOfBatches = 0
    var currentQuestions: [DocumentSnapshot] = [] // Local cache for questions
    var presentedQuestionCount = 0
    var realTimeDatabaseReference: DatabaseReference
    var firestore: Firestore
    var userID: String // This will be set to the currently logged in user's ID
    @Published var currentQuestionText: String = ""
    @Published var currentOptions: [String] = []
    @Published var currentAnswer: String = ""
    @Published var currentCategory: String = ""
    @Published var currentImageURL: String = ""
    
    
  
    
    // MARK: - Initializer
    init(realTimeDatabaseReference: DatabaseReference, firestore: Firestore, userID: String) {
        // Set up your instance here...
        self.realTimeDatabaseReference = realTimeDatabaseReference
        self.firestore = firestore
        self.userID = userID
        // Initialize other properties or perform any setup necessary...
    }
    
    // MARK: - Methods
    
    
    func setNumeroDeBatch(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        print("setNumeroDeBatch - Entered for userId: \(userId)")
        
        countTotalBatches { totalBatches in
            print("setNumeroDeBatch - Total batches count retrieved: \(totalBatches)")
            
            guard totalBatches > 0 else {
                print("setNumeroDeBatch - Exit: No batches available to assign.")
                completion(false, nil)
                return
            }
            
            let randomBatchNumber = Int.random(in: 1...totalBatches)
            print("setNumeroDeBatch - Generated random batch number: \(randomBatchNumber)")
            
            let ref = Database.database().reference()
                ref.child("user").child(userId).updateChildValues(["currentBatch": randomBatchNumber]) { error, _ in
                if let error = error {
                    print("setNumeroDeBatch - Error: Failed to set batch number - \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("setNumeroDeBatch - Set batch number \(randomBatchNumber) for user \(userId)")
                    completion(true, nil)
                }
            }
        }
        
        print("setNumeroDeBatch - Exited")
    }
    
    func updateCurrentBatchInRealtime(completion: @escaping (Bool, Error?) -> Void) {
        // Retrieve the current user's ID from Firebase Auth
        guard let userID = Auth.auth().currentUser?.uid else {
            print("updateCurrentBatchInRealtime - Error: No current user ID found")
            completion(false, nil)
            return
        }

        print("updateCurrentBatchInRealtime - Function was called for userID: \(userID)")

        fetchCurrentBatchForUser { currentBatch in
            print("updateCurrentBatchInRealtime - Current batch number retrieved: \(currentBatch)")

            self.countTotalBatches { totalBatches in
                print("updateCurrentBatchInRealtime - Total batch count retrieved: \(totalBatches)")

                guard totalBatches > 0 else {
                    print("updateCurrentBatchInRealtime - Exit: No batches available to update.")
                    completion(false, nil)
                    return
                }

                let newBatchNumber = currentBatch >= totalBatches ? 1 : currentBatch + 1
                print("updateCurrentBatchInRealtime - New batch number to set: \(newBatchNumber)")
                
                // Log the completed batch
                          self.logCompletedBatch(userId: userID, completedBatch: currentBatch)


                let userRef = self.realTimeDatabaseReference.child("user").child(userID)
                   userRef.updateChildValues(["currentBatch": newBatchNumber]) { error, _ in
                    if let error = error {
                        print("updateCurrentBatchInRealtime - Error updating current batch: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        print("updateCurrentBatchInRealtime - Updated current batch to new value: \(newBatchNumber)")
                        completion(true, nil)
                    }
                }
            }
        }

        print("updateCurrentBatchInRealtime - Exited")
    }
    
    func logCompletedBatch(userId: String, completedBatch: Int) {
        print("logCompletedBatch - Started for userID: \(userId) and batch: \(completedBatch)")
        
        let userRef = Database.database().reference().child("user").child(userId).child("CompletedBatch")
        userRef.observeSingleEvent(of: .value, with: { snapshot in
            if let existingBatches = snapshot.value as? String {
                print("logCompletedBatch - Existing batches found: \(existingBatches)")
                
                let updatedBatches = existingBatches.isEmpty ? "\(completedBatch)" : "\(existingBatches), \(completedBatch)"
                userRef.setValue(updatedBatches) { error, _ in
                    if let error = error {
                        print("logCompletedBatch - Error updating completed batches: \(error.localizedDescription)")
                    } else {
                        print("logCompletedBatch - Successfully updated completed batches to: \(updatedBatches)")
                    }
                }
            } else {
                print("logCompletedBatch - No existing batches found. Setting first completed batch to: \(completedBatch)")
                userRef.setValue("\(completedBatch)") { error, _ in
                    if let error = error {
                        print("logCompletedBatch - Error setting first completed batch: \(error.localizedDescription)")
                    } else {
                        print("logCompletedBatch - Successfully set first completed batch to: \(completedBatch)")
                    }
                }
            }
        })
    }

    func fetchCurrentBatchForUser(completion: @escaping (Int) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("fetchCurrentBatchForUser - Error: No current user ID found")
            completion(1) // Return a default value or handle this scenario appropriately
            return
        }

        print("fetchCurrentBatchForUser - Entered for userID: \(currentUserID)")
        
        let userRef = self.realTimeDatabaseReference.child("user").child(currentUserID)
            userRef.observeSingleEvent(of: .value, with: { snapshot in
                let currentBatch = snapshot.childSnapshot(forPath: "currentBatch").value as? Int ?? 1
            print("fetchCurrentBatchForUser - Current batch retrieved: \(currentBatch)")
            completion(currentBatch)
        })
        
        print("fetchCurrentBatchForUser - Exited")
    }

    func fetchShuffledOrderForBatch(batchNumber: Int, completion: @escaping ([String]) -> Void) {
        print("fetchShuffledOrderForBatch - Entered for batchNumber: \(batchNumber)")
        
        let batchRef = self.firestore.collection("Metadata").document("Batch_\(batchNumber)")
        batchRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("fetchShuffledOrderForBatch - Error fetching shuffled order: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let document = documentSnapshot else {
                print("fetchShuffledOrderForBatch - Error: Document snapshot is nil")
                completion([])
                return
            }
            let shuffledOrder = document.data()?["shuffledOrder"] as? [String] ?? []
            print("fetchShuffledOrderForBatch - Shuffled order retrieved: \(shuffledOrder)")
            completion(shuffledOrder)
        }
        
        print("fetchShuffledOrderForBatch - Exited")
    }

    
    func fetchQuestionsBasedOnShuffledOrder(shuffledOrder: [String], completion: @escaping ([DocumentSnapshot]) -> Void) {
        print("fetchQuestionsBasedOnShuffledOrder - Entered with shuffled order IDs: \(shuffledOrder.joined(separator: ", "))")
        
        let questionsRef = self.firestore.collection("QUESTIONS")
        var fetchedQuestions: [DocumentSnapshot] = []
        
        let dispatchGroup = DispatchGroup()
        
        for questionID in shuffledOrder {
            dispatchGroup.enter()
            questionsRef.document(questionID).getDocument { documentSnapshot, error in
                if let document = documentSnapshot, error == nil {
                    fetchedQuestions.append(document)
                    print("fetchQuestionsBasedOnShuffledOrder - Fetched question with ID: \(questionID)")
                } else {
                    print("fetchQuestionsBasedOnShuffledOrder - Error: \(error?.localizedDescription ?? "unknown error") while fetching question with ID \(questionID)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("fetchQuestionsBasedOnShuffledOrder - All questions fetched based on shuffled order. Total fetched: \(fetchedQuestions.count)")
            completion(fetchedQuestions)
        }
        
        print("fetchQuestionsBasedOnShuffledOrder - Pending completion for shuffled order IDs being fetched")
    }
    
    func fetchQuestionsForCurrentUser() {
        print("fetchQuestionsForCurrentUser - Entered")
        
        let unusedQuestionsCount = DatabaseManager.shared.countUnusedQuestions()
        print("fetchQuestionsForCurrentUser - Unused questions in local DB: \(unusedQuestionsCount)")
        
        if unusedQuestionsCount <= 5 {
            print("fetchQuestionsForCurrentUser - Not enough questions, initiating fetch from server.")
            fetchCurrentBatchForUser { [weak self] batchNumber in
                guard let strongSelf = self else {
                    print("fetchQuestionsForCurrentUser - Weak self is nil, exiting.")
                    return
                }
                
                print("fetchQuestionsForCurrentUser - Current batch number: \(batchNumber)")
                strongSelf.fetchShuffledOrderForBatch(batchNumber: batchNumber) { shuffledOrder in
                    print("fetchQuestionsForCurrentUser - Fetched shuffled order: \(shuffledOrder.joined(separator: ", "))")
                    
                    strongSelf.fetchQuestionsBasedOnShuffledOrder(shuffledOrder: shuffledOrder) { fetchedQuestions in
                        print("fetchQuestionsForCurrentUser - Fetched \(fetchedQuestions.count) questions based on shuffled order.")
                        
                        // Insert new questions into the local database and remove old ones if necessary
                        // (This part will depend on the implementation of your DatabaseManager)
                    }
                }
            }
        } else {
            print("fetchQuestionsForCurrentUser - Sufficient unused questions, no need to fetch from server.")
            // Present the next available question
            // (This part will depend on the implementation of your DatabaseManager)
        }
        
        print("x     - Exited")
    }
    
    func presentNextAvailableQuestion() {
        print("presentNextAvailableQuestion - Entered")
        
        guard let question = DatabaseManager.shared.fetchRandomQuestionFromLocalDatabase() else {
            print("presentNextAvailableQuestion - No questions available to present, consider fetching more.")
            // Fetch more questions if needed.
            return
        }
        
        self.currentQuestionText = question.questionText
        self.currentOptions = [question.optionA, question.optionB, question.optionC]
        self.currentAnswer = question.answer
        self.currentCategory = question.category
        self.currentImageURL = question.image
        
        print("presentNextAvailableQuestion - Presented question text: \(question.questionText)")
        print("presentNextAvailableQuestion - Exited")
    }
    
    func preloadNextBatchQuestions() {
        print("preloadNextBatchQuestions - Entered")
        
        let nextBatchNumber = (currentBatchNumber % totalNumberOfBatches) + 1
        print("preloadNextBatchQuestions - Calculated next batch number: \(nextBatchNumber)")
        
        fetchShuffledOrderForBatch(batchNumber: nextBatchNumber) { shuffledOrder in
            print("preloadNextBatchQuestions - Fetched shuffled order for next batch: \(shuffledOrder.joined(separator: ", "))")
            
            self.fetchQuestionsBasedOnShuffledOrder(shuffledOrder: shuffledOrder) { fetchedQuestions in
                print("preloadNextBatchQuestions - Preloading questions: \(fetchedQuestions.count)")
                // Insert preloaded questions into the local cache or prepare them for presentation.
            }
        }
        
        print("preloadNextBatchQuestions - Exited")
    }
    
    func countTotalBatches(completion: @escaping (Int) -> Void) {
        print("countTotalBatches - Entered")
        
        let metadataRef = self.firestore.collection("Metadata")
        metadataRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("countTotalBatches - Error getting total batch count: \(error.localizedDescription)")
                completion(0)
            } else if let batchCount = querySnapshot?.documents.count {
                print("countTotalBatches - Total number of batches: \(batchCount)")
                completion(batchCount)
            } else {
                print("countTotalBatches - Could not retrieve a valid batch count, defaulting to zero.")
                completion(0)
            }
        }
        
        print("countTotalBatches - Exited")
    }
}
