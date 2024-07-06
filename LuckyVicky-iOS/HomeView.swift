//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.background)
                    .frame(height: .infinity)
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: geo.size.height / 4)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(.luckyvicky)
                                .resizable()
                                .scaledToFit()
                                .blendMode(.screen)
                                .frame(width: 50)
                            Text("원영적 사고로 변환하기")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .onTapGesture {
                        print("럭키비키 버튼 누르기")
                        // 럭키비키로 변환하는 코드
                    }
            }
            .ignoresSafeArea()
        }
        
    }
}

#Preview {
    HomeView()
}
