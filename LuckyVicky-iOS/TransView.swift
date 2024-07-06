//
//  TransView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

struct TransView: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 20) {
                Rectangle()
                    .fill(Color.background)
                    .frame(height: geo.size.height / 4)
                Rectangle()
                    .fill(Color.accentColor)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    TransView()
}
