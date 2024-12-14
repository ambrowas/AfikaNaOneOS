import Combine
import Firebase
import FirebaseAuth
import FirebaseDatabase


class UserManager: ObservableObject {
    @Published var loggedInUserName: String = ""
    @Published var isUserLoggedIn: Bool = false
    

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkLoginStatus()
    }

    func checkLoginStatus() {
        if let user = Auth.auth().currentUser {
            let ref = Database.database().reference().child("user").child(user.uid)
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                if let dict = snapshot.value as? [String: Any],
                   let fullname = dict["fullname"] as? String {
                    self?.loggedInUserName = fullname
                }
                self?.isUserLoggedIn = true
            }
        } else {
            loggedInUserName = ""
            isUserLoggedIn = false
        }
    }

    func loginUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self?.checkLoginStatus()
            }
        }
    }

    func signOutUser() {
        do {
            try Auth.auth().signOut()
            loggedInUserName = ""
            isUserLoggedIn = false
        } catch {
            print(error.localizedDescription)
        }
    }
}

