//
//  LuckyVicky_iOSApp.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

@main
struct LuckyVicky_iOSApp: App {
    @StateObject private var coordinator = NavigationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                ContentView()
                    .environmentObject(coordinator)
            }
        }
    }
}
