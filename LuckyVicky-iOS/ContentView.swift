//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import NavigationTransitions

struct ContentView: View {
    @FocusState private var isFocused: Bool
    @State private var generateComplete: Bool = false
    @State private var isTrans: Bool = false
    @State private var originalText: String = ""
    @State private var rotationTimer: Timer?
    @State private var rotation: Double = 0.0
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxHeight: isTrans ? geo.size.height / 4 : .infinity)
                    .overlay {
                        VStack {
                            TextField("오늘 있었던 일을 입력해보세요",
                                      text: $originalText.max(60), axis: .vertical)
                            .frame(height: 200)
                            .foregroundColor(.black.opacity(0.7))
                            .focused($isFocused)
                            .font(.system(size: 18, weight: .regular))
                            .multilineTextAlignment(.center)
                            .submitLabel(.return)
                            .padding(70)
                            .disabled(isTrans)
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
                                    // 복사하기 기능 구현
                                    Text("오늘 택시를 한참 기다렸는데 어떤 사람이 내 택시를 빼앗아서 탔어! 완전 황당했지! 흔들리잔앙!! 그 사람이 안 탔으면, 내가 타고 가다가 교통체증에 걸려서 더 늦었을 거라고 생각했어. 그리고 내 뒤에 온 택시가 훨씬 더 빨랐지! 덕분에 빨리 도착했어 🤭🤭 완전 럭키비키잔앙🍀오늘 택시를 한참 기다렸는데 어떤 사람이 내 택시를 빼앗아서 탔어! 완전 황당했지! 흔들리잔앙!! 그 사람이 안 탔으면, 내가 타고 가다가 교통체증에 걸려서 더 늦었을 거라고 생각했어. 그리고 내 뒤에 온 택시가 훨씬 더 빨랐지! 덕분에 빨리 도착했어 🤭🤭 완전 럭키비키잔앙🍀")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .padding(50)
                                }
                                .frame(maxHeight: geo.size.height / 2)
                                Spacer()
                            }
                            Spacer()
                            VStack {
                                Image(.luckyvicky)
                                    .resizable()
                                    .scaledToFit()
                                    .blendMode(.screen)
                                    .frame(width: 50)
//                                    .rotationEffect(isTrans ? .degrees(405) : .zero)
                                    .rotationEffect(.degrees(rotation))
                                
                                Text(isTrans ? "돌아가기" : "원영적 사고로 변환하기")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                if isTrans {
                                    withAnimation {
                                        isTrans = false
                                        rotation = 360.0
                                    }
                                } else {
                                    // TODO: - 럭키비키로 변환하는 코드
                                    withAnimation {
                                        isTrans = true
                                    }
                                    startTranslate()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        completeTranslate()
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Color.background)
            .onTapGesture {
                isFocused = false
            }
        }
    }
    
    private func startTranslate() {
        print("start Translate")
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            withAnimation(.linear(duration: 0.01)) {
                rotation += 2.7 // 0.01초마다 3.6도씩 회전 (1초에 360도)
                if rotation >= 360 {
                    rotation = 0
                }
            }
        }
    }
    
    private func completeTranslate() {
        print("complete Translate")
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        rotationTimer?.invalidate()
        rotationTimer = nil
        withAnimation(.linear(duration: 0.1)) {
            rotation = 45
        }
    }
}

#Preview {
    ContentView()
}
