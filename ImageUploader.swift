import SwiftUI
import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth




    class ImageUploader: ObservableObject {
       
        
        @Published var showAlert = false
        @State private var currentAlertType: ProfileAlertType?
        @Published var alertMessage = ""
        
        let storageRef: StorageReference
        let ref: DatabaseReference
        let imageService: ProfileImageService
        
        init(storageRef: StorageReference, ref: DatabaseReference) {
                self.storageRef = storageRef
                self.ref = ref
                self.imageService = ProfileImageService(storageRef: storageRef, ref: ref)
            }
        
        
        func updateUserProfileImage(downloadURL: String) {
              imageService.updateUserProfileImage(downloadURL: downloadURL) { result in
                  switch result {
                  case .success:
                      print("Profile image updated successfully")
                      DispatchQueue.main.async {
                          self.alertMessage = "Profile image updated successfully"
                          self.currentAlertType = .success("Profile image updated successfully")
                          self.showAlert = true
                      }
                  case .failure(let error):
                      print("Error updating data: \(error)")
                      DispatchQueue.main.async {
                          self.alertMessage = "Failed to update profile image"
                          self.currentAlertType = .error("Failed to update profile image")
                          self.showAlert = true
                      }
                  }
              }
          }
      
    }



