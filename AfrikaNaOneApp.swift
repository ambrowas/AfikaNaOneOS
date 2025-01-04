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
        //testDatabaseAccess()
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

   

    var body: some Scene {
        WindowGroup {
            FlashView()
                .environmentObject(authService) // Pass AuthService to all child views
                .tint(Color(red: 96/255, green: 108/255, blue: 56/255)) // Global accent color
                    }
        
    }
}
