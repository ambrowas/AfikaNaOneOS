import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth


struct Profile: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var isImagePickerDisplayed = false
    @State private var showAlert: Bool = false
    @State private var showGestionarSesionView = false
    @State private var showMenuPrincipalView = false
    @State private var showMenuModoCompeticion = false
    @Environment(\.presentationMode) var presentationMode
    @State private var placeholderScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                // Profile Image Section
                profileImageSection
                    .padding(.top, 240)
                    .padding(.bottom, -80)
                    .onTapGesture {
                        isImagePickerDisplayed = true
                    }
                
                // Flag Section
                flagSection
                
                // Leaderboard Circle
                leaderboardCircle
                
                // Details and Buttons
                VStack(spacing: 20) {
                    detailsScrollView
                    actionButtons
                }
                .padding(.bottom, 240)
            }
            .fullScreenCover(isPresented: $showMenuModoCompeticion) {
                MenuModoCompeticion(userId: "DummyuserId", userData: UserData(), viewModel: MenuModoCompeticionViewModel())
            }
            .sheet(isPresented: $isImagePickerDisplayed) {
                ImagePicker(
                    profileViewModel: profileViewModel,
                    selectedImage: $profileViewModel.profileImage,
                    storageRef: Storage.storage().reference(),
                    ref: Database.database().reference()
                )
            }
            .sheet(isPresented: $profileViewModel.showReauthenticationCard) {
                ReauthenticationCard { email, password in
                    profileViewModel.performReauthentication(email: email, password: password)
                }
            }
            .alert(item: $profileViewModel.alertType, content: alertContent)
            .onAppear {
                profileViewModel.fetchProfileData()
            }
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        Group {
            if let profileImage = profileViewModel.profileImage {
                // Profile image is set
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 200)
                    .clipped()
                    .border(Color.black, width: 3)
                    .background(Color.white)
            } else {
                // Profile image is not set
                Image(systemName: "person.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 150)
                    .foregroundColor(.gray)
                    .overlay(
                        Text("Profile Picture")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    )
                    .scaleEffect(placeholderScale)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: placeholderScale
                    )
                    .onAppear {
                        placeholderScale = 1.1 // Start the grow effect
                    }
                    .onDisappear {
                        placeholderScale = 1.0 // Reset to original size
                    }
            }
        }
    }
    
    // MARK: - Flag Section
    private var flagSection: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 50, height: 47)
                
                if let flagUrl = profileViewModel.flagUrl, let url = URL(string: flagUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 44)
                    } placeholder: {
                        Image("other")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 44)
                    }
                } else {
                    Image("other")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 44)
                }
            }
            .frame(width: 50, height: 47)
            .offset(x: -90, y: 40)
        }
        .frame(width: 100, height: 100, alignment: .topLeading)
    }
    
    // MARK: - Leaderboard Circle
    private var leaderboardCircle: some View {
        Circle()
            .stroke(Color.black, lineWidth: 2)
            .background(Circle().fill(Color(hue: 1.0, saturation: 0.984, brightness: 0.699)))
            .frame(width: 100, height: 100)
            .overlay(
                Text("\(profileViewModel.positionInLeaderboard)")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            )
            .position(x: 300, y: -60)
    }
    
    // MARK: - Details ScrollView
    private var detailsScrollView: some View {
        ScrollView {
            VStack(spacing: 8) {
                TextRowView(title: "NAME:", content: profileViewModel.fullname.uppercased())
                TextRowView(title: "EMAIL:", content: profileViewModel.email.uppercased())
                TextRowView(title: "TELEPHONE:", content: profileViewModel.telefono.uppercased())
                TextRowView(title: "CITY:", content: profileViewModel.ciudad.uppercased())
                TextRowView(title: "COUNTRY:", content: profileViewModel.pais.uppercased())
                TextRowView(title: "RECORD:", content: "\(profileViewModel.highestScore)".uppercased())
                TextRowView(title: "TOTAL SCORE:", content: "\(profileViewModel.accumulatedPuntuacion)".uppercased())
                TextRowView(title: "TOTAL CORRECT ANSWERS:", content: "\(profileViewModel.accumulatedAciertos)".uppercased())
                TextRowView(title: "TOTAL INCORRECT ANSWERS:", content: "\(profileViewModel.accumulatedFallos)".uppercased())
            }
        }
        .frame(width: 300, height: 300)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                if profileViewModel.profileImage != nil {
                    SoundManager.shared.playTransitionSound()
                    showMenuModoCompeticion = true
                } else {
                    profileViewModel.alertType = .volveratras
                    showAlert = true
                }
            }) {
                Text("VOLVER")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 55)
                    .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
            }
            
            Button(action: {
                profileViewModel.alertType = .deleteConfirmation
                showAlert = true
            }) {
                Text("BORRAR USUARIO")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 55)
                    .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
            }
        }
    }
    
    private func alertContent(for alertType: ProfileViewModel.AlertType) -> Alert {
        switch alertType {
        case .deleteConfirmation:
            SoundManager.shared.playWarningSound()
            return Alert(
                title: Text("ATTENTION"),
                message: Text("Are you sure you want to proceed? This action cannot be undone."),
                primaryButton: .destructive(Text("Go Ahead")) {
                    profileViewModel.deleteUserAndNotify()
                },
                secondaryButton: .cancel {
                    SoundManager.shared.playTransitionSound()
                }
            )
        case .deletionSuccess:
            SoundManager.shared.playMagicalSound()
            return Alert(
                title: Text("USER DELETED"),
                message: Text("Account will be erased within 48 hours."),
                dismissButton: .default(Text("OK")) {
                    showMenuPrincipalView = true
                }
            )
        case .deletionFailure(let errorMessage):
            SoundManager.shared.playWarningSound()
            return Alert(
                title: Text("ERROR"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        case .imageChangeSuccess:
            SoundManager.shared.playMagicalSound()
            return Alert(
                title: Text("DJUDJU BLACK MAGIC"),
                message: Text("Your profile picture has been updated!"),
                dismissButton: .default(Text("OK"))
            )
        case .imageChangeError(let errorMessage):
            SoundManager.shared.playWarningSound()
            return Alert(
                title: Text("ERROR"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        case .volveratras:
            SoundManager.shared.playWarningSound()
            return Alert(
                title: Text("ATTENTION"),
                message: Text("Sure you want to leave without a profile picture?"),
                primaryButton: .default(Text("YES")) {
                    $showMenuModoCompeticion
                },
                secondaryButton: .cancel {
                    SoundManager.shared.playTransitionSound()
                }
            )
        case .reauthenticateRequired:
            return Alert(
                title: Text("Reauthentication Required"),
                message: Text("Please log in again to proceed with the deletion."),
                dismissButton: .default(Text("OK")) {
                    self.profileViewModel.showReauthenticationCard = true
                }
            )
        }
    }
    
    // MARK: - TextRowView
    struct TextRowView: View {
        let title: String
        let content: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black)
                Spacer()
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
    }
    struct ReauthenticationCard: View {
        @Environment(\.presentationMode) var presentationMode
        var onAuthenticate: (String, String) -> Void
        
        @State private var email: String = ""
        @State private var password: String = ""
        @State private var errorMessage: String = ""
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Reauthenticate")
                    .font(.headline)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                HStack {
                    Button("Cancel") {
                        SoundManager.shared.playTransitionSound()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    
                    Button("Authenticate") {
                        if email.isEmpty || password.isEmpty {
                            SoundManager.shared.playWarningSound()
                            errorMessage = "Both fields are required."
                        } else {
                            onAuthenticate(email, password)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
        }
    }
    
    // MARK: - Preview
    struct Profile_Previews: PreviewProvider {
        static var previews: some View {
            Profile(profileViewModel: ProfileViewModel.mock)
                .previewLayout(.sizeThatFits)
        }
    }
}
