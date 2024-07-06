//
//  LuckyVicky_iOSApp.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct LuckyVicky_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var navigationManager = NavigationManager<Destination>()
    @StateObject private var fsManager = FirestoreManager()
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationManager.paths) {
                if isLoggedIn {
                    ContentView(fsManager: fsManager)
                } else {
                    AuthView(fsManager: fsManager)
                }
            }
        }
    }
}
