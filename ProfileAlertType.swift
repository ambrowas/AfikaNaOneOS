import Foundation

enum ProfileAlertType: Identifiable {
    case success(String)
    case error(String)
    case profileImageUpdated
    
    
    var id: String {
        switch self {
        case .success(let message), .error(let message):
            return message
        case .profileImageUpdated:
            return "profileImageUpdated"
        }
    }
    
    var message: String {
        switch self {
        case .success(let message), .error(let message):
            return message
        case .profileImageUpdated:
            return "Profile picture updated successfully!"
        }
    }
    
    var title: String {
        switch self {
        case .success, .profileImageUpdated:
            return "Success"
        case .error:
            return "Error"
        }
    }
}

