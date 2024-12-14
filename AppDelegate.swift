import UIKit
import UserNotifications
import Firebase
import FirebaseInAppMessaging
import FirebaseDatabase
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, InAppMessagingDisplayDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                FirebaseApp.configure()
                return true
            }
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        // Request permission for notifications and register for remote notifications
        requestNotificationPermission()

        fetchAndStoreFirebaseInstallationID()
        
        InAppMessaging.inAppMessaging().delegate = self

        return true
    }


    func requestNotificationPermission() {
        print("Requesting notification permission")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            guard let strongSelf = self else { return }
            print("Notification permission response received")

            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }

            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission not granted, scheduling alert presentation")
                // Schedule the alert presentation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    strongSelf.showNotificationPermissionAlert()
                }
            }
        }
    }


    func showNotificationPermissionAlert() {
        print("Presenting notification permission alert")
        let alertController = UIAlertController(
            title: "Atención",
            message: "Activa las notificaciones para recibir códigos de juego y otros mensajes importantes. ¿Quieres activarlo?",
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(title: "Si", style: .default) { (_) in
            // Open app settings
            if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }

        let cancelAction = UIAlertAction(title: "No", style: .cancel)

        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        // Find the topmost view controller to present the alert
        if let topController = getTopViewController() {
            topController.present(alertController, animated: true)
            print("Notification permission alert presented")
        } else {
                    print("Unable to find top view controller to present alert")
        }
    }

    func getTopViewController() -> UIViewController? {
        // Access the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
            return nil
        }

        // Find the key window within the window scene
        guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }

        // Traverse the view controller hierarchy to find the topmost view controller
        var topController = keyWindow.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }

    
    func fetchAndStoreFirebaseInstallationID() {
        Installations.installations().installationID { (installationID, error) in
            if let error = error {
                print("Error fetching installation ID: \(error)")
                return
            }
            if let installationID = installationID {
                // Save the FID in UserDefaults
                UserDefaults.standard.set(installationID, forKey: "firebaseInstallationID")
                // Update in database if user is logged in
                self.updateFirebaseInstallationIDInDatabaseIfNeeded(installationID)
            }
        }
    }
    
    
    func updateFirebaseInstallationIDInDatabaseIfNeeded(_ installationID: String) {
        if let userID = Auth.auth().currentUser?.uid {
            // Reference to your database
            let ref = Database.database().reference()

            // Update the installation ID in the database
            ref.child("user").child(userID).updateChildValues(["InstallationID": installationID]) { error, _ in
                if let error = error {
                    print("Error saving installation ID to database: \(error.localizedDescription)")
                } else {
                    print("Installation ID successfully saved to database")
                }
            }
        }
    }


    func updateUserDeviceTokenInDatabase(token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in, cannot update device token")
            return
        }

        // Reference to your Firebase database
        let ref = Database.database().reference()

        // Update the token in the database
        ref.child("user").child(userID).updateChildValues(["Token": token]) { error, _ in
            if let error = error {
                print("Error saving token to database: \(error.localizedDescription)")
            } else {
                print("Device token successfully saved to database for user ID: \(userID)")
                // Optionally, clear the token from UserDefaults after successful upload
                UserDefaults.standard.removeObject(forKey: "deviceToken")
            }
        }
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

        // Save the token in UserDefaults
        UserDefaults.standard.set(token, forKey: "deviceToken")

        // If the user is already logged in, update the token in the database
        if Auth.auth().currentUser != nil {
            updateUserDeviceTokenInDatabase(token: token)
        }
    }

    

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            print("Will present notification: \(notification)")
            completionHandler([.banner, .sound])
        }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
          print("Did receive response to notification: \(response)")
          let notification = response.notification
          logNotificationReceived(notification: notification)
          completionHandler()
      }
    
    private func logNotificationReceived(notification: UNNotification) {
        print("Logging received notification: \(notification)")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not logged in, deferring notification logging.")
            return  // Exit early if the user is not logged in
        }

        // Extract the message ID from the notification
        let userInfo = notification.request.content.userInfo
        guard let messageID = userInfo["gcm.message_id"] as? String else {
            print("Message ID not found")
            return
        }

        // Get the current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateReceived = dateFormatter.string(from: Date())

        // Reference to your Firebase database
        let ref = Database.database().reference()

        // Prepare the data to be saved
        let notificationData: [String: Any] = ["messageID": messageID, "dateReceived": dateReceived]

        // Update the latest notification data under the user's node
        ref.child("user").child(userID).child("latestNotification").setValue(notificationData) { error, _ in
            if let error = error {
                print("Error updating latest notification data in database: \(error.localizedDescription)")
            } else {
                print("Latest notification data successfully updated in database")
            }
        }
    }
    
    func attemptToUpdateDeviceTokenInDatabase() {
        if let token = UserDefaults.standard.string(forKey: "deviceToken") {
            updateUserDeviceTokenInDatabase(token: token)
        }
    }
    
    // MARK: - InAppMessagingDisplayDelegate

    func messageClicked(_ inAppMessage: InAppMessagingDisplayMessage) {
        print("In-app message clicked: \(inAppMessage)")
        // Handle in-app message click
    }

    func messageDismissed(_ inAppMessage: InAppMessagingDisplayMessage, dismissType: InAppMessagingDismissType) {
        print("In-app message dismissed: \(inAppMessage)")
        // Handle in-app message dismissal
    }

    func impressionDetected(for inAppMessage: InAppMessagingDisplayMessage) {
        print("Impression for in-app message detected: \(inAppMessage)")
        // Handle in-app message impression
    }

    func displayError(for inAppMessage: InAppMessagingDisplayMessage, error: Error) {
        print("Error displaying in-app message: \(inAppMessage), error: \(error)")
        // Handle errors in displaying in-app message
    }

  }

