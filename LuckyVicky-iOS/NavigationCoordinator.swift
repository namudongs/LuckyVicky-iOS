//
//  NavigationCoordinator.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func goToRoot() {
        path.removeLast(path.count)
    }
    
    func goBack() {
        path.removeLast()
    }
    
    func goToTransView() {
        path.append("Trans")
    }
}
