//
//  LuckyVicky_iOSApp.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import FirebaseCore
import SwiftUI

/// AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Firebase 로깅 설정
    FirebaseConfiguration.shared.setLoggerLevel(.error)
    setenv("GRPC_VERBOSITY", "ERROR", 1)
    
    
    FirebaseApp.configure()
    
    return true
  }
}

/// 앱의 진입점 구조체입니다.
@main
struct AppEntry: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
  private let container = DependencyContainer.shared
  
  var body: some Scene {
    WindowGroup {
      if isLoggedIn {
        ContentView(viewModel: container.makeContentViewModel())
      } else {
        AuthView(viewModel: container.makeAuthViewModel())
      }
    }
  }
}
