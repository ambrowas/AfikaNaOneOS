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
            
            VStack(spacing: 20) {
                // Logo
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 150)
                
                // Title
                Text("SCORECARD FOR \(userViewModel.fullname)")
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
                
                // **Table Layout**
                VStack(spacing: 0) {
                    
                    // Table Rows
                    TableRowView(title: "CORRECT ANSWERS", value: "\(userViewModel.currentGameAciertos)")
                    TableRowView(title: "INCORRECT ANSWERS", value: "\(userViewModel.currentGameFallos)")
                    TableRowView(title: "SCORE", value: "\(userViewModel.currentGamePuntuacion)")
                    TableRowView(title: "CASH", value: "\(userViewModel.currentGamePuntuacion) AFROS")
                    TableRowView(title: "GLOBAL RANKING", value: "\(userViewModel.positionInLeaderboard)")
                    TableRowView(title: "HIGHSCORE", value: "\(userViewModel.highestScore)")
                    TableRowView(title: "TOTAL CASH", value: "\(userViewModel.accumulatedPuntuacion) AFROS")
                }
                .padding()
                .background(Color(red: 121/255, green: 125/255, blue: 98/255).opacity(0.50))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.7), lineWidth: 2)
                )
                .shadow(color: Color.white.opacity(0.15), radius: 5, x: 0, y: 5)
                .frame(width: 320)
                
                // Buttons
                VStack(spacing: 10) {
                    ActionButton(title: "CASH OUT", action: handleCashOutButton)
                        .disabled(isButtonDisabled)
                        .fullScreenCover(isPresented: $showCodigo) {
                            CodigoQR()
                        }
                    
                    ActionButton(title: "LEADERBOARD", action: handleLeaderboardButton)
                        .fullScreenCover(isPresented: $goToClasificacion) {
                            ClasificacionView(userId: Auth.auth().currentUser?.uid ?? "")
                        }
                    
                    ActionButton(title: "MAIN MENU", action: handleMainMenuButton)
                        .fullScreenCover(isPresented: $goToMenuPrincipal) {
                            MenuPrincipal(player: .constant(nil))
                        }
                }
            }
            .padding(.top, 50)
            .environment(\.colorScheme, .light)
            .alert(item: $activeAlert) { alertType in
                handleAlert(alertType)
            }
            .onAppear {
                SoundManager.shared.playRandomLoopedSound()
                
                userViewModel.fetchUserData { result in
                    if case .failure(let error) = result {
                        print("Error fetching user data: \(error.localizedDescription)")
                    }
                }
            }
            .onDisappear {
                SoundManager.shared.stopLoopedSound() // ✅ Stop looped sound properly
            }
        }
    }
    // MARK: - Button Handlers
    
    
    private func handleCashOutButton() {
        SoundManager.shared.stopLoopedSound()
        if isButtonCoolingDown {
            SoundManager.shared.playWarningSound()
            activeAlert = .esperaNecesaria
        } else {
            if userViewModel.currentGamePuntuacion >= 2500 {
                SoundManager.shared.playTransitionSound()
                showCodigo = true
            } else {
                SoundManager.shared.playWarningSound()
                activeAlert = .minimoCobro
            }
            initiateCooldown()
        }
    }
    
    private func handleLeaderboardButton() {
        SoundManager.shared.stopLoopedSound()
        SoundManager.shared.playTransitionSound()
        goToClasificacion = true
    }
    
    private func handleMainMenuButton() {
        SoundManager.shared.stopLoopedSound()
        SoundManager.shared.playWarningSound()
        activeAlert = .confirmarSalida
    }
    
    // MARK: - Alert Handlers
    private func handleAlert(_ alertType: ActiveAlert) -> Alert {
        switch alertType {
        case .minimoCobro:
            return Alert(
                title: Text(""),
                message: Text("2500 AFROS CASH OUT MINIMUM"),
                dismissButton: .default(Text("OK"))
            )
        case .esperaNecesaria:
            return Alert(
                title: Text(""),
                message: Text("This code has already been processed."),
                dismissButton: .default(Text("OK"))
            )
        case .confirmarSalida:
            return Alert(
                title: Text("CONFIRM EXIT"),
                message: Text("Yo, you out??"),
                primaryButton: .cancel(Text("NOPE"), action: {
                    SoundManager.shared.playTransitionSound() // ✅ Correct placement inside action closure
                }),
                secondaryButton: .destructive(Text("YEP")) {
                    SoundManager.shared.playTransitionSound()
                    goToMenuPrincipal = true
                }
            
            )
        }
    }
}

// MARK: - UI Components

struct TableRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1) // ✅ Prevents title from wrapping
                .minimumScaleFactor(0.8) // ✅ Scales text down if needed
                .truncationMode(.tail) // ✅ Ensures long text is cut off properly
                .frame(width: 180, alignment: .leading) // ✅ Fixed width for consistency

            Spacer() // ✅ Adds flexible spacing between title and value

            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1) // ✅ Keeps value in a single line
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
                .frame(width: 100, alignment: .trailing) // ✅ Ensures proper alignment
        }
        .padding(.vertical, 8) // ✅ Better spacing
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.3)) // ✅ Keeps contrast high
        .cornerRadius(5) // ✅ Slightly rounded edges for aesthetics
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.7), lineWidth: 1) // ✅ Subtle border
        )
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 55)
                .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
        }
    }
}

struct ResultadoCompeticion_Previews: PreviewProvider {
    static var previews: some View {
        ResultadoCompeticion(userId: "exampleUserId")
    }
}
