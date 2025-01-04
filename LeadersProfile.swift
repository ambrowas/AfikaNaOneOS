import SwiftUI
import FirebaseDatabase
import FirebaseStorage

struct LeadersProfile: View {
    @StateObject private var viewModel: LeadersProfileViewModel
    @State private var shouldShowMenuModoCompeticion = false
    @Environment(\.presentationMode) var presentationMode
    @State private var userData: UserData = UserData()
    @State private var showSheet: Bool = false
    @State private var goToMenuCompeticion: Bool = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: LeadersProfileViewModel(userId: userId))
    }

    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                 // Profile Picture and Circle
                 VStack(spacing: 10) {
                     if let profileImageData = viewModel.profileImageData,
                        let uiImage = UIImage(data: profileImageData) {
                         // Resize the image to fit within the target frame
                         let resizedImage = resizeImageToFit(image: uiImage, targetSize: CGSize(width: 250, height: 200))
                         
                         Image(uiImage: resizedImage)
                             .resizable()
                             .scaledToFit() // Ensures the resized image fits proportionally
                             .frame(width: 250, height: 200) // Target frame size
                             .border(Color.black, width: 3)
                             .background(Color.white)
                             .clipped() // Ensures no overflow outside the frame
                             .padding(.top, 80)
                             .padding(.bottom, 20)
                     } else {
                         Image(systemName: "person.fill")
                             .resizable()
                             .scaledToFit() // Ensure placeholder fits proportionally
                             .frame(width: 200, height: 150) // Placeholder frame size
                             .border(Color.black, width: 3)
                             .foregroundColor(.gray)
                             .overlay(
                                 VStack {
                                     Text("Profile picture")
                                         .font(.subheadline)
                                         .foregroundColor(.black)
                                }
                            )
                    }

                     if #available(iOS 16.0, *) {
                         HStack {
                             Spacer() // Pushes the circle to the right
                             Circle()
                                 .stroke(Color.black, lineWidth: 2) // Black border
                                 .background(Circle().fill((Color(red: 121/255, green: 125/255, blue: 98/255)))) 
                                 .frame(width: 100, height: 100)
                                 .overlay(
                                     FlashingText(text: "\(viewModel.user?.positionInLeaderboard ?? 0)", shouldFlash: true, flashingColor: $userData.flashingColor)
                                         .foregroundColor(.white)
                                         .font(.largeTitle)
                                         .bold()
                                 )
                                 .padding(.trailing, 40) // Reduce padding to move it left/ Optional padding for extra spacing from the edge
                         }
                         .padding(.top, -90) // Adjust vertical positioning as needed
                    } else {
                        // Fallback on earlier versions
                    }
                }
                // Flag Section
                             ZStack {
                                 // Placeholder for flag image
                                 Rectangle()
                                     .fill(Color.black)
                                     .frame(width: 50, height: 47)

                                 if let flagUrl = viewModel.flagUrl {
                                     AsyncImage(url: URL(string: flagUrl)) { image in
                                         image
                                             .resizable()
                                             .scaledToFit()
                                             .frame(width: 58, height: 44)
                                     } placeholder: {
                                         Image("other")
                                             .resizable()
                                             .scaledToFit()
                                             .frame(width: 58, height: 44)
                                     }
                                 } else {
                                     // Placeholder "other" flag if no flag URL is provided
                                     Image("other")
                                         .resizable()
                                         .scaledToFit()
                                         .frame(width: 58, height: 44)
                                 }
                             }
                             .position(x: 90, y: -65) // Adjust position for better layout
                         }
                         
            ScrollView {
                VStack(spacing: 3) { // ✅ Increased spacing for better readability
                    if let user = viewModel.user {
                        UpdatedTextRowView(title: "NAME", value: user.fullname.uppercased())
                        UpdatedTextRowView(title: "CITY", value: user.ciudad.uppercased())
                        UpdatedTextRowView(title: "COUNTRY", value: user.pais.uppercased())
                        UpdatedTextRowView(title: "TOTAL SCORE", value: "\(user.accumulatedPuntuacion)".uppercased())
                        UpdatedTextRowView(title: "TOTAL CORRECT ANSWERS", value: "\(user.accumulatedAciertos)".uppercased())
                        UpdatedTextRowView(title: "TOTAL INCORRECT ANSWERS", value: "\(user.accumulatedFallos)".uppercased())
                        UpdatedTextRowView(title: "TOTAL CASH", value: "\(user.accumulatedPuntuacion) AFROS".uppercased())
                        UpdatedTextRowView(title: "RECORD", value: "\(user.highestScore)".uppercased())
                    }
                }
                .padding()
                .background(
                    Color(red: 121/255, green: 125/255, blue: 98/255).opacity(0.50) // ✅ 50% Transparent Background
                        .blur(radius: 5) // ✅ Soft Blur for a Modern Look
                )
                .cornerRadius(15) // ✅ More Rounded Corners
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.7), lineWidth: 6) // ✅ White Border Around Whole Table
                )
                .shadow(color: Color.white.opacity(0.15), radius: 5, x: 0, y: 5) // ✅ Subtle Glow Effect
            }
            .frame(width: 320)
            .padding(.top, 350)
            .environment(\.colorScheme, .light) // ✅ Keeps Light Mode for Best Contrast
                // Volver Button
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 55)
                        .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .padding(.top, 650)
            }
            .onAppear {
                self.viewModel.fetchUserDataFromRealtimeDatabase()
            }
        }
    }

struct UpdatedTextRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) { // ✅ Adjusted spacing for better readability
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1) // ✅ Prevents text from wrapping
                .minimumScaleFactor(0.6) // ✅ Ensures text shrinks instead of cutting off
                .truncationMode(.tail) // ✅ Cuts text properly if too long
                .frame(width: 180, alignment: .leading) // ✅ Allocates more space to titles

            Spacer() // ✅ Creates space between title and value

            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .truncationMode(.tail)
                .frame(width: 120, alignment: .trailing) // ✅ Allocates space for values
        }
        .padding(.vertical, 8) // ✅ Increased vertical spacing
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.3)) // ✅ Ensures visibility and contrast
        .cornerRadius(5) // ✅ Smooth edges for a modern look
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.7), lineWidth: 1) // ✅ Clear white border
        )
    }
}

// MARK: - Helper Function
private func resizeImageToFit(image: UIImage, targetSize: CGSize) -> UIImage {
    let originalSize = image.size
    
    // Calculate the aspect ratio to fit the image within the target size
    let widthRatio = targetSize.width / originalSize.width
    let heightRatio = targetSize.height / originalSize.height
    let scaleFactor = min(widthRatio, heightRatio)
    
    let newSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
    let rect = CGRect(origin: .zero, size: newSize)
    
    // Create a graphics context for resizing
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(in: rect)
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage ?? image
}

// MARK: - Preview
struct LeadersProfile_Previews: PreviewProvider {
    static var previews: some View {
        LeadersProfile(userId: "DummyUserId")
            .environmentObject(LeadersProfileViewModel.mock())
            .previewLayout(.sizeThatFits)
            .previewDisplayName("LeadersProfile Preview")
    }
}

// MARK: - Mock Extension
extension LeadersProfileViewModel {
    static func mock() -> LeadersProfileViewModel {
        let mockViewModel = LeadersProfileViewModel(userId: "DummyUserId")
        mockViewModel.user = ProfileUser(
            id: "MockId",
            fullname: "John Doe",
            ciudad: "USA",
            pais: "https://example.com/mock-profile-picture.png",
            positionInLeaderboard: 10000,
            accumulatedPuntuacion: 150,
            accumulatedAciertos: 20,
            accumulatedFallos: 999,
            highestScore: 1, profilePictureURL: "https://example.com/mock-profile-picture.png"
        )
        return mockViewModel
    }
}
