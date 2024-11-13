//
//  ContentViewModel.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Combine
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
    case binding
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
  private var cancellables = Set<AnyCancellable>()
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
  }
  
  // MARK: - Public Methods
  func send(_ action: Action) {
    switch action {
    case .binding: bindPublishers()
    case .fetchAppInfo: fetchAppInfo()
    case .translate: handleTranslate()
    case .startTranslate: handleStartTranslate()
    case .completeTranslate(let result): handleCompleteTranslate(result)
    case .fetchUserInfo: fetchUserInfo()
    case .updateUserUsage: updateUserUsage()
    case .resetUserUsage: resetUserUsage()
    case .removeAccount: removeAccount()
    }
  }
  
  func updateBeforeText(_ newText: String) {
    state.beforeText = newText
  }
  
  func updateToast<T>(_ keyPath: WritableKeyPath<Toast, T>, value: T) {
    state.toast[keyPath: keyPath] = value
  }
  
  // MARK: - Private Methods
  
  // API 및 데이터 관리 관련 메서드
  private func fetchAppInfo() {
    Task {
      do {
        let settings = try await storageService.fetchAppSettings()
        updateSettings(settings)
      } catch { handleError(error) }
    }
  }
  
  private func fetchUserInfo() {
    Task {
      guard let user = authService.currentUser else {
        isLoggedIn = false
        return
      }
      do {
        let usage = try await storageService.fetchUserUsage(userID: user.id)
        updateUserInfo(usage)
      } catch { handleError(error) }
    }
  }
  
  private func updateUserUsage() {
    Task {
      guard let user = authService.currentUser else {
        isLoggedIn = false
        return
      }
      do {
        let newUsedCount = state.usedUsageCounts + 1
        try await storageService.updateUserUsage(userID: user.id, usedCount: newUsedCount)
        state.usedUsageCounts = newUsedCount
        state.lastUsedTime = Date().toString()
        state.toast.usageAdded = true
      } catch { handleError(error) }
    }
  }
  
  private func resetUserUsage() {
    Task {
      guard let user = authService.currentUser else {
        isLoggedIn = false
        return
      }
      do {
        try await storageService.resetUserUsage(userID: user.id)
        state.usedUsageCounts = 0
        state.lastUsedTime = Date().toString()
        state.toast.usageReseted = true
      } catch { handleError(error) }
    }
  }
  
  private func removeAccount() {
    Task {
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
      } catch { handleError(error) }
    }
  }
  
  // UI 업데이트 관련 메서드
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
  
  private func textEditorValidation() -> Bool {
    if state.usedUsageCounts >= state.totalUsageCounts {
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
      updateToast(\.usageExceeded, value: true)
      return false
    } else if state.beforeText.isEmpty {
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
      updateToast(\.textEmpty, value: true)
      return false
    }
    
    return true
  }
  
  private func startNewTranslation() {
    guard textEditorValidation() else { return }
    
    send(.startTranslate)
    
    Task {
      do {
        try await aiService.processText(state.beforeText)
      } catch { send(.completeTranslate(.failure(error))) }
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
      withAnimation { state.buttonRotation = 45 }
      state.isGenerating = false
      send(.updateUserUsage)
    case .failure(let error): handleError(error)
    }
  }
  
  // 에러 및 설정 업데이트 관련 메서드
  private func handleError(_ error: Error) {
    state.error = error
  }
  
  private func updateSettings(_ settings: AppSettings) {
    state.deleteAccountButtonVisible = settings.canDeleteAccount
    state.totalUsageCounts = settings.maxUsageCount
    state.toast.isLoading = false
  }
  
  private func updateUserInfo(_ usage: UsageInfo) {
    state.usedUsageCounts = usage.usedCount
    state.lastUsedTime = usage.lastUsedTime
    state.toast.isLoading = false
    state.toast.userInfoFetchSuccessed = true
  }
  
  // Publisher 바인딩 메서드
  private func bindPublishers() {
    aiService.textPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        guard let self = self else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        self.state.responseText += text
      }
      .store(in: &cancellables)
    
    aiService.completionPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self = self else { return }
        self.handleCompleteTranslate(result)
      }
      .store(in: &cancellables)
  }
}
