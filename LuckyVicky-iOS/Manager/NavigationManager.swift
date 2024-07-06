//
//  NavigationManager.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import SwiftUI

final class NavigationManager<T: Hashable>: ObservableObject {
    @Published var paths: [T] = []
    
    func push(_ path: T) {
        paths.append(path)
    }
    
    func pop() {
        paths.removeLast()
    }
    
    func pop(to: T) {
        guard let found = paths.firstIndex(where: { $0 == to }) else {
            return
        }
        let numToPop = (found..<paths.endIndex).count - 1
        paths.removeLast(numToPop)
    }
    
    func popToRoot() {
        paths.removeAll()
    }
}

enum Destination: Hashable {
    case LoginView
    case ContentView
}
