import SwiftUI
import Firebase
import FirebaseAuth



class AuthService: ObservableObject {
    @Published var isUserLoggedIn: Bool = false
    var currentUser: FirebaseAuth.User? { // Use FirebaseAuth.User instead of just User
        return Auth.auth().currentUser
    }
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.isUserLoggedIn = user != nil
        }
    }
    
    deinit {
        if let authStateDidChangeListenerHandle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateDidChangeListenerHandle)
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            // Handle any errors
            if let error = error {
                print("Error logging in: \(error)")
                return
            }
            
            guard let authResult = authResult else { return }

            // Update user details in UserDefaults
            let ref = Database.database().reference().child("user").child(authResult.user.uid)
            ref.observeSingleEvent(of: .value, with: { snapshot in
                if let dict = snapshot.value as? [String: Any],
                   let fullname = dict["fullname"] as? String,
                   let highestScore = dict["highestScore"] as? Int {
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(fullname, forKey: "loggedInUserName")
                        UserDefaults.standard.set(highestScore, forKey: "highestScore")
                        // Save other user data as needed
                    }
                }
            })

            // Update the device token in the database
            self?.updateUserDeviceTokenInDatabase()
            self?.updateFirebaseInstallationIDInDatabase()
        }
    }
    
    private func updateUserDeviceTokenInDatabase() {
        if let userID = Auth.auth().currentUser?.uid,
           let token = UserDefaults.standard.string(forKey: "deviceToken") {
            let ref = Database.database().reference()
            ref.child("user").child(userID).updateChildValues(["Token": token]) { error, _ in
                if let error = error {
                    // Log the error and continue; do not disrupt the user flow
                    print("Error saving token to database: \(error.localizedDescription)")
                } else {
                    print("Device token successfully saved to database")
                    // Optionally, clear the token from UserDefaults after successful upload
                    UserDefaults.standard.removeObject(forKey: "deviceToken")
                }
            }
        } else {
            // Log if the user is not logged in or if there's no token, but continue the flow
            print("User not logged in or no token available")
        }
    }
    
    private func updateFirebaseInstallationIDInDatabase() {
        if let userID = Auth.auth().currentUser?.uid,
           let installationID = UserDefaults.standard.string(forKey: "firebaseInstallationID") {
            let ref = Database.database().reference()
            ref.child("user").child(userID).updateChildValues(["InstallationID": installationID]) { error, _ in
                if let error = error {
                    print("Error saving installation ID to database: \(error.localizedDescription)")
                } else {
                    print("Installation ID successfully saved to database")
                }
            }
        } else {
            print("User not logged in or no installation ID available")
        }
    }



    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.isUserLoggedIn = false
        } catch let signOutError {
            print("Error occurred while signing out: \(signOutError.localizedDescription)")
            throw signOutError
        }
    }
}
