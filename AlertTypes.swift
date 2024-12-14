import SwiftUI

enum AlertType: Identifiable {
    case userCreated, emptyFields, incorrectPassword, invalidEmail, loginSuccess, generalError

    var id: Int {
        switch self {
        case .userCreated:
            return 1
        case .emptyFields:
            return 2
        case .incorrectPassword:
            return 3
        case .invalidEmail:
            return 4
        case .loginSuccess:
            return 5
        case .generalError:
            return 6
        }
    }
}

