//
//  AfrikaNaOneApp.swift
//  AfrikaNaOne
//
//  Created by ELEBI on 11/30/24.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth


@main
struct AfrikaNaOneApp: App {
    @StateObject private var authService = AuthService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure()

        #if DEBUG
        //
        testDatabaseAccess()
        #endif

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    func sanitize(input: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ".#$[]")
        return input.components(separatedBy: invalidCharacters).joined(separator: "")
    }

    func testDatabaseAccess() {
        let databaseRef = Database.database().reference()
        databaseRef.child("test").setValue("Hello, Firebase!") { error, _ in
            if let error = error {
                print("Error writing to database: \(error.localizedDescription)")
            } else {
                print("Database access is configured correctly")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            FlashView()
                .environmentObject(authService) // Pass AuthService to all child views
        }
    }
}
