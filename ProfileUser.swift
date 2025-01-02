
import Foundation


struct ProfileUser: Equatable {
    let id: String
    let fullname: String
    let ciudad: String
    let pais: String
    let positionInLeaderboard: Int
    let accumulatedPuntuacion: Int
    let accumulatedAciertos: Int
    let accumulatedFallos: Int
    let highestScore: Int
    var profilePictureURL: String
    
    static func ==(lhs: ProfileUser, rhs: ProfileUser) -> Bool {
        return lhs.id == rhs.id
    }
}
