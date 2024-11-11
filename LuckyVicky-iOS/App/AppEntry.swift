//
//  LuckyVicky_iOSApp.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct AppEntry: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
  private let container = DependencyContainer.shared
  
  var body: some Scene {
    WindowGroup {
      if isLoggedIn {
        ContentView(container: container)
      } else {
        AuthView(container: container)
      }
    }
  }
}
