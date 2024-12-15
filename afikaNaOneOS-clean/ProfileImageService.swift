import Foundation
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class ProfileImageService {
    
    let storageRef: StorageReference
    let ref: DatabaseReference
    
    init(storageRef: StorageReference, ref: DatabaseReference) {
        self.storageRef = storageRef
        self.ref = ref
    }
    
    func uploadImage(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let imageData = image.jpegData(compressionQuality: 0.8)
           let imageRef = storageRef.child("profileImages/\(userId).jpg")

           let metadata = StorageMetadata()
           metadata.contentType = "image/jpeg"

           imageRef.putData(imageData!, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func updateUserProfileImage(downloadURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }
        
        let userRef = ref.child("user").child(userID)
        
        userRef.updateChildValues(["profilePicture": downloadURL]) { (error, ref) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
}
