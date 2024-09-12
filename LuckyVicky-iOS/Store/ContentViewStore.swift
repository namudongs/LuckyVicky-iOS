//
//  ContentViewStore.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 9/7/24.
//

import FirebaseAuth
import SwiftUI

final class ContentViewStore: ObservableObject {
    @Published var toastState = ToastState()  // 토스트 상태
    @Published var viewState = ViewState() // 뷰 상태
    
    func dispatch(_ action: ViewAction) {
        viewState = ContentViewReducer.reduce(state: viewState, action: action)
    }
    
    // translate button tapped
    func translate() {
        if viewState.isTranslating {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation {
                viewState.beforeText = ""
                viewState.responseText = ""
                viewState.isGenerating = false
                viewState.isTranslating = false
                viewState.buttonRotation = 0
            }
        } else {
            if viewState.lastUsedTime == Date().toString() && viewState.usedUsageCounts >= viewState.totalUsageCounts {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                toastState.usageExceeded = true
            } else {
                if viewState.beforeText.isEmpty {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    toastState.textEmpty = true
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation {
                        viewState.isTranslating = true
                    }
                    dispatch(.startTranslate)
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        viewState.buttonRotation = 360
                    }
                    GPTManager.shared.sendMessage(from: self.viewState.beforeText) { response in
                        self.viewState.responseText += response
                    } completion: { result in
                        switch result {
                        case .success:
                            withAnimation {
                                self.viewState.buttonRotation = 45
                            }
                            self.dispatch(.completeTranslate)
                            self.updateUserUsage()
                        case .failure(let error):
                            print("오류 발생: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // fetchUserInfo effect
    func fetchUserInfo() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        FirestoreManager.shared.fetchUserUsage(userID: userID) { result in
            switch result {
            case .success(let data):
                print("Success fetching user info")
                self.dispatch(.fetchUserInfo(data: data))
                self.toastState.isLoading = false
                self.toastState.userInfoFetchSuccessed = true
            case .failure(let error):
                print("Error fetching user info: \(error.localizedDescription)")
            }
        }
    }
    
    // fetchAppInfo effect
    func fetchAppInfo() {
        FirestoreManager.shared.fetchAppSettings { result in
            switch result {
            case .success(let data):
                print("Success fetching app info")
                self.dispatch(.fetchAppInfo(data: data))
                self.toastState.isLoading = false
            case .failure(let error):
                print("Error fetching app info: \(error.localizedDescription)")
            }
        }
    }
    
    // updateUserUsage effect
    func updateUserUsage() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        FirestoreManager.shared.updateUserUsage(userID: userID,
                                                usedCounts: viewState.usedUsageCounts + 1,
                                                lastUsedTime: Date().toString()) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
            } else {
                print("Success updating user info")
                self.dispatch(.updateUserUsage)
                self.toastState.usageAdded = true
            }
        }
    }
    
    // resetUserUsage effect
    func resetUserUsage() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        FirestoreManager.shared.resetUserUsage(userID: userID) { error in
            if let error = error {
                print("Error resetting user info: \(error.localizedDescription)")
            } else {
                print("Success resetting user info")
                self.dispatch(.resetUserUsage)
                self.toastState.usageReseted = true
            }
        }
    }
}

struct ContentViewReducer {
    static func reduce(state: ViewState, action: ViewAction) -> ViewState {
        var newState = state
        switch action {
        case .startTranslate:
            print("Start Translate")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            newState.isTranslating = true
            newState.isGenerating = true
        case .completeTranslate:
            print("Complete Translate")
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            newState.isGenerating = false
        case .fetchAppInfo(let data):
            newState.deleteAccountButtonVisible = data["deleteable"] as? Bool ?? false
            newState.totalUsageCounts = data["usage"] as? Int ?? 20
        case .fetchUserInfo(let data):
            newState.usedUsageCounts = data["usedCounts"] as? Int ?? 20
            newState.lastUsedTime = data["lastUsedTime"] as? String ?? Date().toString()
        case .updateUserUsage:
            newState.usedUsageCounts += 1
            newState.lastUsedTime = Date().toString()
        case .resetUserUsage:
            newState.usedUsageCounts = 0
            newState.lastUsedTime = Date().toString()
        case .removeAccount:
            // 계정을 삭제하는 처리 로직 추가
            break
        }
        return newState
    }
}

// 토스트 상태 구조체
struct ToastState {
    var removeAccountSuccess = false
    var removeAccountCheck = false
    var usageReseted = false
    var usageExceeded = false
    var usageAdded = false
    var textEmpty = false
    var textLengthExceeded = false
    var textCopied = false
    var textShared = false
    var userInfoFetchSuccessed = false
    var isLoading = true
}

// 뷰 상태 구조체
struct ViewState {
    var isTranslating: Bool = false
    var isGenerating: Bool = false
    var isFocused: Bool = false
    var beforeText: String = ""
    var responseText: String = ""
    var buttonRotation: Double = 0.0
    var usedUsageCounts: Int = 20
    var totalUsageCounts: Int = 20
    var lastUsedTime: String = Date().toString()
    var deleteAccountButtonVisible: Bool = false
}

// 뷰 액션 정의
enum ViewAction {
    case fetchAppInfo(data: [String: Any])
    case startTranslate
    case completeTranslate
    case fetchUserInfo(data: [String: Any])
    case updateUserUsage
    case resetUserUsage
    case removeAccount
}
