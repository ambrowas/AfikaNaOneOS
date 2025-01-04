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
                    .padding(.top, 280)
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
                ReauthenticationDialog { email, password in
                    profileViewModel.performReauthentication(email: email, password: password)
                } onCancel: {
                    profileViewModel.showReauthenticationCard = false // Dismiss the dialog
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
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 200)
                    .clipped()
                    .border(Color.black, width: 3)
                    .background(Color.white)
            } else {
                // Profile image is not set
                Image(systemName: "person.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 200)
                    .clipped()
                    .foregroundColor(.gray)
                    .overlay(
                        Text("Profile Picture")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding()
                    )
                    .scaleEffect(placeholderScale) // Add grow-shrink effect
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: placeholderScale
                    )
                    .border(Color(hue: 1.0, saturation: 0.984, brightness: 0.699), width: 3)
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
            .position(x: 320, y: -60)
    }
    
    // MARK: - Details ScrollView
    private var detailsScrollView: some View {
        ScrollView {
            VStack(spacing: 0) { // Set spacing to 0 to tightly fit dividers
                UpdatedTextRowView(title: "NAME:", value: profileViewModel.fullname.uppercased())
                Divider()
                UpdatedTextRowView(title: "EMAIL:", value: profileViewModel.email.uppercased())
                Divider()
                UpdatedTextRowView(title: "TELEPHONE:", value: profileViewModel.telefono.uppercased())
                Divider()
                UpdatedTextRowView(title: "CITY:", value: profileViewModel.ciudad.uppercased())
                Divider()
                UpdatedTextRowView(title: "COUNTRY:", value: profileViewModel.pais.uppercased())
                Divider()
                UpdatedTextRowView(title: "RECORD:", value: "\(profileViewModel.highestScore)".uppercased())
                Divider()
                UpdatedTextRowView(title: "TOTAL SCORE:", value: "\(profileViewModel.accumulatedPuntuacion)".uppercased())
                Divider()
                UpdatedTextRowView(title: "TOTAL CORRECT ANSWERS:", value: "\(profileViewModel.accumulatedAciertos)".uppercased())
                Divider()
                UpdatedTextRowView(title: "TOTAL INCORRECT ANSWERS:", value: "\(profileViewModel.accumulatedFallos)".uppercased())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.black, lineWidth: 3)
            )
        }
        .frame(width: 350, height: 400)
        .environment(\.colorScheme, .light)
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
                Text("RETURN")
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
                Text("DELETE USER")
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
                    SoundManager.shared.playTransitionSound()
                    showMenuModoCompeticion = true
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
                title: Text(""),
                message: Text("Please log in again to proceed with the deletion."),
                dismissButton: .default(Text("OK")) {
                    SoundManager.shared.playTransitionSound()
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
            HStack(alignment: .top) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black) // Ensure black text color
                    .frame(maxWidth: 100, alignment: .leading) // Set a max width for the title
                    .fixedSize(horizontal: false, vertical: true) // Allow wrapping for long titles
                
                Text(content)
                    .font(.system(size: 16)) // Set font size
                    .foregroundColor(.black) // Ensure black text color
                    .multilineTextAlignment(.leading) // Align content to the left
                    .fixedSize(horizontal: false, vertical: true) // Allow wrapping for long content
            }
            .padding(.horizontal) // Add horizontal padding
            .frame(maxWidth: .infinity, alignment: .leading) // Stretch the row to fill the container
        }
    }
    // MARK: - Reauthentication
    struct ReauthenticationDialog: View {
        var onAuthenticate: (String, String) -> Void
        var onCancel: () -> Void
        
        @State private var email: String = ""
        @State private var password: String = ""
        @State private var errorMessage: String = ""
        
        var body: some View {
            ZStack {
                // Background Image
                Image("neon")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all) // Ensures the image covers the entire screen
                
                // Foreground Content
                VStack(spacing: 20) {
                    Text("Reauthenticate")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            SoundManager.shared.playTransitionSound()
                            onCancel()
                        }
                        .foregroundColor(.red)
                        .padding()
                        
                        Button("Authenticate") {
                            if email.isEmpty || password.isEmpty {
                                SoundManager.shared.playWarningSound()
                                errorMessage = "Both fields are required."
                            } else {
                                onAuthenticate(email, password)
                            }
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                }
                .padding()
                .frame(width: 300) // Adjust size of the dialog
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
            }
        }
    }
    // MARK: - Preview
    struct Profile_Previews: PreviewProvider {
        static var previews: some View {
            Profile(profileViewModel: ProfileViewModel.mock)
                .previewLayout(.sizeThatFits)
                .background(Color.gray)
        }
    }
}
