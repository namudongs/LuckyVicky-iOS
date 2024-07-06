//
//  TextField+.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.dropLast())
            }
        }
        return self
    }
}
