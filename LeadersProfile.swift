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
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 150)
                            .border(Color.black, width: 3)
                            .background(Color.white)
                            .padding(.top, 80)
                            .padding(.bottom, 20)
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.top)
                            .frame(width: 200, height: 150)
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
                        Circle()
                            .stroke(Color.black, lineWidth: 2) // black border
                            .background(Circle().fill(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))) // red circle
                            .frame(width: 100, height: 100)
                            .padding(.leading, 200)
                            .padding(.top, -70)
                            .overlay(
                                FlashingText(text: "\(viewModel.user?.positionInLeaderboard ?? 0)", shouldFlash: true, flashingColor: $userData.flashingColor)
                                    .foregroundColor(.white)
                                    .font(.largeTitle)
                                    .bold()
                                    .padding(.leading, 200)
                                    .padding(.top, -50)
                            )
                    } else {
                        // Fallback on earlier versions
                    }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if let user = viewModel.user {
                            UpdatedTextRowView(title: "NAME", value: user.fullname)
                            UpdatedTextRowView(title: "CITY", value: user.ciudad)
                            UpdatedTextRowView(title: "COUNTRY", value: user.pais)
                            UpdatedTextRowView(title: "TOTAL SCORE", value: "\(user.accumulatedPuntuacion)")
                            UpdatedTextRowView(title: "TOTAL CORRECT ANSWERS", value: "\(user.accumulatedAciertos)")
                            UpdatedTextRowView(title: "TOTAL WRONG ANSWERS", value: "\(user.accumulatedFallos)")
                            UpdatedTextRowView(title: "RECORD", value: "\(user.highestScore)")
                            UpdatedTextRowView(title: "TOTAL CASH", value: "\(user.accumulatedPuntuacion) AFROS")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20) // Adjust padding for better alignment
                }
                .padding(.top, 10)
                
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
                .padding(.bottom, 60)
            }
            .onAppear {
                self.viewModel.fetchUserDataFromRealtimeDatabase()
            }
        }
    }
}
// MARK: - Updated TextRowView
struct UpdatedTextRowView: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.black) // White text for title
                .lineLimit(nil) // Allow text to wrap
                .minimumScaleFactor(0.8) // Scale down if needed
                .fixedSize(horizontal: false, vertical: true) // Prevent truncation
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white) // White text for value
                .multilineTextAlignment(.trailing) // Align text to the trailing edge
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5) // Adds spacing for better appearance
        .frame(maxWidth: .infinity)
    }
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
            barrio: "New York",
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
