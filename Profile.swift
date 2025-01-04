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
                    detailsTable
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
            .background(Circle().fill((Color(red: 121/255, green: 125/255, blue: 98/255)))) 
            .frame(width: 100, height: 100)
            .overlay(
                Text("\(profileViewModel.positionInLeaderboard)")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            )
            .position(x: 340, y: -60)
    }
    
    // MARK: - Details Table
    private var detailsTable: some View {
        VStack(spacing: 4) { // ✅ Increased spacing for better readability
            UpdatedTextRowView(title: "NAME:", value: profileViewModel.fullname.uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "EMAIL:", value: profileViewModel.email.uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "TELEPHONE:", value: profileViewModel.telefono.uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "CITY:", value: profileViewModel.ciudad.uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "COUNTRY:", value: profileViewModel.pais.uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "RECORD:", value: "\(profileViewModel.highestScore)".uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "TOTAL SCORE:", value: "\(profileViewModel.accumulatedPuntuacion) POINTS".uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "TOTAL CORRECT ANSWERS:", value: "\(profileViewModel.accumulatedAciertos)".uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "TOTAL INCORRECT ANSWERS:", value: "\(profileViewModel.accumulatedFallos)".uppercased())
            Divider().background(Color.white.opacity(0.7))

            UpdatedTextRowView(title: "TOTAL CASH:", value: "\(profileViewModel.accumulatedPuntuacion) AFROS".uppercased())
        }
        .padding()
        .background(
            Color(red: 121/255, green: 125/255, blue: 98/255).opacity(0.50) // ✅ 50% Transparent Background
                .blur(radius: 5) // ✅ Soft Blur for a Modern Look
        )
        .cornerRadius(15) // ✅ Rounded Corners
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.black.opacity(0.7), lineWidth: 2) // ✅ Full white outer border for consistency
        )
        .shadow(color: Color.white.opacity(0.15), radius: 5, x: 0, y: 5) // ✅ Subtle Glow Effect
        .frame(width: 350, height: 400) // ✅ Fixed height, no scrolling
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
                    .background(Color(red: 121/255, green: 125/255, blue: 98/255))
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
                    .background(Color(red: 121/255, green: 125/255, blue: 98/255))
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
    struct UpdatedTextRowView: View {
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white) // ✅ Title always white
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 180, alignment: .leading) // ✅ Ensures title fits in one row

                Spacer() // ✅ Adds spacing between title and value

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white) // ✅ Value always white
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 120, alignment: .trailing) // ✅ Ensures value fits in one row
            }
            .padding(.vertical, 8) // ✅ More vertical spacing for better readability
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.3)) // ✅ Consistent semi-transparent background
            .cornerRadius(5) // ✅ Smooth rounded edges for a modern look
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1) // ✅ Full white border around the row
            )
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
                .background(Color(red: 121/255, green: 125/255, blue: 98/255))
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
