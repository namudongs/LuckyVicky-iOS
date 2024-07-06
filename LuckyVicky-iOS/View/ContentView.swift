//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import NavigationTransitions

struct ContentView: View {
    // MARK: - 프로퍼티
    @StateObject var manager = GPTManager()
    @FocusState private var isFocused: Bool
    @State private var isGenerating: Bool = false
    @State private var isTranslate: Bool = false
    @State private var originalText: String = ""
    @State private var rotation: Double = 0.0
    
    // MARK: - 뷰
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxHeight: isTranslate ? geo.size.height / 4 : .infinity)
                    .overlay {
                        VStack {
                            TextField("오늘 안좋은 일이 있었나요?",
                                      text: $originalText.max(60), axis: .vertical)
                            .frame(height: 200)
                            .foregroundColor(.black.opacity(0.7))
                            .focused($isFocused)
                            .font(.system(size: 22, weight: .regular))
                            .multilineTextAlignment(.center)
                            .submitLabel(.return)
                            .padding(70)
                            .disabled(isTranslate)
                            
                            // TODO: - 현재 글자 수 보여주기
                            // TODO: - 글자 수 넘어가면 경고 띄우기
                            // TODO: - 글자 수 부족하거나 글이 없으면 입력하지 못하게 하기
                        }
                    }
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(maxHeight: isTranslate ? .infinity : geo.size.height / 4)
                    .overlay {
                        VStack(spacing: 0) {
                            Spacer()
                            if isTranslate {
                                ScrollView {
                                    // TODO: 공유하기와 복사하기 기능 구현
                                    Text(manager.response)
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .padding(.horizontal, 50)
                                }
                                .frame(maxHeight: geo.size.height / 2)
                                Spacer()
                            }
//                            Spacer()
                            VStack {
                                Image(.luckyvicky)
                                    .resizable()
                                    .scaledToFit()
                                    .blendMode(.screen)
                                    .frame(width: 50)
                                    .rotationEffect(.degrees(rotation))
                                
                                Text(isTranslate ? "돌아가기" : "원영적 사고로 변환하기")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                if isTranslate {
                                    withAnimation {
                                        originalText = ""
                                        manager.response = ""
                                        isGenerating = false
                                        isTranslate = false
                                        rotation = 0
                                    }
                                } else {
                                    withAnimation {
                                        isTranslate = true
                                    }
                                    startTranslate()
                                    manager.sendMessage(from: originalText) { result in
                                        switch result {
                                        case .success:
                                            completeTranslate()
                                        case .failure(let error):
                                            print("오류 발생: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                            .disabled(isGenerating)
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
}

// MARK: - 함수
extension ContentView {
    // TODO: - 럭키비키로 변환하는 로직
    private func startTranslate() {
        print("start Translate")
        isGenerating = true
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
    
    private func completeTranslate() {
        print("complete Translate")
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isGenerating = false
        withAnimation {
            rotation = 45
        }
    }
}

#Preview {
    ContentView()
}
