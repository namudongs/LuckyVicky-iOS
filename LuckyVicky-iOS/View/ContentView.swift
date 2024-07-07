//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import AlertToast
import FirebaseAuth

// TODO: - FirebaseAuth 연결하고 로그인 기능 구현하기 - 완료
// TODO: - User가 API 호출한 횟수 저장하고 10번 제한 걸기 - 완료
// TODO: - User Data 하루 뒤에 삭제해서 재가입시에 사용횟수 초기화되지 않게 하기 - 완료
// TODO: - 나의 이메일 가리기 옵션 선택 시 필수적으로 이메일 수집할 수 있도록 하기
// TODO: - Gemini API 연결하기
// TODO: - User가 10번 제한에 걸리면 광고 보고 해제할 수 있게 하기
// TODO: - 원영적 사고 설명 및 개발자 소개, 사용한 API 등의 저작권 표기 뷰 만들기
// TODO: - 후원 기능 구현하기

struct ContentView: View {
    // MARK: - 프로퍼티
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject var fsManager: FirestoreManager
    @StateObject var gptManager = GPTManager()
    @FocusState private var isFocused: Bool
    @State private var isGenerating: Bool = false
    @State private var isTranslate: Bool = false
    @State private var originalText: String = ""
    @State private var rotation: Double = 0.0
    @State private var nowTextLength: Int = 0
    
    @State private var showRemoveAccountSuccessAlert: Bool = false
    @State private var showRemoveAccountCheckAlert: Bool = false
    @State private var showUpdateUsage: Bool = false
    @State private var showSuccessFetchUserInfo: Bool = false
    @State private var showAddUsageAlert: Bool = false
    @State private var showUsageExceededAlert: Bool = false
    @State private var showAlert: Bool = false
    @State private var showEmptyAlert: Bool = false
    @State private var showCopiedAlert: Bool = false
    @State private var showSharedAlert: Bool = false
    
    @State private var usedCounts: Int = 10
    @State private var lastUsedTime: String = Date().toString()
    
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
                if !isTranslate {
                    HStack {
                        Spacer()
                        Text("\(usedCounts)/10")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black.opacity(0.3))
                        Spacer()
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Image(systemName: "person.slash")
                                .foregroundColor(.black.opacity(0.5))
                                .padding(.trailing, 10)
                        }
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            showRemoveAccountCheckAlert = true
                        }
                        .alert("계정 삭제", isPresented: $showRemoveAccountCheckAlert) {
                            Button("삭제", role: .destructive) {
                                removeAccount()
                                showRemoveAccountSuccessAlert = true
                            }
                            Button("취소", role: .cancel) {}
                        } message: {
                            Text("정말로 계정을 삭제하시겠습니까?\n계정을 삭제해도 사용 횟수는 초기화되지 않습니다.")
                        }
                    }
                    .padding(.bottom)
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
                                        Text(gptManager.response)
                                            .foregroundColor(.white)
                                            .font(.system(size: 24, weight: .bold))
                                            .padding(.horizontal, 50)
                                        if !isGenerating {
                                            HStack(spacing: 15) {
                                                Spacer()
                                                Image(systemName: "clipboard")
                                                    .foregroundColor(.white)
                                                    .onTapGesture {
                                                        UIPasteboard.general.string = gptManager.response
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        showCopiedAlert = true
                                                    }
                                                ShareLink(item: gptManager.response) {
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
                            // MARK: - 원영적 사고로 변환하기 버튼 로직
                            .onTapGesture {
                                if isTranslate {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    withAnimation {
                                        originalText = ""
                                        gptManager.response = ""
                                        isGenerating = false
                                        isTranslate = false
                                        rotation = 0
                                    }
                                } else {
                                    if self.lastUsedTime == Date().toString() && self.usedCounts >= 10 {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        showUsageExceededAlert = true
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
                                            gptManager.sendMessage(from: originalText) { result in
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
            .onAppear {
                fetchUserUsageInfo()
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
            .toast(isPresenting: $showSuccessFetchUserInfo, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", Color.green),
                    title: "로그인에 성공했습니다."
                )
            }
            .toast(isPresenting: $showUsageExceededAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.circle.fill", Color.red),
                    title: "하루 사용 횟수가 초과되었습니다."
                )
            }
            .toast(isPresenting: $showAddUsageAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("arrow.counterclockwise.circle.fill", .accentColor),
                    title: "오늘 남은 사용 횟수는 \(10 - self.usedCounts)번입니다."
                )
            }
            .toast(isPresenting: $showUpdateUsage, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("plus.circle.fill", .blue),
                    title: "사용 횟수가 초기화되었습니다."
                )
            }
            .toast(isPresenting: $showRemoveAccountSuccessAlert, offsetY: 10) {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("checkmark.circle.fill", .green),
                    title: "계정이 성공적으로 삭제되었습니다."
                )
            }
        }
    }
}

// MARK: - 변환
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
        updateUserUsageInfo()
        withAnimation {
            rotation = 45
        }
    }
}

// MARK: - 유저 정보
extension ContentView {
    func fetchUserUsageInfo() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        fsManager.fetchUserUsage(userID: userID) { result in
            switch result {
            case .success(let data):
                usedCounts = data["usedCounts"] as? Int ?? 10
                lastUsedTime = data["lastUsedTime"] as? String ?? Date().toString()
                if lastUsedTime != Date().toString() {
                    resetUserUsage()
                } else {
                    showSuccessFetchUserInfo = true
                }
            case .failure(let error):
                print("Error fetching user info: \(error.localizedDescription)")
                isLoggedIn = false
            }
        }
    }
    
    func updateUserUsageInfo() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let updatedCounts = usedCounts + 1
        let updatedTime = Date().toString()
        fsManager.updateUserUsage(userID: userID,
                                      usedCounts: updatedCounts, lastUsedTime: updatedTime) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
                isLoggedIn = false
            } else {
                usedCounts = updatedCounts
                lastUsedTime = updatedTime
            }
        }
    }
    
    func resetUserUsage() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        fsManager.resetUserUsage(userID: userID) { error in
            if let error = error {
                print("Error resetting user info: \(error.localizedDescription)")
                isLoggedIn = false
            } else {
                showUpdateUsage = true
                usedCounts = 0
                lastUsedTime = Date().toString()
            }
        }
    }
}

// MARK: - 회원 탈퇴
extension ContentView {
    func removeAccount() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in")
            isLoggedIn = false
            return
        }
        
        let userID = user.uid
        fsManager.requestAccountDeletion(userID: userID) { error in
            if let error = error {
                print("Error request deleting Firestore user data: \(error.localizedDescription)")
                return
            }
            
            user.delete { error in
                if let error = error {
                    print("Error deleting user account: \(error.localizedDescription)")
                    return
                }
                isLoggedIn = false
                do {
                    try Auth.auth().signOut()
                    print("User signed out and account deleted successfully")
                    
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }
        }
        
        // Refresh Token 삭제
        if let token = UserDefaults.standard.string(forKey: "refreshToken") {
            let url = URL(string: "https://us-central1-luckyvicky-ios.cloudfunctions.net/revokeToken?refresh_token=\(token)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard data != nil else { return }
            }
            task.resume()
        }
    }
}

#Preview {
    ContentView(fsManager: FirestoreManager())
}
