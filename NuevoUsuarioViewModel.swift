import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage


class NuevoUsuarioViewModel: ObservableObject {
    @Published var fullname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var telefono: String = ""
    @Published var ciudad: String = ""
    @Published var selectedCountry: String = ""
    @Published var selectedDevice: String = "Android"
    @Published var alertaTipo: AlertaTipo?
    @Published var mostrarAlerta: Bool = false
    @Published var navegarAlPerfil: Bool = false
    
    // Error Handling
    enum AlertaTipo: Identifiable {
        case exito(message: String)
        case error(message: String)

        var id: String {
            switch self {
            case .exito(let message), .error(let message):
                return message
            }
        }
    }

    enum NuevoUsuarioError: Error {
        case emptyField(fieldName: String)
        case invalidEmailFormat
        case shortPassword
        case invalidPhoneNumber
        case invalidCharacters(fieldName: String)
        case firebaseError(description: String)

        var localizedDescription: String {
            switch self {
            case .emptyField(let fieldName):
                return "\(fieldName) cannot be empty."
            case .invalidEmailFormat:
                return "Invalid email format."
            case .shortPassword:
                return "Password must be at least 6 characters long."
            case .invalidPhoneNumber:
                return "Invalid phone number."
            case .invalidCharacters(let fieldName):
                return "\(fieldName) contains invalid characters."
            case .firebaseError(let description):
                return "Firebase error: \(description)"
            }
        }
    }

    // MARK: - User Creation Flow
    func crearUsuario() {
        print("Starting user creation process...")
        
        // Validate user input
        do {
            try validarCampos()
        } catch let error as NuevoUsuarioError {
            mostrarError(error.localizedDescription)
            return
        } catch {
            mostrarError("Unexpected error occurred during validation.")
            return
        }

        // Proceed with Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.mostrarError("Failed to create user: \(error.localizedDescription)")
                return
            }

            guard let userID = authResult?.user.uid else {
                self.mostrarError("Failed to retrieve user ID.")
                return
            }

            print("User successfully created in Firebase Auth. User ID: \(userID)")
            self.fetchFlagUrlAndSaveUser(userId: userID)
        }
    }

    private func fetchFlagUrlAndSaveUser(userId: String) {
        print("Fetching flag URL for \(selectedCountry)...")
        let storageRef = Storage.storage().reference().child("flags/\(selectedCountry).png")

        storageRef.downloadURL { [weak self] url, error in
            guard let self = self else { return }

            let flagUrl = url?.absoluteString ?? "https://example.com/default_flag.png"
            if let error = error {
                print("Error fetching flag: \(error.localizedDescription), using default flag URL.")
            }

            print("Flag URL fetched: \(flagUrl)")
            self.saveUserToDatabase(userId: userId, flagUrl: flagUrl)
        }
    }

    private func saveUserToDatabase(userId: String, flagUrl: String) {
        let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let userData: [String: Any] = [
            "fullname": fullname,
            "email": email,
            "telefono": telefono,
            "ciudad": ciudad,
            "pais": selectedCountry,
            "dispositivo": selectedDevice,
            "accumulatedAciertos": 0,
            "accumulatedFallos": 0,
            "accumulatedPuntuacion": 0,
            "highestScore": 0,
            "FechadeCreacion": formattedDate,
            "flagUrl": flagUrl
        ]

        let ref = Database.database().reference().child("user").child(userId)
        ref.setValue(userData) { [weak self] error, _ in
            guard let self = self else { return }
            if let error = error {
                self.mostrarError("Failed to save user data: \(error.localizedDescription)")
                return
            }

            print("User data successfully saved in Firebase.")
            DispatchQueue.main.async {
                SoundManager.shared.playMagicalSound()
                self.alertaTipo = .exito(message: "User created successfully. Please set up a profile picture.")
                self.mostrarAlerta = true
                self.navegarAlPerfil = true
            }
        }
    }

    // MARK: - Validation
    private func validarCampos() throws {
        guard !fullname.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "Full Name") }
        guard !email.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "Email") }
        guard !password.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "Password") }
        guard !telefono.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "Phone Number") }
        guard !ciudad.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "City") }
        guard !selectedCountry.isEmpty else { throw NuevoUsuarioError.emptyField(fieldName: "Country") }
        guard email.isValidEmail else { throw NuevoUsuarioError.invalidEmailFormat }
        guard password.count >= 6 else { throw NuevoUsuarioError.shortPassword }
        guard telefono.isValidPhoneNumber else { throw NuevoUsuarioError.invalidPhoneNumber }
    }

    // MARK: - Error Handling
    private func mostrarError(_ message: String) {
        DispatchQueue.main.async {
            self.alertaTipo = .error(message: message)
            self.mostrarAlerta = true
            SoundManager.shared.playWarningSound()
        }
    }
}

// MARK: - String Validation Extensions
extension String {
    var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    var isValidPhoneNumber: Bool {
        let regex = "^[+0-9]{1,}[0-9\\-\\s]{3,15}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
}
