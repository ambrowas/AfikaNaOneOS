//
//  FirebaseImageView.swift
//  AfrikaNaOne
//
//  Created by INICIATIVAS ELEBI on 12/8/24.
//
import FirebaseStorage
import UIKit
import SwiftUICore
import SwiftUI

struct FirebaseImageView: View {
    @State private var image: UIImage?
    var storagePath: String

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
                .onAppear {
                    fetchImage()
                }
        }
    }

    private func fetchImage() {
        let storageRef = Storage.storage().reference(forURL: storagePath)
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let data = data, let uiImage = UIImage(data: data) {
                self.image = uiImage
            } else {
                print("Error fetching image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
