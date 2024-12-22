import SwiftUI
import Firebase
import FirebaseAuth


struct CheckCodigo: View {
    @StateObject private var viewModel = NuevoUsuarioViewModel()
    @State private var showAlert = false
    @State private var showAlert1 = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    @State private var showAlert4 = false
    @State private var showAlertPromotionValid = false
    @State private var input1: String = ""
    @State private var input2: String = ""
    @State private var input3: String = ""
    @State private var input4: String = ""
    @FocusState private var isInput1Active: Bool
    @FocusState private var isInput2Active: Bool
    @FocusState private var isInput3Active: Bool
    @FocusState private var isInput4Active: Bool
    @State private var showSheet = false
    @State private var userData: UserData = UserData()
    @State private var goToMenuCompeticion: Bool = false
    @State private var goToMenuModoCompeticion: Bool = false
    
    func checkCodigo() {
        guard let input = Int("\(input1)\(input2)\(input3)\(input4)") else {
            showAlert4 = true
            showAlert = true
            return
        }
        
        print("Input is valid, proceeding to fetch data from Firebase")
        
        let gameCodesRef = Database.database().reference().child("gamecodes")
        gameCodesRef.observeSingleEvent(of: .value) { snapshot in
            var codeExists = false
            var codeUsed = false
            var keyToUpdate: String?
            var isStaticCode = false
            
            print("Successfully fetched data from Firebase")
            
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                if let value = snap.value as? [String: Any] {
                    if let code = value["code"] as? Int {
                        if input == code {
                            codeExists = true
                            keyToUpdate = snap.key
                            if let used = value["used"] as? Bool {
                                codeUsed = used
                            }
                            if value["StaticCode"] != nil {
                                isStaticCode = true
                            }
                            break
                        }
                    }
                }
            }
            
            if !codeExists {
                SoundManager.shared.playWarningSound()
                showAlert3 = true
                showAlert = true
                clearInputs()
                isInput1Active = true
            } else if isStaticCode {
                SoundManager.shared.playMagicalSound()
                showAlertPromotionValid = true
                showAlert = true
                clearInputs()
                isInput1Active = true
                resetGameData() // Reset game data when static code is used
            } else if codeUsed {
                SoundManager.shared.playWarningSound()
                showAlert2 = true
                showAlert = true
                clearInputs()
                isInput1Active = true
            } else {
                SoundManager.shared.playMagicalSound()
                showAlert1 = true
                showAlert = true
                clearInputs()
                isInput1Active = true
                
                if let user = Auth.auth().currentUser, let key = keyToUpdate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yy HH:mm"
                    let timestamp = dateFormatter.string(from: Date())
                    let updateValue: [String: Any] = ["used": true,
                                                      "usedByUserID": user.uid,
                                                      "usedByfullname": viewModel.fullname,
                                                      "usedTimestamp": timestamp]
                    gameCodesRef.child(key).updateChildValues(updateValue) { (error, reference) in
                        if let error = error {
                            print("Failed to update value. Error: \(error)")
                            return
                        }
                        print("Successfully updated the code usage info")
                    }
                }
            }
        }
    }
    
    func resetGameData() {
        if let user = Auth.auth().currentUser {
            let userGameRef = Database.database().reference().child("user").child(user.uid)
            let gameData: [String: Any] = ["currentGameAciertos": 0,
                                           "currentGameFallos": 0,
                                           "currentGamePuntuacion": 0]
            userGameRef.updateChildValues(gameData) { (error, reference) in
                if let error = error {
                    print("Failed to reset game data. Error: \(error)")
                    return
                }
                print("Game data has been successfully reset.")
            }
        } else {
            print("No current user found while trying to reset game data.")
        }
    }
    
    func clearInputs() {
        input1 = ""
        input2 = ""
        input3 = ""
        input4 = ""
    }
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.trailing, 10.0)
                    .frame(width: 200, height: 150)
                    .padding(.top, -50)
                    .padding(.bottom, 200)
                
                Text("ENTER A GAMECODE")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack {
                    TextField("", text: $input1)
                        .modifier(InputModifier())
                        .onChange(of: input1) { newValue in
                            if newValue.count > 4 {
                                input1 = String(newValue.prefix(4))
                                isInput2Active = true
                            }
                        }
                        .focused($isInput1Active)
                    
                    TextField("", text: $input2)
                        .modifier(InputModifier())
                        .onChange(of: input2) { newValue in
                            if newValue.count > 4 {
                                input2 = String(newValue.prefix(4))
                                isInput3Active = true
                            }
                        }
                        .focused($isInput2Active)
                    
                    TextField("", text: $input3)
                        .modifier(InputModifier())
                        .onChange(of: input3) { newValue in
                            if newValue.count > 4 {
                                input3 = String(newValue.prefix(4))
                                isInput4Active = true
                            }
                        }
                        .focused($isInput3Active)
                    
                    TextField("", text: $input4)
                        .modifier(InputModifier())
                        .onChange(of: input4) { newValue in
                            if newValue.count > 3 {
                                input4 = String(newValue.prefix(3))
                                checkCodigo() // Add action for when the last input field is filled
                            }
                        }
                        .focused($isInput4Active)
                }
                
                Button(action: {
                   
                    checkCodigo()
                }) {
                    Text("VALIDATE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .padding(.top, 60)
                
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    goToMenuCompeticion = true
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .padding(.bottom, 10)
                .fullScreenCover(isPresented: $goToMenuCompeticion) {
                    MenuModoCompeticion(userId: "DummyuserId", userData: UserData(), viewModel: MenuModoCompeticionViewModel())
                }
            }
            // Use fullScreenCover for going to MenuModoCompeticion
            .fullScreenCover(isPresented: $goToMenuModoCompeticion) {
                MenuModoCompeticion(userId: "DummyuserId", userData: UserData(), viewModel: MenuModoCompeticionViewModel())
            }
        }
        .alert(isPresented: $showAlert) {
            if showAlert1 {
                return Alert(
                    title: Text("GAME CODE VALIDATED"),
                    message: Text("Good luck! You're in."),
                    dismissButton: .default(Text("OK")) {
                        // Reset game data
                        resetGameData()
                        // Navigate to MenuModoCompeticion
                        showAlert1 = false
                        showAlert = false
                        SoundManager.shared.playTransitionSound()
                        goToMenuModoCompeticion = true
                    }
                )
            } else if showAlert2 {
                return Alert(
                    title: Text("SOMETHING IS WRONG"),
                    message: Text("This code has already been used. Try again.Let's see"),
                    dismissButton: .default(Text("ok")) {
                        clearInputs()
                        showAlert2 = false
                        showAlert = false
                        isInput1Active = true
                    }
                )
            } else if showAlert3 {
                return Alert(
                    title: Text("SOMETHING'S WRONG"),
                    message: Text("This code does not seem to exist. Try again."),
                    dismissButton: .default(Text("ok")) {
                        clearInputs()
                        showAlert3 = false
                        showAlert = false
                        isInput1Active = true
                    }
                )
            } else if showAlert4 {
                SoundManager.shared.playWarningSound()
                return Alert(
                    title: Text("SOMETHING IS NOT RIGHT"),
                    message: Text("Enter your 15 digit gamecode."),
                    dismissButton: .default(Text("ok")) {
                        clearInputs()
                        showAlert4 = false
                        showAlert = false
                        isInput1Active = true
                    }
                )
            } else if showAlertPromotionValid {
                return Alert(
                    title: Text("PROMO CODE VALIDATED. Get on it champ!"),
                    dismissButton: .default(Text("OK")) {
                        showAlertPromotionValid = false
                        showAlert = false
                        SoundManager.shared.playTransitionSound()
                        goToMenuModoCompeticion = true
                    }
                )
            } else {
                // Default alert
                return Alert(
                    title: Text("Unknown error"),
                    message: Text("An unknown error occurred.")
                )
            }
        }
    }
    
    struct InputModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 30, weight: .light, design: .monospaced))
                .frame(width: 85, height: 60)
                .border(Color.black, width: 2)
        }
    }
    
    struct CheckCodigo_Previews: PreviewProvider {
        static var previews: some View {
            CheckCodigo()
        }
    }
}
