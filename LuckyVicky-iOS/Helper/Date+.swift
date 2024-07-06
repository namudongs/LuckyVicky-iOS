//
//  Date+.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import Foundation

extension Date {
    func toString(format: String = "yyyy-MM-dd") -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: self)
        }
}
