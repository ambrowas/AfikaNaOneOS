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
                                 .background(Circle().fill(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))) // Red circle
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
                             .position(x: 90, y: -70) // Adjust position for better layout
                         }
                         

            ScrollView {
                VStack(spacing: 0) { // No spacing between rows
                    if let user = viewModel.user {
                        UpdatedTextRowView(title: "NAME", value: user.fullname.uppercased())
                        Divider()
                        UpdatedTextRowView(title: "CITY", value: user.ciudad.uppercased())
                        Divider()
                        UpdatedTextRowView(title: "COUNTRY", value: user.pais.uppercased())
                        Divider()
                        UpdatedTextRowView(title: "TOTAL SCORE", value: "\(user.accumulatedPuntuacion)".uppercased())
                        Divider()
                        UpdatedTextRowView(title: "TOTAL CORRECT ANSWERS", value: "\(user.accumulatedAciertos)".uppercased())
                        Divider()
                        UpdatedTextRowView(title: "TOTAL WRONG ANSWERS", value: "\(user.accumulatedFallos)".uppercased())
                        Divider()
                        UpdatedTextRowView(title: "RECORD", value: "\(user.highestScore)".uppercased())
                        Divider()
                        UpdatedTextRowView(title: "TOTAL CASH", value: "\(user.accumulatedPuntuacion) AFROS".uppercased())
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 3)
                )
                .frame(maxWidth: .infinity) // Allow the container to resize flexibly
            }
            .frame(width: 320)
            .padding(.top, 350)
            .environment(\.colorScheme, .light) // Force light mode for contrast
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
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
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
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1) // Keep text in one line
                .minimumScaleFactor(0.5) // Allow scaling down if the text is too long
                .frame(maxWidth: .infinity, alignment: .leading) // Left align with flexible width

            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
                .lineLimit(1) // Keep text in one line
                .minimumScaleFactor(0.5) // Allow scaling down if the text is too long
                .frame(maxWidth: .infinity, alignment: .trailing) // Right align with flexible width
        }
        .padding(.vertical, 8) // Add spacing for better readability
        .padding(.horizontal) // Horizontal padding for overall alignment
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
