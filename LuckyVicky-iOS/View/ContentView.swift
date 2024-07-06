//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import AlertToast

// TODO: - FirebaseAuth 연결하고 로그인 기능 구현하기
// TODO: - User가 API 호출한 횟수 저장하고 10번 제한 걸기
// TODO: - Gemini API 연결하기
// TODO: - User가 10번 제한에 걸리면 광고 보고 해제할 수 있게 하기
// TODO: - 원영적 사고 설명 및 개발자 소개, 사용한 API 등의 저작권 표기 뷰 만들기
// TODO: - 후원 기능 구현하기

struct ContentView: View {
    // MARK: - 프로퍼티
    @StateObject var manager = GPTManager()
    @FocusState private var isFocused: Bool
    @State private var isGenerating: Bool = false
    @State private var isTranslate: Bool = false
    @State private var originalText: String = ""
    @State private var rotation: Double = 0.0
    @State private var nowTextLength: Int = 0
    @State private var showAlert: Bool = false
    @State private var showEmptyAlert: Bool = false
    @State private var showCopiedAlert: Bool = false
    @State private var showSharedAlert: Bool = false
    
    // MARK: - 뷰
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxHeight: isTranslate ? geo.size.height / 4 : .infinity)
                    .overlay {
                        VStack {
                            TextField("안좋은 일이 있었나요?",
                                      text: $originalText.max(45, showAlert: $showAlert),
                                      axis: .vertical)
                            .frame(height: 200)
                            .foregroundColor(.black.opacity(0.7))
                            .focused($isFocused)
                            .font(.system(size: 22, weight: .regular))
                            .multilineTextAlignment(.center)
                            .submitLabel(.return)
                            .padding(70)
                            .disabled(isTranslate)
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
                                    VStack {
                                        Text(manager.response)
                                            .foregroundColor(.white)
                                            .font(.system(size: 24, weight: .bold))
                                            .padding(.horizontal, 50)
                                        if !isGenerating {
                                            HStack(spacing: 15) {
                                                Spacer()
                                                Image(systemName: "clipboard")
                                                    .foregroundColor(.white)
                                                    .onTapGesture {
                                                        UIPasteboard.general.string = manager.response
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        showCopiedAlert = true
                                                    }
                                                ShareLink(item: manager.response) {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .foregroundColor(.white)
                                                }
                                                .simultaneousGesture(TapGesture().onEnded() {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    showSharedAlert = true
                                                })
                                            }
                                            .padding(.top, 10)
                                            .padding(.trailing, 50)
                                        }
                                    }
                                }
                                .frame(maxHeight: geo.size.height / 2)
                                Spacer()
                            }
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
                                if isTranslate {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    withAnimation {
                                        originalText = ""
                                        manager.response = ""
                                        isGenerating = false
                                        isTranslate = false
                                        rotation = 0
                                    }
                                } else {
                                    if originalText.isEmpty {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        showEmptyAlert = true
                                    } else {
                                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
            // MARK: - 토스트
            .toast(isPresenting: $showAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.circle.fill", Color.red),
                    title: "글자 수 제한을 초과했습니다."
                )
                
            }
            .toast(isPresenting: $showEmptyAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.triangle.fill", Color.yellow),
                    title: "텍스트를 입력해주세요."
                )
            }
            .toast(isPresenting: $showCopiedAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "클립보드에 복사했습니다."
                )
            }
            .toast(isPresenting: $showSharedAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "공유에 성공했습니다."
                )
            }
        }
    }
}

// MARK: - 함수
extension ContentView {
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
