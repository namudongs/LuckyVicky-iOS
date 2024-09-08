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
}

struct ContentViewReducer {
    static func reduce(state: ViewState, action: ViewAction) -> ViewState {
        var newState = state
        switch action {
        case .startTranslate:
            print("start Translate")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            newState.isTranslating = true
            newState.isGenerating = true
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                newState.buttonRotation = 360
            }
            // 이후에 GPTManager에 요청 보내는 사이드 이펙트
        case .completeTranslate:
            print("complete Translate")
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            newState.isGenerating = false
            withAnimation {
                newState.buttonRotation = 45
            }
            // 이후에 updateUserUsage 호출하는 사이드 이펙트
        case .fetchAppInfo:
            // 앱 정보를 가져오는 로직
            FirestoreManager.shared.fetchAppSettings { result in
                switch result {
                case .success(let data):
                    newState.deleteAccountButtonVisible = data["deleteable"] as? Bool ?? false
                    newState.totalUsageCounts = data["usage"] as? Int ?? 20
                    print("Success fetching app info")
                case .failure(let error):
                    print("Error fetching app info: \(error.localizedDescription)")
                }
            }
        case .fetchUserInfo:
            // 유저 정보를 가져오는 처리 로직
            guard let userID = Auth.auth().currentUser?.uid else { return newState }
            FirestoreManager.shared.fetchUserUsage(userID: userID) { result in
                switch result {
                case .success(let data):
                    print("Success fetching user info")
                    newState.usedUsageCounts = data["usedCounts"] as? Int ?? 20
                    newState.lastUsedTime = data["lastUsedTime"] as? String ?? Date().toString()
                case .failure(let error):
                    print("Error fetching user info: \(error.localizedDescription)")
                    // isLoggedIn = false
                }
            }
        case .updateUserUsage:
            // 사용량을 업데이트하는 처리 로직
            guard let userID = Auth.auth().currentUser?.uid else { return newState }
            FirestoreManager.shared.updateUserUsage(userID: userID, 
                                                    usedCounts: state.usedUsageCounts + 1,
                                                    lastUsedTime: Date().toString()) { error in
                if let error = error {
                    print("Error updating user info: \(error.localizedDescription)")
                    // isLoggedIn = false
                } else {
                    print("Success updating user info")
                    newState.usedUsageCounts = state.usedUsageCounts + 1
                    newState.lastUsedTime = Date().toString()
                }
            }
        case .resetUserUsage:
            guard let userID = Auth.auth().currentUser?.uid else { return newState }
            FirestoreManager.shared.resetUserUsage(userID: userID) { error in
                if let error = error {
                    print("Error resetting user info: \(error.localizedDescription)")
                    // isLoggedIn = false
                } else {
                    // showUpdateUsage = true
                    newState.usedUsageCounts = 0
                    newState.lastUsedTime = Date().toString()
                }
            }
            newState.usedUsageCounts = 0
            newState.lastUsedTime = Date().toString()
        case .removeAccount: break
            // 계정을 삭제하는 처리 로직
        }
        return newState
    }
}

// 토스트 상태 구조체
struct ToastState {
    var removeAccountSuccess = false
    var removeAccountCheck = false
    var usageUpdated = false
    var usageExceeded = false
    var usageAdded = false
    var textEmpty = false
    var textLengthExceeded = false
    var textCopied = false
    var textShared = false
    var userInfoFetchSuccessed = false
    var isLoading = false
}

// 뷰 상태 구조체
struct ViewState {
    var isTranslating: Bool = false
    var isGenerating: Bool = false
    var isFocused: Bool = false
    var beforeText: String = ""
    var buttonRotation: Double = 0.0
    var usedUsageCounts: Int = 20
    var totalUsageCounts: Int = 20
    var lastUsedTime: String = Date().toString()
    var deleteAccountButtonVisible: Bool = false
}

// 뷰 액션 정의
enum ViewAction {
    case fetchAppInfo
    case startTranslate
    case completeTranslate
    case fetchUserInfo
    case updateUserUsage
    case resetUserUsage
    case removeAccount
}
