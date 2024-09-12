//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import AlertToast
import FirebaseAuth
import SwiftUI

struct ContentView: View {
    @StateObject var viewStore = ContentViewStore()
    
    // MARK: - 프로퍼티
    @Binding var isLoggedIn: Bool
    @FocusState private var isFocused: Bool
    
    // MARK: - 뷰
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxHeight: viewStore.viewState.isTranslating ? geo.size.height / 4 : .infinity)
                    .overlay {
                        VStack {
                            TextField("럭키비키하게 바꿔봐🍀",
                                      text: $viewStore.viewState.beforeText.max(45, showAlert: $viewStore.toastState.textLengthExceeded),
                                      axis: .vertical)
                            .frame(height: 200)
                            .foregroundColor(.black.opacity(0.7))
                            .focused($isFocused)
                            .nanumsquareneo(weight: .regular, size: 24)
                            .lineSpacing(5)
                            .multilineTextAlignment(.center)
                            .submitLabel(.return)
                            .padding(70)
                            .disabled(viewStore.viewState.isTranslating)
                        }
                    }
                if !viewStore.viewState.isTranslating {
                    HStack {
                        Spacer()
                        Text("오늘 사용 가능한 횟수 \(viewStore.viewState.usedUsageCounts)/\(viewStore.viewState.totalUsageCounts)")
                            .nanumsquareneo(weight: .regular, size: 12)
                            .foregroundColor(.black.opacity(0.3))
                        Spacer()
                    }
                    .overlay {
                        if viewStore.viewState.deleteAccountButtonVisible {
                            HStack {
                                Spacer()
                                Image(systemName: "person.slash")
                                    .foregroundColor(.black.opacity(0.5))
                                    .padding(.trailing, 10)
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                viewStore.toastState.removeAccountCheck = true
                            }
                            .alert("계정 삭제", isPresented: $viewStore.toastState.removeAccountCheck) {
                                Button("삭제", role: .destructive) {
                                    viewStore.dispatch(.removeAccount)
                                    viewStore.toastState.removeAccountSuccess = true
                                }
                                Button("취소", role: .cancel) {}
                            } message: {
                                Text("정말로 계정을 삭제하시겠습니까?\n계정을 삭제해도 사용 횟수는 초기화되지 않습니다.")
                            }
                        }
                    }
                    .padding(.bottom)
                }
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(maxHeight: viewStore.viewState.isTranslating ? .infinity : geo.size.height / 4)
                    .overlay {
                        VStack(spacing: 0) {
                            Spacer()
                            if viewStore.viewState.isTranslating {
                                ScrollView {
                                    VStack {
                                        Text(viewStore.viewState.responseText)
                                            .foregroundColor(.white)
                                            .nanumsquareneo(weight: .bold, size: 26)
                                            .lineSpacing(5)
                                            .padding(.horizontal, 50)
                                        if !viewStore.viewState.isGenerating {
                                            HStack(spacing: 15) {
                                                Spacer()
                                                Image(systemName: "clipboard")
                                                    .foregroundColor(.white)
                                                    .onTapGesture {
                                                        UIPasteboard.general.string = viewStore.viewState.responseText
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        viewStore.toastState.textCopied = true
                                                    }
                                                ShareLink(item: viewStore.viewState.responseText) {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .foregroundColor(.white)
                                                }
                                                .simultaneousGesture(TapGesture().onEnded {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    viewStore.toastState.textShared = true
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
                                    .rotationEffect(.degrees(viewStore.viewState.buttonRotation))
                                
                                Text(viewStore.viewState.isTranslating ? "돌아가기" : "원영적 사고로 변환하기")
                                    .foregroundColor(.white)
                                    .nanumsquareneo(weight: .bold, size: 16)
                            }
                            // MARK: - 원영적 사고로 변환하기 버튼 로직
                            .onTapGesture {
                                viewStore.translate()
                            }
                            .disabled(viewStore.viewState.isGenerating)
                            Spacer()
                        }
                    }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Color.background)
            .onTapGesture {
                isFocused = false
            }
            .onAppear {
                viewStore.fetchAppInfo()
                viewStore.fetchUserInfo()
            }
            // MARK: - 토스트
            .toast(isPresenting: $viewStore.toastState.textLengthExceeded, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.circle.fill", Color.red),
                    title: "글자 수 제한을 초과했습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.textEmpty, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.triangle.fill", Color.yellow),
                    title: "텍스트를 입력해주세요."
                )
            }
            .toast(isPresenting: $viewStore.toastState.textCopied, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "클립보드에 복사했습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.textShared, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "공유에 성공했습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.userInfoFetchSuccessed, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "로그인에 성공했습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.usageExceeded, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.circle.fill", Color.red),
                    title: "하루 사용 횟수가 초과되었습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.usageAdded, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("arrow.counterclockwise.circle.fill", .accentColor),
                    title: "오늘 남은 사용 횟수는 \(viewStore.viewState.totalUsageCounts - viewStore.viewState.usedUsageCounts)번입니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.usageReseted, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("plus.circle.fill", .blue),
                    title: "사용 횟수가 초기화되었습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.removeAccountSuccess, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", .green),
                    title: "계정이 성공적으로 삭제되었습니다."
                )
            }
            .toast(isPresenting: $viewStore.toastState.isLoading) {
                AlertToast(type: .loading)
            }
        }
    }
}

#Preview {
    ContentView(isLoggedIn: .constant(true))
}
