import SwiftUI
import FirebaseAuth

// MARK: - ResultadoCompeticion
struct ResultadoCompeticion: View {
    @StateObject var userViewModel = UserViewModel()
    @State private var isButtonDisabled = false
    @State private var activeAlert: ActiveAlert? = nil
    @State private var showCodigo = false
    let userId: String
    @Environment(\.presentationMode) var presentationMode
    @State private var goToMenuPrincipal: Bool = false
    @State private var goToClasificacion: Bool = false
    @State private var isButtonCoolingDown = false
    @State private var isPlayingSound = false // Tracks if sound is actively playing
    
    enum ActiveAlert: Identifiable {
        case minimoCobro, esperaNecesaria, confirmarSalida
        
        var id: String {
            switch self {
            case .minimoCobro:
                return "minimoCobro"
            case .esperaNecesaria:
                return "esperaNecesaria"
            case .confirmarSalida:
                return "confirmarSalida"
            }
        }
    }
    
    private func initiateCooldown() {
        isButtonCoolingDown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
            self.isButtonCoolingDown = false
        }
    }
    
    var body: some View {
        ZStack {
            // Background Image
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                // Logo
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.top, -50)
                    .frame(width: 100, height: 150)
                
                // Title
                Text("SCORECARD FOR \(userViewModel.fullname)")
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top, -20)
                
                // Data List
                List {
                    TextRowView(title: "CORRECT ANSWERS", value: "\(userViewModel.currentGameAciertos)")
                    TextRowView(title: "INCORRECT ANSWERS", value: "\(userViewModel.currentGameFallos)")
                    TextRowView(title: "SCORE", value: "\(userViewModel.currentGamePuntuacion)")
                    TextRowView(title: "CASH", value: "\(userViewModel.currentGamePuntuacion) AFROS")
                    TextRowView(title: "GLOBAL RANKING", value: "\(userViewModel.positionInLeaderboard)")
                    TextRowView(title: "RECORD", value: "\(userViewModel.highestScore)")
                    TextRowView(title: "TOTAL CASH", value: "\(userViewModel.accumulatedPuntuacion) AFROS")
                }
                .listStyle(PlainListStyle())
                .frame(width: 300, height: 310)
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 3)
                )
                .environment(\.colorScheme, .light)
                
                // Buttons
                VStack(spacing: 10) {
                    Button(action: handleCashOutButton) {
                        Text("CASH OUT")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 300, height: 55)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .disabled(isButtonDisabled)
                    .fullScreenCover(isPresented: $showCodigo) {
                        CodigoQR()
                    }
                    
                    Button(action: handleLeaderboardButton) {
                        Text("LEADERBOARD")
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
                    .fullScreenCover(isPresented: $goToClasificacion) {
                        ClasificacionView(userId: Auth.auth().currentUser?.uid ?? "")
                    }
                    
                    Button(action: handleMainMenuButton) {
                        Text("MAIN MENU")
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
                    .fullScreenCover(isPresented: $goToMenuPrincipal) {
                        MenuPrincipal(player: .constant(nil))
                    }
                }
                
                // Alerts
                .alert(item: $activeAlert) { alertType in
                    handleAlert(alertType)
                }
                .onAppear {
                    userViewModel.fetchUserData { result in
                        if case .failure(let error) = result {
                            print("Error fetching user data: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Button Handlers
    private func handleCashOutButton() {
        if isButtonCoolingDown {
            SoundManager.shared.playWarningSound()
            activeAlert = .esperaNecesaria
        } else {
            SoundManager.shared.playWarningSound()
            if userViewModel.currentGamePuntuacion >= 2500 {
                showCodigo = true
            } else {
                activeAlert = .minimoCobro
            }
            initiateCooldown()
        }
    }
    
    private func handleLeaderboardButton() {
        SoundManager.shared.playTransitionSound()
        goToClasificacion = true
    }
    
    private func handleMainMenuButton() {
        SoundManager.shared.playWarningSound()
        activeAlert = .confirmarSalida
    }
    
    
    // MARK: - Alert Handlers
    private func handleAlert(_ alertType: ActiveAlert) -> Alert {
        switch alertType {
        case .minimoCobro:
            // playWarningSound()
            return Alert(
                title: Text(""),
                message: Text("2500 AFROS CASH OUT MINIMUM"),
                dismissButton: .default(Text("OK")) {
                    SoundManager.shared.playTransitionSound()
                }
            )
        case .esperaNecesaria:
            //playWarningSound()
            return Alert(
                title: Text(""),
                message: Text("This code has already been processed."),
                dismissButton: .default(Text("OK")) {
                    SoundManager.shared.playTransitionSound()
                }
            )
        case .confirmarSalida:
            // playWarningSound()
            return Alert(
                title: Text("CONFIRM EXIT"),
                message: Text("Yo, you out??"),
                primaryButton: .cancel(Text("NOPE")) {
                    SoundManager.shared.playTransitionSound()
                },
                secondaryButton: .destructive(Text("YEP")) {
                    SoundManager.shared.playTransitionSound()
                    goToMenuPrincipal = true
                }
            )
        }
    }
    
    // MARK: - Sound Management
    
    
    // Helper View for Text Rows
    struct TextRowView: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(nil) // Allow text to wrap to multiple lines
                    .multilineTextAlignment(.leading) // Align text to the left
                    .minimumScaleFactor(0.7) // Scale text if space is tight
                    .frame(maxWidth: .infinity, alignment: .leading) // Take up available space
                
                Text(value)
                    .font(.subheadline)
                    .lineLimit(1) // Restrict value to one line
                    .minimumScaleFactor(0.7) // Scale down text if needed
                    .frame(maxWidth: .infinity, alignment: .trailing) // Align text to the right
            }
            .padding(.vertical, 4) // Add vertical padding between rows
        }
    }
    
    
    struct ResultadoCompeticion_Previews: PreviewProvider {
        static var previews: some View {
            ResultadoCompeticion(userId: "exampleUserId")
        }
    }
}
