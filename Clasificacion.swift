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
    @Published var flashingColor: Color = .white
    private var db = Database.database().reference()
    private var timer: Timer?

    init() {
        fetchUsers()
        startFlashing()
    }

    func fetchUsers() {
        db.child("user")
            .queryOrdered(byChild: "accumulatedPuntuacion")
            .queryLimited(toLast: 20)
            .observe(.value) { snapshot in
                var newUsers = [User]()
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let user = User(snapshot: snapshot) {
                        newUsers.append(user)
                    }
                }

                DispatchQueue.main.async {
                    newUsers.sort { $0.accumulatedPuntuacion > $1.accumulatedPuntuacion }
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

        for index in users.indices {
            users[index].leaderboardPosition = currentLeaderboardPosition
            currentLeaderboardPosition += 1
        }
    }

    private func startFlashing() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.flashingColor = (self.flashingColor == .white) ? .red : .white
            }
        }
    }

    deinit {
        timer?.invalidate()
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
    @Binding var flashingColor: Color

    var body: some View {
        Text(text)
            .foregroundColor(shouldFlash ? flashingColor : .white)
    }
}

struct ClasificacionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var userData = UserData()
    let userId: String
    @State private var selectedUser: User? = nil

    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                Spacer()

                Text("GLOBAL AFRIKA NA ONE LEADERBOARD")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .foregroundColor(.white)
                    .padding(.top, 15)

                if #available(iOS 16.0, *) {
                    List {
                        Section(header: EmptyView()) {
                            ForEach(userData.users) { user in
                                Button(action: {
                                    SoundManager.shared.playTransitionSound()
                                    self.selectedUser = user
                                }) {
                                    HStack {
                                        FlashingText(
                                            text: "\(user.leaderboardPosition)",
                                            shouldFlash: user.id == userId,
                                            flashingColor: $userData.flashingColor
                                        )
                                        .font(.system(size: 12))

                                        Spacer()

                                        FlashingText(
                                            text: user.fullname,
                                            shouldFlash: user.id == userId,
                                            flashingColor: $userData.flashingColor
                                        )
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        Spacer()

                                        FlashingText(
                                            text: "\(user.accumulatedPuntuacion)",
                                            shouldFlash: user.id == userId,
                                            flashingColor: $userData.flashingColor
                                        )
                                        .font(.system(size: 12))
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .id(userData.refreshID)
                    .environment(\.colorScheme, .light)
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                }

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
                    // Full-Screen Cover for LeadersProfile
                    .fullScreenCover(item: $selectedUser) { user in
                        LeadersProfile(userId: user.id)
                    }
        }
    }
}
    
struct ClasificacionView_Previews: PreviewProvider {
        static var previews: some View {
            ClasificacionView(userId: "DummyUserId")
        }
    }
    


