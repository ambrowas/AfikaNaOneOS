import SwiftUI
import FirebaseDatabase
import FirebaseStorage
import Foundation
import FirebaseAuth
import Firebase

final class LeadersProfileViewModel: ObservableObject {
    @Published var user: ProfileUser?
    private let userId: String
    @Published var profileImageData: Data?
    @Published var flagUrl: String?
    

    init(userId: String) {
           self.userId = userId
           fetchUserDataFromRealtimeDatabase()
       }
    
    func fetchUserDataFromRealtimeDatabase() {
           let ref = Database.database().reference().child("user").child(userId)
           ref.observeSingleEvent(of: .value) { snapshot in
               if let value = snapshot.value as? [String: Any] {
                   let fullname = value["fullname"] as? String ?? "Unknown"
                   let ciudad = value["ciudad"] as? String ?? "Unknown"
                   let pais = value["pais"] as? String ?? "Unknown"
                   let positionInLeaderboard = value["positionInLeaderboard"] as? Int ?? 0
                   let accumulatedPuntuacion = value["accumulatedPuntuacion"] as? Int ?? 0
                   let accumulatedAciertos = value["accumulatedAciertos"] as? Int ?? 0
                   let accumulatedFallos = value["accumulatedFallos"] as? Int ?? 0
                   let highestScore = value["highestScore"] as? Int ?? 0
                   let profilePicture = value["profilePicture"] as? String ?? ""
                   let flagUrl = value["flagUrl"] as? String
                   
                   DispatchQueue.main.async {
                       self.user = ProfileUser(
                           id: self.userId,
                           fullname: fullname,
                           ciudad: ciudad,
                           pais: pais,
                           positionInLeaderboard: positionInLeaderboard,
                           accumulatedPuntuacion: accumulatedPuntuacion,
                           accumulatedAciertos: accumulatedAciertos,
                           accumulatedFallos: accumulatedFallos,
                           highestScore: highestScore,
                           profilePictureURL: profilePicture
                       )
                       self.flagUrl = flagUrl
                       self.fetchProfileImage(urlString: profilePicture)
                   }
               }
           }
       }
    
    
    func fetchProfileImage(urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Failed to fetch image:", error ?? "No error information")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageData = data
            }
        }.resume()
    }
    
    
}
