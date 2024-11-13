//
//  ContentViewModel.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
  // MARK: - Types
  struct State {
    var isTranslating = false
    var isGenerating = false
    var beforeText = ""
    var responseText = ""
    var buttonRotation = 0.0
    var usedUsageCounts = 0
    var totalUsageCounts = 20
    var lastUsedTime = Date().toString()
    var deleteAccountButtonVisible = false
    var toast = Toast()
    var error: Error?
    
    static let initial = State()
  }
  
  struct Toast: Equatable {
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
  
  enum Action {
    case fetchAppInfo
    case translate
    case startTranslate
    case completeTranslate(Result<Void, Error>)
    case fetchUserInfo
    case updateUserUsage
    case resetUserUsage
    case removeAccount
  }
  
  // MARK: - Properties
  private var aiService: AIServiceProtocol
  private let authService: AuthService
  private let storageService: StorageService
  @Published private(set) var state: State
  @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
  
  // MARK: - Initialization
  init(
    aiService: AIServiceProtocol,
    authService: AuthService,
    storageService: StorageService,
    initialState: State = .initial
  ) {
    self.aiService = aiService
    self.authService = authService
    self.storageService = storageService
    self.state = initialState
    self.aiService.delegate = self
  }
  
  // MARK: - Methods
  func send(_ action: Action) {
    switch action {
    case .fetchAppInfo:
      Task { await handleFetchAppInfo() }
      
    case .translate:
      handleTranslate()
      
    case .startTranslate:
      handleStartTranslate()
      
    case .completeTranslate(let result):
      handleCompleteTranslate(result)
      
    case .fetchUserInfo:
      Task { await handleFetchUserInfo() }
      
    case .updateUserUsage:
      Task { await handleUpdateUserUsage() }
      
    case .resetUserUsage:
      Task { await handleResetUserUsage() }
      
    case .removeAccount:
      Task { await handleRemoveAccount() }
    }
  }
  
  func updateBeforeText(_ newText: String) {
    state.beforeText = newText
  }
  
  func updateToast<T>(_ keyPath: WritableKeyPath<Toast, T>, value: T) {
    state.toast[keyPath: keyPath] = value
  }
  
  // MARK: - Private Methods
  private func handleFetchAppInfo() async {
    do {
      let settings = try await storageService.fetchAppSettings()
      state.deleteAccountButtonVisible = settings.canDeleteAccount
      state.totalUsageCounts = settings.maxUsageCount
      state.toast.isLoading = false
    } catch {
      state.error = error
    }
  }
  
  private func handleStartTranslate() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    state.isTranslating = true
    state.isGenerating = true
    
    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
      state.buttonRotation = 360
    }
  }
  
  private func handleCompleteTranslate(_ result: Result<Void, Error>) {
    switch result {
    case .success:
      withAnimation {
        state.buttonRotation = 45
        state.isGenerating = false
      }
      send(.updateUserUsage)
      
    case .failure(let error):
      state.error = error
    }
  }
  
  private func handleFetchUserInfo() async {
    guard let user = authService.currentUser else {
      isLoggedIn = false
      return
    }
    
    do {
      let usage = try await storageService.fetchUserUsage(userID: user.id)
      state.usedUsageCounts = usage.usedCount
      state.lastUsedTime = usage.lastUsedTime
      state.toast.isLoading = false
      state.toast.userInfoFetchSuccessed = true
    } catch {
      state.error = error
    }
  }
  
  private func handleUpdateUserUsage() async {
    guard let user = authService.currentUser else {
      isLoggedIn = false
      return
    }
    
    do {
      let newUsedCount = state.usedUsageCounts + 1
      try await storageService.updateUserUsage(
        userID: user.id,
        usedCount: newUsedCount
      )
      state.usedUsageCounts = newUsedCount
      state.lastUsedTime = Date().toString()
      state.toast.usageAdded = true
    } catch {
      state.error = error
    }
  }
  
  private func handleResetUserUsage() async {
    guard let user = authService.currentUser else {
      isLoggedIn = false
      return
    }
    
    do {
      try await storageService.resetUserUsage(userID: user.id)
      state.usedUsageCounts = 0
      state.lastUsedTime = Date().toString()
      state.toast.usageReseted = true
    } catch {
      state.error = error
    }
  }
  
  private func handleRemoveAccount() async {
    guard let user = authService.currentUser else {
      isLoggedIn = false
      return
    }
    
    do {
      try await storageService.requestAccountDeletion(userID: user.id)
      try await authService.deleteAccount()
      try authService.signOut()
      
      state.toast.removeAccountSuccess = true
      isLoggedIn = false
      
    } catch {
      state.error = error
    }
  }
  
  private func handleTranslate() {
    if state.isTranslating {
      resetTranslationState()
    } else {
      startNewTranslation()
    }
  }
  
  private func resetTranslationState() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    
    withAnimation {
      state.beforeText = ""
      state.responseText = ""
      state.isGenerating = false
      state.isTranslating = false
      state.buttonRotation = 0
    }
  }
  
  private func startNewTranslation() {
    guard canStartNewTranslation() else { return }
    
    send(.startTranslate)
    
    Task {
      do {
        try await aiService.processText(state.beforeText)
      } catch {
        send(.completeTranslate(.failure(error)))
      }
    }
  }
  
  private func canStartNewTranslation() -> Bool {
    let isSameDay = Calendar.current.isDate(state.lastUsedTime.toDate() ?? Date(), inSameDayAs: Date())
    if isSameDay && state.usedUsageCounts >= state.totalUsageCounts {
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
      state.toast.usageExceeded = true
      return false
    }
    
    if state.beforeText.isEmpty {
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
      state.toast.textEmpty = true
      return false
    }
    
    return true
  }
}

// MARK: - AIServiceDelegate
extension ContentViewModel: @preconcurrency AIServiceDelegate {
  func aiService(_ service: AIServiceProtocol, didGenerateText text: String) {
    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    state.responseText += text
  }
  
  func aiService(_ service: AIServiceProtocol, didCompleteWithResult result: Result<Void, Error>) {
    send(.completeTranslate(result))
  }
}
