    import SwiftUI
    import UIKit
    import FirebaseDatabase
    import FirebaseStorage
    import FirebaseFirestore
    import FirebaseAuth

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var profileViewModel: ProfileViewModel
    
    let storageRef: StorageReference
    let ref: DatabaseReference
    
    init(profileViewModel: ProfileViewModel, selectedImage: Binding<UIImage?>, storageRef: StorageReference, ref: DatabaseReference) {
        self.profileViewModel = profileViewModel
        self._selectedImage = selectedImage
        self.storageRef = storageRef
        self.ref = ref
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.uploadImage(image: image)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func uploadImage(image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user signed in")
            return
        }
        
        let profileImageService = ProfileImageService(storageRef: storageRef, ref: ref)
        profileImageService.uploadImage(image: image, userId: userId) { result in
            switch result {
            case .success(let downloadURL):
                self.updateUserProfileImage(downloadURL: downloadURL)
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.profileViewModel.alertType = .imageChangeError(error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUserProfileImage(downloadURL: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No user signed in")
            return
        }

        let userRef = ref.child("user").child(userID)

        userRef.updateChildValues(["profilePicture": downloadURL]) { (error, ref) in
            if let error = error {
                print("Error updating data: \(error)")
                DispatchQueue.main.async {
                    self.profileViewModel.alertType = .imageChangeError("Failed to update profile image")
                }
            } else {
                print("Profile image updated successfully")
                DispatchQueue.main.async {
                    self.profileViewModel.alertType = .imageChangeSuccess
                }
            }
        }
    }
}
