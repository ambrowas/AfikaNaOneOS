import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import UIKit
import Combine



struct Profile: View {
    @StateObject var profileViewModel = ProfileViewModel.shared
    @State private var isImagePickerDisplayed = false
    @State private var showAlert: Bool = false
    @State private var showGestionarSesionView: Bool = false
    @State private var showMenuPrincipalView: Bool = false
    @State private var showMenuModoCompeticion: Bool = false
    @State private var showSuccessAlertImagePicker = false
    private let storageRef = Storage.storage().reference()
    private let ref = Database.database().reference()
    @State private var showCambiodeFotoAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var currentAlertType: AlertType? = nil
    @State private var scaleEffect: CGFloat = 1.0 // For the shrink-and-grow effect
    @State private var borderColor: Color = .black // Border color
    

    @Environment(\.presentationMode) var presentationMode
    
    var alertTypeBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                switch profileViewModel.alertType {
                case .deleteConfirmation, .deletionSuccess, .deletionFailure,  .imageChangeSuccess, .imageChangeError(_), .volveratras:
                    return true
                case .none:
                    return false
                }
            },
            set: { newValue in
                if !newValue {
                    profileViewModel.alertType = .none
                }
            }
        )
    }
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Group {
                    if let profileImage = profileViewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 150)
                            .border(Color.black, width: 3)
                            .background(Color.white)
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 150)
                            .border(Color.black, width: 3)
                            .foregroundColor(.gray)
                            .scaleEffect(scaleEffect)
                                                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scaleEffect)
                                                        .onAppear {
                                                            scaleEffect = 1.2 // Start the shrink-and-grow effect
                                                            borderColor = Color(hue: 1.0, saturation: 0.984, brightness: 0.699) 
                                                        }
                            .overlay(
                                VStack {
                                    Text("Profile pic")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                }
                            )
                    }
                }
                .onTapGesture {
                    self.isImagePickerDisplayed = true
                }
                
                
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .background(Circle().fill(Color(hue: 1.0, saturation: 0.984, brightness: 0.699)))
                    .frame(width: 100, height: 100)
                    .padding(.leading, 200)
                    .padding(.top, -50)
                    .overlay(
                        Text("\(profileViewModel.positionInLeaderboard)")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading, 200)
                            .padding(.top, -40)
                    )
                
                ScrollView {
                    VStack {
                        TextRowView(title: "NAME:", content: profileViewModel.fullname)
                        TextRowView(title: "EMAIL:", content: profileViewModel.email)
                        TextRowView(title: "TELEPHONE:", content: profileViewModel.telefono)
                        TextRowView(title: "CITY:", content: profileViewModel.ciudad)
                        TextRowView(title: "COUNTRY:", content: profileViewModel.pais)
                        TextRowView(title: "RECORD:", content: "\(profileViewModel.highestScore)")
                        TextRowView(title: "TOTAL SCORE:", content: "\(profileViewModel.accumulatedPuntuacion)")
                        TextRowView(title: "TOTAL CORRECT ANSWERS:", content: "\(profileViewModel.accumulatedAciertos)")
                        TextRowView(title: "TOTAL WRONG ANSWERS:", content: "\(profileViewModel.accumulatedFallos)")
                    }
                }
                .frame(width: 300, height: 400)
                .padding(.top, 50)
                .padding(.horizontal, 3)
                .padding(.bottom, -50)
                
                Button(action: {
                    if profileViewModel.profileImage == nil {
                        // If no profile picture is set, prompt the user with the alert
                        profileViewModel.alertType = .volveratras
                        showAlert = true
                    } else {
                        // If a profile picture is set, directly navigate to the desired view
                        SoundManager.shared.playTransitionSound()
                        showMenuModoCompeticion = true
                    }
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 55)
                        .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                
                .alert(item: $profileViewModel.alertType) { alertType in
                    switch alertType {
                    case .deleteConfirmation:
                        return Alert(
                            title: Text("HOLD UP"),
                            message: Text("¿You sure you want to do this? This acction cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                
                                profileViewModel.deleteUserAndNotify()
                            },
                            secondaryButton: .cancel()
                        )
                    case .deletionSuccess:
                        return Alert(
                            title: Text("USER DELETED"),
                            message: Text("Account and related data will be gone within 48 hours."),
                            dismissButton: .default(Text("OK")){
                                SoundManager.shared.playTransitionSound()
                                showMenuPrincipalView = true
                            }
                        )
                        
                    case .deletionFailure(_):
                        return Alert(
                            title: Text("ERROR"),
                            message: Text("You need to log in in order to delete the account."),
                            dismissButton: .default(Text("OK")){
                                SoundManager.shared.playTransitionSound()
                                showGestionarSesionView = true
                            }
                        )
                        
                    case .imageChangeSuccess:
                        SoundManager.shared.playMagicalSound()
                        return Alert(
                            title: Text("DJUDJU BLACK MAGIC"),
                            message: Text("Your profile pic has been updated!"),
                            dismissButton: .default(Text("OK")){
                                SoundManager.shared.playTransitionSound()
                                showMenuModoCompeticion = true
                            }
                        )
                    case .imageChangeError(let errorMessage):
                        return Alert(
                            title: Text("Error"),
                            message: Text(errorMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    case .volveratras:
                        return Alert(
                            title: Text("HOLD UP!"),
                            message: Text("Sure you wanna leave without a photo?"),
                            primaryButton: .default(Text("OK")){
                                SoundManager.shared.playTransitionSound()
                                showMenuModoCompeticion = true
                            },
                            secondaryButton: .cancel()
                            
                            
                        )
                        
                    }
                }
            }
            .fullScreenCover(isPresented: $showGestionarSesionView) {
                GestionarSesion() // Assuming GestionarSesion is a View you have defined
            }
            
            .fullScreenCover(isPresented: $showMenuPrincipalView) {
                MenuPrincipal(player: .constant(nil))
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
            
            .onChange(of: profileViewModel.alertType) { alertType in
                switch alertType {
                case .imageChangeSuccess, .imageChangeError(_):
                    // No action is needed here as the alert will be shown based on the alertType value
                    break
                default:
                    break
                }
            }
            
            
            .onAppear {
                profileViewModel.fetchProfileData()
            }
        }
    }
    
    struct TextRowView: View {
        let title: String
        let content: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)
                
                Text(content)
                    .font(.system(size: 14))
                    .padding(3)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding([.leading, .trailing])
            .environment(\.colorScheme, .light)
        }
    }
    
    struct Profile_Previews: PreviewProvider {
        static var previews: some View {
            // Set up mock data for the preview
            let profileViewModel = ProfileViewModel.shared
            profileViewModel.fullname = "John Doe"
            profileViewModel.email = "john.doe@example.com"
            profileViewModel.telefono = "+1234567890"
            profileViewModel.ciudad = "New York"
            profileViewModel.pais = "USA"
            profileViewModel.highestScore = 9999
            profileViewModel.accumulatedPuntuacion = 25000
            profileViewModel.accumulatedAciertos = 150
            profileViewModel.accumulatedFallos = 20
            profileViewModel.positionInLeaderboard = 1
            profileViewModel.profileImage = UIImage(systemName: "person.fill") // Mock image
            
            return Profile()
                .environmentObject(profileViewModel) // Inject mock data into the environment
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Profile Preview")
        }
    }
}
