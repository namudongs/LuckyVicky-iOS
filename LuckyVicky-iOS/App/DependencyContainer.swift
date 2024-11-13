//
//  DependencyContainer.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// 앱의 의존성을 관리하는 컨테이너입니다.
final class DependencyContainer {
  static let shared = DependencyContainer()
  
  private init() {}
  
  // MARK: - Services
  private(set) lazy var authService: AuthService = {
    FirebaseAuthService()
  }()
  
  private(set) lazy var storageService: StorageService = {
    FirestoreService()
  }()
  
  private(set) lazy var aiService: AIServiceProtocol = {
    ChatGPTService.createDefault()
  }()
  
  // MARK: - ViewModels
  @MainActor
  func makeContentViewModel() -> ContentViewModel {
    ContentViewModel(
      aiService: aiService,
      authService: authService,
      storageService: storageService
    )
  }
  
  @MainActor
  func makeAuthViewModel() -> AuthViewModel {
    AuthViewModel(
      authService: authService,
      storageService: storageService
    )
  }
  
  // MARK: - Testing Support
#if DEBUG
  func overrideServices(
    authService: AuthService? = nil,
    storageService: StorageService? = nil,
    aiService: AIServiceProtocol? = nil
  ) {
    if let authService = authService {
      self.authService = authService
    }
    if let storageService = storageService {
      self.storageService = storageService
    }
    if let aiService = aiService {
      self.aiService = aiService
    }
  }
  
  func makeMockContainer() -> DependencyContainer {
    let container = DependencyContainer()
    container.overrideServices(
      authService: MockAuthService(),
      storageService: MockStorageService(),
      aiService: MockAIService(configuration: .init(
        apiKey: "test_key",
        model: "test_model",
        systemPrompt: "test_prompt"
      ))
    )
    return container
  }
#endif
}
