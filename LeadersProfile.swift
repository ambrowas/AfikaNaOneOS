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
                                FlashingText(text: "\(viewModel.user?.positionInLeaderboard ?? 0)", shouldFlash: true)
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
                            TextRowView(title: "NAME", value: user.fullname)
                            TextRowView(title: "CITY", value: user.ciudad)
                            TextRowView(title: "COUNTRY", value: user.pais)
                            TextRowView(title: "TOTAL SCORE", value: "\(user.accumulatedPuntuacion)")
                            TextRowView(title: "TOTAL CORRECT ANSWERS", value: "\(user.accumulatedAciertos)")
                            TextRowView(title: "TOTAL WRONG ANSWERS", value: "\(user.accumulatedFallos)")
                            TextRowView(title: "RECORD", value: "\(user.highestScore)")
                            TextRowView(title: "TOTAL CASH", value: "\(user.accumulatedPuntuacion ) AFROS")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 50)
                    
                    
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
    
    struct LeadersProfile_Previews: PreviewProvider {
        static var previews: some View {
            LeadersProfile(userId: "DummyUserId")
            
        }
    }
    

    
    struct TextRowView: View {
        var title: String
        var value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
                Text(value)
                    .foregroundColor(Color.white)
                    .bold()
            }
          
            
        }
        
    }
    
   
    
}
