import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct MenuModoCompeticion: View {
    @State private var userFullName = ""
    @State private var highestScore = 0
    @State private var showAlertJugar = false
    @State private var showAlertClasificacion = false
    @State private var showAlertPerfil = false
    @State private var jugarModoCompeticionActive = false
    @State private var currentGameFallos = 0
    @State private var showCheckCodigo = false
    @State private var showClasificacion = false
  // @State private var showProfile = false
    @State private var showIniciarSesion = false
    @State private var colorIndex: Int = 0
    var userId: String
    @ObservedObject var userData: UserData
    @ObservedObject var viewModel: MenuModoCompeticionViewModel
    @State private var alertMessage = ""
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode
    @State private var shouldPresentGameOver: Bool = false
    @State private var shouldPresentResultado: Bool = false
    @State private var shouldNavigateToProfile: Bool = false
    @State private var shouldPresentProfile = false
    @State private var showMenuPrincipalSheet = false
    @State private var isFlashing = false
    @State private var isShowingProfile = false
    @State private var hasPlayedWarningSound = false // State to manage warning sound
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                if viewModel.userFullName.isEmpty {
                    Text("LOG IN OR REGISTER")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Text(viewModel.userFullName)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal, 20)
                   
                
                if !viewModel.userFullName.isEmpty {
                    Text("Your HighScore is \(viewModel.highestScore) AFROS")
                        .foregroundColor(viewModel.getFlashingColor()) // ✅ Uses Dark Red when not flashing
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.top, -10)
                        .shadow(color: .white, radius: 0.5, x: 0, y: 0) // ✅ Adds white glow effect
                }
                
                if viewModel.validateCurrentGameFallos() {
                    Button(action: {
                        SoundManager.shared.playTransitionSound()
                        showCheckCodigo = true
                    }) {
                        Text("VALIDATE GAMECODE")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(isFlashing ? Color(red: 84/255, green: 8/255, blue: 4/255) : Color(red: 121/255, green: 125/255, blue: 98/255)) 
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .fullScreenCover(isPresented: $showCheckCodigo) {
                        CheckCodigo()
                    }
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                            withAnimation {
                                isFlashing.toggle()
                            }
                        }
                    }
                } else {
                    Button(action: {
                        if Auth.auth().currentUser != nil {
                            SoundManager.shared.playTransitionSound()
                            jugarModoCompeticionActive = true
                        } else {
                            alertMessage = "You must log in to play."
                            showAlert = true // Trigger the alert
                            playWarningSound() // Play warning sound
                        }
                    }) {
                        Text("PLAY")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(isFlashing ? Color.white : Color(red: 121/255, green: 125/255, blue: 98/255)) // #797D62
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .fullScreenCover(isPresented: $jugarModoCompeticionActive) {
                        JugarModoCompeticion(userId: userId, userData: userData)
                    }
                    
                    Button(action: {
                        if Auth.auth().currentUser != nil {
                            SoundManager.shared.playTransitionSound()
                            showClasificacion = true
                        } else {
                            alertMessage = "You must log in first."
                            showAlert = true
                            playWarningSound()
                        }
                    }) {
                        Text("SCOREBOARD")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // Olive Green
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .fullScreenCover(isPresented: $showClasificacion) {
                        if let currentUser = Auth.auth().currentUser {
                            ClasificacionView(userId: currentUser.uid)
                        } else {
                            Text("Loading...")
                        }
                    }
                    
                    Button(action: {
                        if Auth.auth().currentUser != nil {
                            SoundManager.shared.playTransitionSound()
                            isShowingProfile = true
                        } else {
                            alertMessage = "You must log in first."
                            showAlert = true
                            playWarningSound()
                        }
                    }) {
                        Text("PROFILE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // Olive Green
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .fullScreenCover(isPresented: $isShowingProfile) {
                        Profile(profileViewModel: ProfileViewModel.shared)
                    }
                    
                    // Alert Modifier
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("ATTENTION"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                
                Button(action: {
                    if viewModel.userFullName.isEmpty {
                        SoundManager.shared.playTransitionSound()
                        showIniciarSesion = true
                    } else {
                        do {
                            try Auth.auth().signOut()
                            SoundManager.shared.playTransitionSound()
                            viewModel.userFullName = ""
                            viewModel.highestScore = 0
                            viewModel.currentGameFallos = 0
                        } catch _ as NSError {}
                    }
                }) {
                    Text(viewModel.userFullName.isEmpty ? "LOGIN/REGISTRATION" : "LOG OUT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // Olive Green
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .fullScreenCover(isPresented: $showIniciarSesion) {
                    GestionarSesion()
                        .onDisappear {
                            viewModel.fetchCurrentUserData()
                        }
                }
                
                Button {
                    SoundManager.shared.playTransitionSound()
                    showMenuPrincipalSheet = true
                } label: {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // Olive Green
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .fullScreenCover(isPresented: $showMenuPrincipalSheet) {
                    MenuPrincipal(player: .constant(nil))
                }
            }
            .onAppear {
                viewModel.checkAndStartBatchProcess()
                if viewModel.userFullName.isEmpty {
                    viewModel.fetchCurrentUserData()
                }
                resetWarningSoundState()
            }
        }
    }
    
    // Functions to manage warning sound state
    func playWarningSound() {
        DispatchQueue.main.async {
            SoundManager.shared.playWarningSound()
        }
    }
    
    func resetWarningSoundState() {
        DispatchQueue.main.async {
            hasPlayedWarningSound = false
        }
    }
}
    
    struct MenuModoCompeticionNavigation: Identifiable {
        let id = UUID()
    }
    struct MenuModoCompeticion_Previews: PreviewProvider {
        static var previews: some View {
            MenuModoCompeticion(
                userId: "PreviewUser", // Provide a mock user ID
                userData: UserData(), // Provide a mock UserData object
                viewModel: MenuModoCompeticionViewModel() // Provide a mock ViewModel
            )
        }
    }



    

