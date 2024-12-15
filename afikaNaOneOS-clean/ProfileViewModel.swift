import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    static let shared = ProfileViewModel()
    
    private init() {}
    
    @Published var fullname: String = ""
    @Published var email: String = ""
    @Published var telefono: String = ""
    @Published var barrio: String = ""
    @Published var ciudad: String = ""
    @Published var pais: String = ""
    @Published var highestScore: Int = 0
    @Published var positionInLeaderboard: Int = 0
    @Published var profileImage: UIImage?
    @Published var accumulatedPuntuacion: Int = 0
    @Published var accumulatedAciertos: Int = 0
    @Published var accumulatedFallos: Int = 0
    @Published var profileFetchStatus: ProfileFetchStatus?
    @Published var shouldNavigateToMenuModoCompeticion = false
    @Published var showAlertLogInToDelete = false
    @Published var showAlertUsuarioBorrado = false
    @Published var showAlertBorrarUsuario = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertType: AlertType?
   
    
    enum AlertType: Identifiable, Equatable {
        case deleteConfirmation
        case deletionSuccess
        case deletionFailure(String)
        case imageChangeSuccess
        case imageChangeError(String)
        case volveratras

        // This computed property will give a unique ID for each alert type
        var id: Int {
            switch self {
            case .deleteConfirmation:
                return 0
            case .deletionSuccess:
                return 1
            case .deletionFailure:
                return 2
            case .imageChangeSuccess:
                return 4
            case .imageChangeError:
                return 5
            case .volveratras:
                return 6
            }
        }
    }

    
    private var ref = Database.database().reference()
    private var storageRef = Storage.storage().reference(forURL: "gs://afrikanaone.firebasestorage.app")
    
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    enum ProfileFetchStatus {
        case success
        case failure(String)
        case noImage
        case none
    }
    
    
    func fetchProfileImage(url: String) {
        guard let url = URL(string: url) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Failed to fetch the profile image with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.profileFetchStatus = .failure("Failed to fetch the profile image")
                }
                return
            }
            
            guard let data = data else {
                print("Failed to fetch data")
                DispatchQueue.main.async {
                    self.profileFetchStatus = .failure("Failed to fetch data")
                }
                return
            }
            
            guard let image = UIImage(data: data) else {
                print("Failed to convert data to image")
                DispatchQueue.main.async {
                    self.profileFetchStatus = .failure("Failed to convert data to image")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.profileImage = image
                self.profileFetchStatus = .success
                print("Successfully fetched and set the profile image")
            }
        }.resume()
    }
    
    
    func fetchProfileData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Failed to fetch current user ID")
            self.alertMessage = "Failed to fetch current user ID"
            self.showAlert = true
            return
        }
        
        let userRef = ref.child("user").child(currentUserID)
        userRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if let userData = snapshot.value as? [String: Any] {
                DispatchQueue.main.async {
                    self.fullname = userData["fullname"] as? String ?? "Unknown"
                    self.email = userData["email"] as? String ?? "Unknown"
                    self.telefono = userData["telefono"] as? String ?? "Unknown"
                    self.barrio = userData["barrio"] as? String ?? "Unknown"
                    self.ciudad = userData["ciudad"] as? String ?? "Unknown"
                    self.pais = userData["pais"] as? String ?? "Unknown"
                    self.highestScore = userData["highestScore"] as? Int ?? 0
                    self.positionInLeaderboard = userData["positionInLeaderboard"] as? Int ?? 0
                    self.accumulatedPuntuacion = userData["accumulatedPuntuacion"] as? Int ?? 0
                    self.accumulatedAciertos = userData["accumulatedAciertos"] as? Int ?? 0
                    self.accumulatedFallos = userData["accumulatedFallos"] as? Int ?? 0
                    
                    if let profileImageURL = userData["profilePicture"] as? String, !profileImageURL.isEmpty {
                        self.fetchProfileImage(url: profileImageURL)
                    } else {
                        self.profileImage = nil
                        self.profileFetchStatus = .noImage
                    }
                }
                
                print("Successfully fetched and updated profile data")
            } else {
                print("Error fetching profile data from Realtime Database")
                self.alertMessage = "Error fetching profile data"
                self.showAlert = true
                self.profileFetchStatus = .failure("Error fetching profile data")
            }
        }
    }
    
    
    func deleteUser(completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        // Delete user from Firebase Authentication
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                print("Error deleting user from Firebase Authentication: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Delete user data from Realtime Database
            let ref = Database.database().reference().child("user").child(userID)
            ref.removeValue { error, _ in
                if let error = error {
                    print("Error deleting user from Realtime Database: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User deleted successfully from Firebase and Realtime Database.")
                    
                    // Log deleted user
                    self.logDeletedUser(userFullName: self.fullname, email: self.email)



                    
                    // Notify success and perform further actions if needed
                    completion(true)
                }
            }
        }
    }
    


     private func logDeletedUser(userFullName: String, email: String) {
            let deletedUsersRef = Database.database().reference().child("deleted_users")
            let userRef = deletedUsersRef.childByAutoId()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "ddMMyy HHmmss"
            let currentTimestamp = dateFormatter.string(from: Date())
            
            let calendar = Calendar.current
            if let finalDeletionDate = calendar.date(byAdding: .hour, value: 48, to: Date()) {
                let finalDeletionTimestamp = dateFormatter.string(from: finalDeletionDate)
                
                userRef.setValue([
                    "fullName": userFullName,
                    "email": email,
                    "currentTimestamp": currentTimestamp,
                    "Final Deletion": finalDeletionTimestamp
                ]) { (error, ref) in
                    if let error = error {
                        print("Failed to save user to database:", error.localizedDescription)
                        return
                    }
                    print("Successfully saved user to the database.")
                }
            }
        }


    
    func deleteUserAndNotify() {
        if Auth.auth().currentUser != nil {
            // User is authenticated, proceed with deletion
            deleteUser { success in
                if success {
                    self.alertType = .deletionSuccess
                } else {
                    self.alertType = .deletionFailure("Error al borrar el usuario.")
                }
            }
        } else {
            // User is not authenticated, show an alert asking the user to log in
            // before deleting their account
            self.alertType = .deletionFailure("Usuario no autenticado.")
        }
    }
}


