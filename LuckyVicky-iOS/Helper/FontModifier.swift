//
//  FontModifier.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/26/24.
//

import SwiftUI

enum NanumSquareNeoWeight {
    case regular
    case bold
    case extrabold
    
    var fontName: String {
        switch self {
        case .regular:
            return "NanumSquareNeoTTF-bRg"
        case .bold:
            return "NanumSquareNeoTTF-cBd"
        case .extrabold:
            return "NanumSquareNeoTTF-dEb"
        }
    }
}

extension View {
    func nanumsquareneo(weight: NanumSquareNeoWeight, size: CGFloat = 16) -> some View {
        self.modifier(NanumSquareNeoFont(weight: weight, size: size))
    }
}

struct NanumSquareNeoFont: ViewModifier {
    let weight: NanumSquareNeoWeight
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom(weight.fontName, size: size))
    }
}
