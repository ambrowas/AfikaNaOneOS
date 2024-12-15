import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

class GestionarSesionViewModel: ObservableObject {
    
    @Published var usuario: FirebaseAuth.User?
    @Published var estaAutenticado: Bool = false
    @Published var errorDeAutenticacion: Error?
    @Published var muestraAlerta: Bool = false
    @Published var alert: TipoDeAlerta?
    @State private var isUserAuthenticated: Bool = false
    
    
    enum TipoDeAlerta {
        
            case success(String)
            case mistake(String)
        }
    
    enum SessionError: LocalizedError {
        case emptyFields
        case invalidEmailFormat
        case wrongPassword
        case emailNotFound
       

        var errorDescription: String? {
            switch self {
            case .emptyFields:
                SoundManager.shared.playWarningSound()
                return "Fill in both fields."
            case .invalidEmailFormat:
                SoundManager.shared.playWarningSound()
                return "Format error on email"
            case .wrongPassword :
                SoundManager.shared.playWarningSound()
                return "Incorrect password. "
            case .emailNotFound:
                SoundManager.shared.playWarningSound()
                        return "This email is not registered. Correct it or create a new account."
          
            }
        }
    }

    func loginUsuario(correoElectronico: String, contrasena: String) {
        
        guard validarInputs(correoElectronico: correoElectronico, contrasena: contrasena) else {
            return
        }
       
      
        Auth.auth().signIn(withEmail: correoElectronico, password: contrasena) { [weak self] authResult, error in
            
        
            if let error = error as NSError? {
                self?.estaAutenticado = false
                self?.errorDeAutenticacion = error
                
                if error.code == AuthErrorCode.userNotFound.rawValue {
                    self?.ensenarAlerta(type: .mistake(SessionError.emailNotFound.localizedDescription))
                } else if error.code == AuthErrorCode.wrongPassword.rawValue {
                    self?.ensenarAlerta(type: .mistake(SessionError.wrongPassword.localizedDescription))
                } else {
                    SoundManager.shared.playWarningSound()
                    self?.ensenarAlerta(type: .mistake("Login error. Check email/password combination."))
                }
                
            } else {
                self?.usuario = authResult?.user
                self?.estaAutenticado = true
                SoundManager.shared.playMagicalSound()
                self?.ensenarAlerta(type: .success("You are now logged in"))
                
  
            }

        }
    }

    func validarInputs(correoElectronico: String, contrasena: String) -> Bool {
        // Validate that inputs are not empty
        guard !correoElectronico.isEmpty, !contrasena.isEmpty else {
            self.errorDeAutenticacion = SessionError.emptyFields
            self.ensenarAlerta(type: .mistake(SessionError.emptyFields.localizedDescription))
            return false
        }
        
        // Validate email format using a simple regex
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        guard emailTest.evaluate(with: correoElectronico) else {
            self.errorDeAutenticacion = SessionError.invalidEmailFormat
            self.ensenarAlerta(type: .mistake(SessionError.invalidEmailFormat.localizedDescription))
            return false
        }
      
        return true
    }
    
    func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "fullname")
        UserDefaults.standard.removeObject(forKey: "highestScore")
        UserDefaults.standard.removeObject(forKey: "currentGameFallos")
    }

    func logoutUsuario() {
            try? Auth.auth().signOut()
            self.estaAutenticado = false
        
        clearUserData()
     

        }
    
    func ensenarAlerta(type: TipoDeAlerta) {
       self.alert = type
       self.muestraAlerta = true


        }
    }


    
