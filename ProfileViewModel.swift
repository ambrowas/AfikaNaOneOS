import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth


extension ProfileViewModel {
    static var mock: ProfileViewModel {
        let mockViewModel = ProfileViewModel()
        mockViewModel.fullname = "John Doe"
        mockViewModel.email = "john.doe@example.com"
        mockViewModel.telefono = "+123456789"
        mockViewModel.ciudad = "New York"
        mockViewModel.pais = "USA"
        mockViewModel.highestScore = 100
        mockViewModel.accumulatedPuntuacion = 500
        mockViewModel.accumulatedAciertos = 50
        mockViewModel.accumulatedFallos = 5
        mockViewModel.flagUrl = nil // Avoid loading external resources
        mockViewModel.positionInLeaderboard = 1
        return mockViewModel
    }
}

class ProfileViewModel: ObservableObject {
    static let shared = ProfileViewModel()
    
    
    init() {}
    
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
    @Published var flagUrl: String? = nil
    @Published var userId: String = ""
    @Published var userData: UserData = UserData() // Replace `UserData` with the correct type
    @Published var showReauthenticationCard: Bool = false
    @State private var showMenuModoCompeticion = false
    
    
    
    enum AlertType: Identifiable, Equatable {
        case deleteConfirmation
        case deletionSuccess
        case deletionFailure(String)
        case imageChangeSuccess
        case imageChangeError(String)
        case volveratras
        case reauthenticateRequired // Add this case
        
        // Unique ID for each alert type
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
            case .reauthenticateRequired:
                return 7
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
        case reauthenticateRequired
    }
    
    
    
    func fetchProfileImage(url: String) {
        guard let url = URL(string: url) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.profileFetchStatus = .failure("Invalid URL")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to fetch the profile image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.profileFetchStatus = .failure("Failed to fetch the profile image")
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to convert data to image")
                DispatchQueue.main.async {
                    self.profileFetchStatus = .failure("Failed to convert data to image")
                }
                return
            }
            
            // Resize the image to fit
            let resizedImage = self.resizeImageToFit(image: image, targetSize: CGSize(width: 250, height: 200))
            
            DispatchQueue.main.async {
                self.profileImage = resizedImage
                self.profileFetchStatus = .success
                print("Successfully fetched and resized the profile image")
            }
        }.resume()
    }
    
    
    
    private func resizeImageToFit(image: UIImage, targetSize: CGSize) -> UIImage {
        let originalSize = image.size
        
        // Calculate the aspect ratio to fit the image within the target size
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Create a graphics context for resizing
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
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
                    self.flagUrl = userData["flagUrl"] as? String
                    
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
    
    
    func deleteUserAndNotify() {
        guard let user = Auth.auth().currentUser else {
            self.alertType = .deletionFailure("User not authenticated.")
            playWarningSound()
            return
        }

        // Step 1: Delete user data from Realtime Database first
        self.deleteUserData { [weak self] success in
            guard let self = self else { return }

            if success {
                print("User data deleted successfully. Proceeding to delete Firebase Authentication account.")
                
                user.delete { error in
                    if let error = error as NSError? {
                        print("Error deleting user: \(error.localizedDescription)")
                        self.playWarningSound()
                        
                        if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            print("Reauthentication required.")
                            DispatchQueue.main.async {
                                self.alertType = .reauthenticateRequired
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.alertType = .deletionFailure("An error occurred: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // User account deleted successfully
                        print("User account deleted successfully.")
                        DispatchQueue.main.async {
                            self.alertType = .deletionSuccess
                            self.playMagicalSound() // Play magical sound for success
                            self.showMenuModoCompeticion = true // Navigate to Menu Principal
                        }
                    }
                }
            } else {
                print("Failed to delete user data. Aborting account deletion.")
                DispatchQueue.main.async {
                    self.alertType = .deletionFailure("Failed to delete user data from the database.")
                    self.playWarningSound()
                }
            }
        }
    }

    
    private func deleteUserData(completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User ID not found.")
            playWarningSound()
            completion(false)
            return
        }

        let userRef = Database.database().reference().child("user").child(userID)
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                print("No user data found to delete.")
                completion(true) // No data to delete, considered successful
                return
            }

            // Backup user data for rollback
            let backupData = snapshot.value

            userRef.removeValue { error, _ in
                if let error = error {
                    print("Error deleting user data: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User data deleted successfully.")
                    self.backupDataForRollback[userID] = backupData // Store backup
                    self.logDeletedUser(userFullName: self.fullname, email: self.email)
                    completion(true)
                }
            }
        }
    }
    
    private func restoreUserData(userID: String, completion: @escaping (Bool) -> Void) {
        guard let backupData = self.backupDataForRollback[userID] else {
            print("No backup data available for rollback.")
            completion(false)
            return
        }

        let userRef = Database.database().reference().child("user").child(userID)
        userRef.setValue(backupData) { error, _ in
            if let error = error {
                print("Error restoring user data: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User data restored successfully.")
                completion(true)
            }
        }
    }
    
    func performReauthentication(email: String, password: String) {
        guard let user = Auth.auth().currentUser else {
            self.alertType = .deletionFailure("User not authenticated.")
            playWarningSound()
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reauthentication failed: \(error.localizedDescription)")
                self.alertType = .deletionFailure("Reauthentication failed. Please check your credentials.")
                self.playWarningSound() // Play warning sound for failure
            } else {
                print("Reauthentication successful. Proceeding with deletion.")
                self.alertType = nil
                self.showReauthenticationCard = false
                
                // Proceed to delete user and notify
                self.deleteUserAndNotify()
            }
        }
    }
    
    private func logDeletedUser(userFullName: String, email: String) {
        let deletedUsersRef = Database.database().reference().child("deleted_users").childByAutoId()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        
        let logData: [String: Any] = [
            "fullName": userFullName,
            "email": email,
            "deletionTime": dateFormatter.string(from: Date())
        ]
        
        deletedUsersRef.setValue(logData) { error, _ in
            if let error = error {
                print("Failed to log deleted user: \(error.localizedDescription)")
            } else {
                print("User deletion logged successfully.")
            }
        }
    }
    
    private var backupDataForRollback: [String: Any] = [:]

    // MARK: - Sound Manager Integration
    private func playWarningSound() {
        SoundManager.shared.playWarningSound()
    }

    private func playMagicalSound() {
        SoundManager.shared.playMagicalSound()
    }

    private func playTransitionSound() {
        SoundManager.shared.playTransitionSound()
    }
}
