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
    @Published var error: NuevoUsuarioError?
    @Published var mostrarAlerta: Bool = false
    @Published var alertaTipo: AlertaTipo?
    @Published var navegarAlPerfil: Bool = false
    @Published var searchText = ""
    var userID: String = ""
    private var questionManager: QuestionManager?
    @Published var isCountrySelected: Bool = false

  
    
   
    private enum FieldType {
          case name, address, phoneNumber, email, password
      }


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

    enum NuevoUsuarioError: Error, Identifiable {
        case emptyField(fieldName: String)
        case invalidEmailFormat
        case shortPassword
        case invalidPhoneNumber
        case invalidCharacters(fieldName: String)
        case signInError(description: String)

        var id: String {
            return localizedDescription
        }

        var localizedDescription: String {
            switch self {
            case .emptyField(let fieldName):
                return "\(fieldName) Can't leave empty."
            case .invalidEmailFormat:
                return "Incorrect email format."
            case .shortPassword:
                return "Password should be at least 6 characters long."
            case .invalidPhoneNumber:
                return "Invalid phone number."
            case .invalidCharacters(let fieldName):
                return "\(fieldName) contains ilegal characters."
            case .signInError(let description):
                return "Error while trying to log in: \(description)"
            }
        }
    }
    
    init() {
            let realTimeDatabaseReference = Database.database().reference()
            let firestore = Firestore.firestore()
            self.userID = Auth.auth().currentUser?.uid ?? "UnknownUserID" // Default value if not logged in
            self.questionManager = QuestionManager(realTimeDatabaseReference: realTimeDatabaseReference, firestore: firestore, userID: userID)
        }

    func crearUsuario() {
        print("Starting registration process.")
        
        // Validate user input
        let validationResult = validarCampos()
        if !validationResult.isValid {
            // Prepare the error message(s)
            let errorMessage = validationResult.errors.map { $0.localizedDescription }.joined(separator: " ")
            
            // Update the alertaTipo to communicate the error(s) to the user
            alertaTipo = .error(message: "Error: \(errorMessage)")
            mostrarAlerta = true  // Trigger the alert
            
            // Play warning sound only once
            if !SoundManager.shared.isPlaying {
                SoundManager.shared.playWarningSound()
            }
            
            return
        }
        print("Field validation OK.")
        
        // Proceed with Firebase user creation
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Firebase Auth error: \(error.localizedDescription)")
                self.alertaTipo = .error(message: error.localizedDescription)
                self.mostrarAlerta = true
                
                // Play warning sound only once
                if !SoundManager.shared.isPlaying {
                    SoundManager.shared.playWarningSound()
                }
                
                return
            }
            
            guard let userID = authResult?.user.uid else {
                print("Error: Failed to obtain a valid user ID from Firebase Auth.")
                self.alertaTipo = .error(message: "Error: Failed to obtain a valid user ID.")
                self.mostrarAlerta = true
                
                // Play warning sound only once
                if !SoundManager.shared.isPlaying {
                    SoundManager.shared.playWarningSound()
                }
                
                return
            }
            print("User created in Firebase Auth.")
            
            // Save additional user information
            self.guardarUsuario(userId: userID)
            SoundManager.shared.playMagicalSound()
            
            // Show success alert and navigate to profile setup
            self.alertaTipo = .exito(message: "New user has been created. Set up a profile pic")
            self.mostrarAlerta = true
            self.navegarAlPerfil = true
        }
    }

    private func guardarUsuario(userId: String) {
        let storageBaseURL = "https://firebasestorage.googleapis.com/v0/b/afrikanaone.firebasestorage.app/o/flags%2F"
        let storageSuffix = "?alt=media"

        // Prepare date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let formattedDate = dateFormatter.string(from: Date())

        // Create the flag URL
        let countryFileName = selectedCountry.replacingOccurrences(of: " ", with: "%20") + ".png"
        let flagUrl = "\(storageBaseURL)\(countryFileName)\(storageSuffix)"

        // Prepare user data
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

        // Reference to Firebase database
        let ref = Database.database().reference()
        ref.child("user").child(userId).setValue(userData) { [weak self] error, _ in
            guard let self = self else { return }

            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                self.alertaTipo = .error(message: "Error saving user data: \(error.localizedDescription)")
                self.mostrarAlerta = true
                if !SoundManager.shared.isPlaying {
                    SoundManager.shared.playWarningSound()
                }
                return
            }

            print("User data saved successfully in Firebase.")
            self.alertaTipo = .exito(message: "User created successfully!")
            self.mostrarAlerta = true

            // Play magical sound on success
            SoundManager.shared.playMagicalSound()
        }
    }
    
    func fetchFlagUrls(completion: @escaping ([String: String]?) -> Void) {
        let firestore = Firestore.firestore()
        firestore.collection("flags").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching flag URLs: \(error.localizedDescription)")
                completion(nil)
                return
            }

            var flagUrlMap = [String: String]()
            snapshot?.documents.forEach { document in
                if let country = document.documentID as? String,
                   let flagUrl = document.get("url") as? String {
                    flagUrlMap[country] = flagUrl
                }
            }

            completion(flagUrlMap)
        }
    }
    
 
    func getCountryAbbreviation(for countryName: String) -> String {
        let countryAbbreviationMap: [String: String] = [
            "Algeria": "DZA",
            "Angola": "AGO",
            "Benin": "BEN",
            "Botswana": "BWA",
            "Burkina Faso": "BFA",
            "Burundi": "BDI",
            "Cameroon": "CMR",
            "Cape Verde": "CPV",
            "Central African Republic": "CAF",
            "Chad": "TCD",
            "Comoros": "COM",
            "Democratic Republic of Congo": "COD",
            "Republic of the Congo": "COG",
            "Côte d'Ivoire": "CIV",
            "Djibouti": "DJI",
            "Egypt": "EGY",
            "Equatorial Guinea": "GNQ",
            "Eritrea": "ERI",
            "Eswatini": "SWZ",
            "Ethiopia": "ETH",
            "Gabon": "GAB",
            "Gambia": "GMB",
            "Ghana": "GHA",
            "Guinea": "GIN",
            "Guinea-Bissau": "GNB",
            "Kenya": "KEN",
            "Lesotho": "LSO",
            "Liberia": "LBR",
            "Libya": "LBY",
            "Madagascar": "MDG",
            "Malawi": "MWI",
            "Mali": "MLI",
            "Mauritania": "MRT",
            "Mauritius": "MUS",
            "Morocco": "MAR",
            "Mozambique": "MOZ",
            "Namibia": "NAM",
            "Niger": "NER",
            "Nigeria": "NGA",
            "Rwanda": "RWA",
            "Sao Tome and Principe": "STP",
            "Senegal": "SEN",
            "Seychelles": "SYC",
            "Sierra Leone": "SLE",
            "Somalia": "SOM",
            "South Africa": "ZAF",
            "South Sudan": "SSD",
            "Sudan": "SDN",
            "Tanzania": "TZA",
            "Togo": "TGO",
            "Tunisia": "TUN",
            "Uganda": "UGA",
            "Zambia": "ZMB",
            "Zimbabwe": "ZWE",
            "United States": "USA",
            "Canada": "CAN",
            "Brazil": "BRA",
            "China": "CHN",
            "India": "IND",
            "United Kingdom": "GBR",
            "Germany": "DEU",
            "France": "FRA",
            "Japan": "JPN",
            "Australia": "AUS",
            "Other": "XXX"
        ]
        return countryAbbreviationMap[countryName] ?? "XXX"
    }

    func updateUserDeviceTokenInDatabase() {
        if let userID = Auth.auth().currentUser?.uid,
           let token = UserDefaults.standard.string(forKey: "deviceToken") {
            let ref = Database.database().reference()
            ref.child("user").child(userID).updateChildValues(["Token": token]) { error, _ in
                if let error = error {
                    print("Error saving token to database: \(error.localizedDescription)")
                } else {
                    print("Device token successfully saved to database")
                    // Optionally, clear the token from UserDefaults after successful upload
                    UserDefaults.standard.removeObject(forKey: "deviceToken")
                }
            }
        }
    }

    private func validarCampos() -> (isValid: Bool, errors: [NuevoUsuarioError]) {
        var errors = [NuevoUsuarioError]()

        // Check for empty fields with specific field names
        if fullname.isEmpty {
            errors.append(.emptyField(fieldName: "Full Name"))
        }
        if email.isEmpty {
            errors.append(.emptyField(fieldName: "Email"))
        }
        if password.isEmpty {
            errors.append(.emptyField(fieldName: "Password"))
        }
        if telefono.isEmpty {
            errors.append(.emptyField(fieldName: "Telephone No."))
        }
        if ciudad.isEmpty {
            errors.append(.emptyField(fieldName: "City"))
        }
        if selectedCountry == "Choose your country of residence" { // Replace with your default or placeholder value
                errors.append(.emptyField(fieldName: "Country"))
        }
        if selectedDevice == "Select your device" { // Replace with your default or placeholder value
                errors.append(.emptyField(fieldName: "Device"))
        }

        // Check for invalid email format
        if !email.isValidEmail {
            errors.append(.invalidEmailFormat)
        }

        // Check for password length
        if password.count < 6 {
            errors.append(.shortPassword)
        }

        // Check for valid phone number format
        if !telefono.isValidPhoneNumber {
            errors.append(.invalidPhoneNumber)
        }

        // Check for valid characters in fullname, barrio, ciudad, and pais
        if !fullname.isValidName {
            errors.append(.invalidCharacters(fieldName: "Full Name"))
        }
        if !ciudad.isLessRestrictiveAlphanumeric {
            errors.append(.invalidCharacters(fieldName: "City"))
        }
     
        if !selectedCountry.isLessRestrictiveAlphanumeric {
            errors.append(.invalidCharacters(fieldName: "Country"))
        }

        return (errors.isEmpty, errors)
    }
    
    
    private func sanitizeAndSetUserInfo(fullname: String, telefono: String, ciudad: String,estado: String, pais: String) {
        // Enum to define field types
        enum FieldType {
            case name, address, phoneNumber, email, password
        }

        // Updated calls to sanitizeString with field type
        self.fullname = sanitizeString(fullname, forFieldType: .name)
        self.telefono = sanitizeString(telefono, forFieldType: .phoneNumber)
        self.ciudad = sanitizeString(ciudad, forFieldType: .address)
      
        // Email is not sanitized to maintain format
        print("Sanitization complete: full name, telephone, city and country.")
    }

    private func sanitizeString(_ input: String, forFieldType type: FieldType) -> String {
        let allowedCharacters: CharacterSet

        switch type {
        case .name, .address:
            // Allow letters, numbers, spaces, punctuation for names and addresses
            allowedCharacters = CharacterSet.letters
                                .union(CharacterSet.decimalDigits)
                                .union(CharacterSet.whitespaces)
                                .union(CharacterSet.punctuationCharacters)
                                .union(CharacterSet(charactersIn: "-.'"))
        case .phoneNumber:
            // For phone numbers, restrict to numbers, plus, hyphen, and spaces
            allowedCharacters = CharacterSet(charactersIn: "+- ")
                                .union(CharacterSet.decimalDigits)
        case .email, .password:
            // For email and password, return input as is
            return input
        }

        let filteredComponents = input.components(separatedBy: allowedCharacters.inverted)
        return filteredComponents.joined()
    }
    
}
    
   extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    var isValidPhoneNumber: Bool {
        let phoneRegex = "^[+0-9]{1,}[0-9\\-\\s]{3,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }

    var isValidName: Bool {
        let allowedCharacters = CharacterSet.letters
                               .union(CharacterSet.whitespaces)
                               .union(CharacterSet(charactersIn: "-'"))
                               .union(CharacterSet(charactersIn: "-.'"))
                               .union(CharacterSet.decimalDigits) // If numeric characters are allowed in names
        return rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }

    var isLessRestrictiveAlphanumeric: Bool {
        let allowedCharacters = CharacterSet.letters
                               .union(CharacterSet.decimalDigits)
                               .union(CharacterSet.whitespaces)
                               .union(CharacterSet.punctuationCharacters) // If punctuation is allowed
        return rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
}

