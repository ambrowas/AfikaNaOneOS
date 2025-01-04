import SwiftUI
import FirebaseDatabase
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var fullname = ""
    @Published var email = ""
    @Published var telefono = ""
    @Published var barrio = ""
    @Published var ciudad = ""
    @Published var pais = ""
    @Published var profilePicture = ""
    @Published var currentGameAciertos = 0
    @Published var currentGameFallos = 0
    @Published var currentGamePuntuacion = 0
    @Published var highestScore = 0
    @Published var accumulatedPuntuacion = 0
    @Published var accumulatedAciertos = 0
    @Published var accumulatedFallos = 0
    @Published var positionInLeaderboard = 0
    @Published var user: User? 
    
    
    func sanitizeUserId(_ userId: String) -> String? {
        let invalidCharacters = CharacterSet(charactersIn: ".$#[]/")
        if let range = userId.rangeOfCharacter(from: invalidCharacters) {
            // Log the invalid userId along with the problematic character(s)
            print("Invalid characters found in userId: \(userId)")
            print("Problematic part: \(userId[range])")
            return nil
        }
        return userId
    }
    
    func fetchUserData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in."])
            completion(.failure(error))
            return
        }
        
        let userId = user.uid
        // Continue as before with the valid userId
        let ref = Database.database().reference().child("user").child(userId)
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user data: \(error)")
                completion(.failure(error as! Error)) // Indicate failure with an error
                return
            }
            
            if let dict = snapshot.value as? [String: Any] {
                DispatchQueue.main.async {
                    // Update the user data here
                    self.fullname = dict["fullname"] as? String ?? ""
                    self.email = dict["email"] as? String ?? ""
                    self.telefono = dict["telefono"] as? String ?? ""
                    self.barrio = dict["barrio"] as? String ?? ""
                    self.ciudad = dict["ciudad"] as? String ?? ""
                    self.pais = dict["pais"] as? String ?? ""
                    self.profilePicture = dict["profilePicture"] as? String ?? ""
                    self.currentGameAciertos = dict["currentGameAciertos"] as? Int ?? 0
                    self.currentGameFallos = dict["currentGameFallos"] as? Int ?? 0
                    self.currentGamePuntuacion = dict["currentGamePuntuacion"] as? Int ?? 0
                    self.highestScore = dict["highestScore"] as? Int ?? 0
                    self.accumulatedPuntuacion = dict["accumulatedPuntuacion"] as? Int ?? 0
                    self.accumulatedAciertos = dict["accumulatedAciertos"] as? Int ?? 0
                    self.accumulatedFallos = dict["accumulatedFallos"] as? Int ?? 0
                    self.positionInLeaderboard = dict["positionInLeaderboard"] as? Int ?? 0
                    
                    completion(.success(()))  // Indicate success
                }
            } else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to cast Firebase snapshot to [String: Any]"])
                completion(.failure(error))  // Indicate failure with an error because the cast did not succeed
           
            }
        }
    }
    }


