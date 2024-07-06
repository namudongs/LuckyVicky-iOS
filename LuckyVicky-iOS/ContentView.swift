//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import NavigationTransitions

struct ContentView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var isTrans: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxHeight: isTrans ? geo.size.height / 4 : .infinity)
                    .overlay {
                        VStack {
                            Text("오늘 택시를 한참 기다렸는데 어떤 사람이 내 택시를 빼앗아서 탔어")
                                .foregroundColor(.black.opacity(0.3))
                                .font(.system(size: 18, weight: .semibold))
                                .padding(70)
                        }
                    }
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(maxHeight: isTrans ? .infinity : geo.size.height / 4)
                    .overlay {
                        VStack(spacing: 8) {
                            if isTrans {
                                Spacer()
                                ScrollView {
                                    Text("오늘 택시를 한참 기다렸는데 어떤 사람이 내 택시를 빼앗아서 탔어! 완전 황당했지! 흔들리잔앙!! 그 사람이 안 탔으면, 내가 타고 가다가 교통체증에 걸려서 더 늦었을 거라고 생각했어. 그리고 내 뒤에 온 택시가 훨씬 더 빨랐지! 덕분에 빨리 도착했어 🤭🤭 완전 럭키비키잔앙🍀오늘 택시를 한참 기다렸는데 어떤 사람이 내 택시를 빼앗아서 탔어! 완전 황당했지! 흔들리잔앙!! 그 사람이 안 탔으면, 내가 타고 가다가 교통체증에 걸려서 더 늦었을 거라고 생각했어. 그리고 내 뒤에 온 택시가 훨씬 더 빨랐지! 덕분에 빨리 도착했어 🤭🤭 완전 럭키비키잔앙🍀")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .padding(50)
                                }
                                .frame(maxHeight: geo.size.height / 2)
                                Spacer()
                            }
                            Spacer()
                            Image(.luckyvicky)
                                .resizable()
                                .scaledToFit()
                                .blendMode(.screen)
                                .frame(width: 50)
                                .onTapGesture {
                                    print("럭키비키 버튼 누름")
                                    withAnimation {
                                        isTrans.toggle()
                                    }
                                    // 럭키비키로 변환하는 코드
                                }
                            if !isTrans {
                                Text("원영적 사고로 변환하기")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Spacer()
                        }
                    }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Color.background)
        }
    }
}

#Preview {
    ContentView()
}
