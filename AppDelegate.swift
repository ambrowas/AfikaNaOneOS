import UIKit
import UserNotifications
import Firebase
import FirebaseInAppMessaging
import FirebaseDatabase
import FirebaseAuth
import FirebaseAnalytics


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
            Analytics.logEvent("test_event", parameters: ["status": "success"])
                }
        requestNotificationPermission()
        return true
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        print("Requesting notification permission")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied")
                DispatchQueue.main.async {
                    self.showNotificationPermissionAlert()
                }
            }
        }
    }
    
    func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "Enable Notifications",
            message: "Enable notifications to receive updates and game-related messages. Go to Settings to enable notifications.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let topController = getTopViewController() {
            topController.present(alert, animated: true)
        }
    }
    
    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return nil }
        var topController = window.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }
    
    // MARK: - Firebase Installation ID
    func fetchAndStoreFirebaseInstallationID() {
        Installations.installations().installationID { [weak self] installationID, error in
            if let error = error {
                print("Error fetching Installation ID: \(error.localizedDescription)")
                return
            }
            if let installationID = installationID {
                print("Firebase Installation ID: \(installationID)")
                UserDefaults.standard.set(installationID, forKey: "firebaseInstallationID")
                self?.updateFirebaseInstallationIDInDatabase(installationID)
            }
        }
    }
    
    func updateFirebaseInstallationIDInDatabase(_ installationID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No logged-in user. Skipping Installation ID update.")
            return
        }
        
        let ref = Database.database().reference()
        ref.child("user").child(userID).updateChildValues(["InstallationID": installationID]) { error, _ in
            if let error = error {
                print("Error updating Installation ID: \(error.localizedDescription)")
            } else {
                print("Installation ID updated successfully in Firebase Database")
            }
        }
    }
    
    // MARK: - Device Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
        UserDefaults.standard.set(token, forKey: "deviceToken")
        updateUserDeviceTokenInDatabase(token: token)
    }
    
    func updateUserDeviceTokenInDatabase(token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No logged-in user. Skipping Device Token update.")
            return
        }
        
        let ref = Database.database().reference()
        ref.child("user").child(userID).updateChildValues(["Token": token]) { error, _ in
            if let error = error {
                print("Error updating Device Token: \(error.localizedDescription)")
            } else {
                print("Device Token updated successfully in Firebase Database")
            }
        }
    }
    
    // MARK: - In-App Messaging Display Delegate
    func messageClicked(_ inAppMessage: InAppMessagingDisplayMessage) {
        if let cardMessage = inAppMessage as? InAppMessagingCardDisplay {
            print("In-app card message clicked with title: \(cardMessage.title ?? "No Title")")
        } else if let modalMessage = inAppMessage as? InAppMessagingModalDisplay {
            print("In-app modal message clicked with title: \(modalMessage.title ?? "No Title")")
        } else {
            print("In-app message clicked: Unknown message type.")
        }
    }
    
    func messageDismissed(_ inAppMessage: InAppMessagingDisplayMessage, dismissType: InAppMessagingDismissType) {
        if let cardMessage = inAppMessage as? InAppMessagingCardDisplay {
            print("In-app card message dismissed with title: \(cardMessage.title ?? "No Title")")
        } else if let modalMessage = inAppMessage as? InAppMessagingModalDisplay {
            print("In-app modal message dismissed with title: \(modalMessage.title ?? "No Title")")
        } else {
            print("In-app message dismissed: Unknown message type.")
        }
    }
    
    func impressionDetected(for inAppMessage: InAppMessagingDisplayMessage) {
        if let cardMessage = inAppMessage as? InAppMessagingCardDisplay {
            print("Impression detected for in-app card message with title: \(cardMessage.title ?? "No Title")")
        } else if let modalMessage = inAppMessage as? InAppMessagingModalDisplay {
            print("Impression detected for in-app modal message with title: \(modalMessage.title ?? "No Title")")
        } else {
            print("Impression detected for in-app message: Unknown message type.")
        }
    }
    
    func displayError(for inAppMessage: InAppMessagingDisplayMessage, error: Error) {
        if let cardMessage = inAppMessage as? InAppMessagingCardDisplay {
            print("Error displaying in-app card message with title: \(cardMessage.title ?? "No Title"), error: \(error.localizedDescription)")
        } else if let modalMessage = inAppMessage as? InAppMessagingModalDisplay {
            print("Error displaying in-app modal message with title: \(modalMessage.title ?? "No Title"), error: \(error.localizedDescription)")
        } else {
            print("Error displaying in-app message: \(error.localizedDescription)")
        }
    }
}
