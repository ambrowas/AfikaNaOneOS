import SwiftUI
import AVFAudio
import AVFoundation



struct MenuPrincipal: View {
    @State private var showMenuModoLibre = false
    @State private var showMenuModoCompeticion = false
    @State private var showContactanosView = false
    @State private var showingUpdateAlert = false
    @State private var updateAlertMessage = ""
    @State private var glowColor = Color.blue
    @Binding var player: AVAudioPlayer?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 150)
                    .padding(.top, 105)
                    .shadow(color: glowColor.opacity(0.8), radius: 10, x: 0.0, y: 0.0)
                
                
                
                Button("SINGLE MODE") {
                    showMenuModoLibre = true
                    SoundManager.shared.playTransitionSound()
                    
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 280, height: 75)
                .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 3)
                )
                
                Button("COMPETITION MODE") {
                    showMenuModoCompeticion = true
                    SoundManager.shared.playTransitionSound()
                   
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 280, height: 75)
                .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 3)
                )
                
                Button("CONTACT US") {
                    showContactanosView = true
                    SoundManager.shared.playTransitionSound()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 280, height: 75)
                .background(Color(red: 121/255, green: 125/255, blue: 98/255))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 3)
                )
                
                Spacer()
                
                Text("2024.INICIATIVAS ELEBI")
                    .foregroundColor(.black)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text("ALL RIGHTS RESERVED")
                    .foregroundColor(.black)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.top, -10.0)
            }
            .padding()
        }
        .onAppear {
            checkAppVersionAndUpdate()
        }
        .onReceive(timer) { _ in
            glowColor = glowColor == .blue ? .green : .blue
        }
        .fullScreenCover(isPresented: $showMenuModoLibre) {
            MenuModoLibre()
        }
        .fullScreenCover(isPresented: $showMenuModoCompeticion) {
            MenuModoCompeticion(userId: "DummyuserId", userData: UserData(), viewModel: MenuModoCompeticionViewModel())
        }
        .fullScreenCover(isPresented: $showContactanosView) {
            ContactanosView()
        }
        .alert(isPresented: $showingUpdateAlert) {
            Alert(
                title: Text("Update Available"),
                message: Text(updateAlertMessage),
                dismissButton: .default(Text("Update"), action: {
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/6739022933"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                })
            )
        }
    }
    
    
    func checkAppVersionAndUpdate() {
        let appID = "6739022933" // Replace with your actual App ID
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appID)") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching app data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreInfo = results.first,
                   let latestVersion = appStoreInfo["version"] as? String,
                   let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    
                    // Print both versions for debugging
                    print("App Store version: \(latestVersion)")
                    print("Current version: \(currentVersion)")
                    
                    if currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending {
                        DispatchQueue.main.async {
                            self.updateAlertMessage = "Kindly upgrade to the latest version"
                            self.showingUpdateAlert = true
                        }
                    }
                }
            } catch {
                print("Error parsing JSON from App Store: \(error)")
            }
        }.resume()
    }
    
    
    struct MenuPrincipal_Previews: PreviewProvider {
        @State static var mockPlayer: AVAudioPlayer? = nil // Mock AVAudioPlayer
        
        static var previews: some View {
            MenuPrincipal(player: $mockPlayer) // Use mockPlayer as the binding
                .previewDevice("iPhone 14") // Set a specific device for preview
                .previewDisplayName("Menu Principal Preview") // Optional: Add a display name for the preview
        }
    }
}








