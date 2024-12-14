import SwiftUI
import Firebase
import FirebaseDatabase

    struct User: Identifiable {
        var id: String
        var fullname: String
        var accumulatedPuntuacion: Int
        var leaderboardPosition: Int
        var scoreAchievedAt: Date? // making this optional
    }

    class UserData: ObservableObject {
    @Published var users = [User]()
    @Published internal var refreshID: UUID = UUID()
    
    private var db = Database.database().reference()
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        db.child("user")
            .queryOrdered(byChild: "accumulatedPuntuacion")
            .queryLimited(toLast: 20)
            .observe(.value) { (snapshot) in
                //print("Number of snapshots fetched: \(snapshot.childrenCount)")
                var newUsers = [User]()
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                        let user = User(snapshot: snapshot) {
                        newUsers.append(user)
                    } else {
                       
               }
              }
                           
                DispatchQueue.main.async {
                    // First, sort the users array by `accumulatedPuntuacion`
                    newUsers.sort { $0.accumulatedPuntuacion > $1.accumulatedPuntuacion }
                    // Then, for users with equal `accumulatedPuntuacion`, sort by `scoreAchievedAt`
                    newUsers = newUsers.sorted {
                        if $0.accumulatedPuntuacion == $1.accumulatedPuntuacion {
                            return $0.scoreAchievedAt ?? Date.distantPast > $1.scoreAchievedAt ?? Date.distantPast
                        }
                        return $0.accumulatedPuntuacion > $1.accumulatedPuntuacion
                    }
                    self.users = newUsers
                    self.updateLeaderboardPositions()
                    self.refreshID = UUID()
                }
            }
    }
    
    func updateLeaderboardPositions() {
        var currentLeaderboardPosition = 1
        
        for (index, _) in users.enumerated() {
            users[index].leaderboardPosition = currentLeaderboardPosition
            currentLeaderboardPosition += 1
        }
    }
}

extension User {
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any],
            let fullname = value["fullname"] as? String,
            let accumulatedPuntuacion = value["accumulatedPuntuacion"] as? Int else {
            print("Failed to parse required fields for snapshot: \(snapshot.key)")
            return nil
        }

        self.id = snapshot.key
        self.fullname = fullname
        self.accumulatedPuntuacion = accumulatedPuntuacion
        self.leaderboardPosition = 0 // Placeholder value, it will be updated later

        if let scoreAchievedAt = value["scoreAchievedAt"] as? Double {
            self.scoreAchievedAt = Date(timeIntervalSince1970: scoreAchievedAt)
        } else {
            self.scoreAchievedAt = nil
        }
    }
}
    
    struct FlashingText: View {
        let text: String
        let shouldFlash: Bool
        @State private var colorIndex: Int = 0
        @State private var timer: Timer? = nil
        
        var body: some View {
            Text(text)
                .multilineTextAlignment(.leading)
                .foregroundColor(getColor())
                .onAppear {
                    if shouldFlash {
                        startFlashing() 
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
        
        private func getColor() -> Color {
            let colors: [Color] = [.black, .red, .blue, .white, .green]
            return colors[colorIndex % colors.count]
        }
        
        private func startFlashing() {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                colorIndex = (colorIndex + 1) % 5
            }
        }
    }
    
struct ClasificacionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var userData = UserData()
    @State private var shouldShowMenuModoCompeticion = false
    @State private var selectedUserId: String? = nil
    let userId: String
    @StateObject private var viewModel = LeadersProfileViewModel(userId: "yourUserIdHere")
    @State private var selectedUser: User? = nil
    @State private var isShowingLeadersProfile = false

    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("GLOBAL AFRIKANAONE LEADERBOARD")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                        .foregroundColor(.black)
                        .padding(.top, 15)
                
                    List {
                        Section(header: HStack {}) {
                            ForEach(userData.users) { user in
                                Button(action: {
                                    SoundManager.shared.playTransitionSound()
                                    self.selectedUser = user
                                    self.isShowingLeadersProfile = true
                                }) {
                                    HStack {
                                        FlashingText(text: "\(user.leaderboardPosition)", shouldFlash: user.id == userId)
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        FlashingText(text: user.fullname, shouldFlash: user.id == userId)
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Spacer()
                                        FlashingText(text: "\(user.accumulatedPuntuacion)", shouldFlash: user.id == userId)
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    }
                                }
                                .listRowBackground(Color.clear) // Makes individual rows transparent
                            }
                        }
                    }
                    .id(userData.refreshID)
                    .environment(\.colorScheme, .light)
                    .listStyle(PlainListStyle()) // Removes default styling of the List
                    .background(Color.clear) // Makes the entire List background transparent`
                }
                .fullScreenCover(item: $selectedUser) { user in
                    LeadersProfile(userId: user.id)
                }
                .onAppear {
                    self.viewModel.fetchUserDataFromRealtimeDatabase()
                }

                // Button moved outside the List
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }
}

    
    struct ClasificacionView_Previews: PreviewProvider {
        static var previews: some View {
            ClasificacionView(userId: "DummyUserId")
        }
    }
    


