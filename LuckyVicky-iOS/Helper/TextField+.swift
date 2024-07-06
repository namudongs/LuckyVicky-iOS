//
//  TextField+.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

extension Binding where Value == String {
    func max(_ limit: Int, showAlert: Binding<Bool>) -> Self {
        if self.wrappedValue.count > limit {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
                showAlert.wrappedValue = true
            }
        }
        return self
    }
}
