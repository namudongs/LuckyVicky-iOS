//
//  AuthViewModel.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
  // MARK: - Types
  struct State {
    var isLoading = false
    var currentText = "\n"
    var textIndex = 0
    var wordIndex = 0
    var rotation = 0.0
    var error: Error?
    
    static let initial = State()
  }
  
  enum Action {
    case startSignIn
    case completeSignIn(Result<User, Error>)
  }
  
  // MARK: - Properties
  private let authService: AuthService
  private let storageService: StorageService
  @Published private(set) var state: State
  @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
  
  let texts = [
    "버스를 놓쳐버렸다고? 우왕! 그럼 걸어 다니면 운동도 되고 기분도 좋아져! 🚶‍♀️ 다음 차를 기다리면서 음악 듣거나 책 읽는 건 어때? 시간이 금방 가잖아! 이거 완전 럭키비키잔앙🍀",
    "숙취가 심하다니 우왕! 파티를 너무 즐겼넹! 🥳 오늘은 몸과 마음 푹 쉬면 됑! 쉬면 다 나아질 거얌. 이거 완전 럭키비키잔앙🍀",
    "우와앙! 택시를 놓쳤다니 우연히 도보로 즐거운 산책을 할 수 있었넹! 🚶‍♂️ 아무래도 기분 전환도 되었겠징? 그리고 다음에 더 좋은 놀이가 기다리고 있옹. 이거 완전 럭키비키잔앙🍀",
    "우왕! 영화 티켓 매진이라니! 그럼 이번 주말을 더 특별하게 보낼 수 있겠징! 🎥 다른 좋은 영화를 보거나, 즐거운 액티비티를 즐길 수도 있엉! 이거 완전 럭키비키잔앙🍀",
    "빨래를 했는데 비가 와서 다 젖었다니 우왕! 빨래가 자연 린스 효과 받았넹! 🌧️ 이렇게 세탁해주는 하늘의 선물이얌! 다 빨리 마르겠지? 이거 완전 럭키비키잔앙🍀",
    "중요한 일을 해야하는데 인터넷이 끊겼다니 우와앙! 인터넷 쉬는 시간이얌! 😌 이제는 조금 쉬면서 더 잘 할 수 있엉! ✨ 중요한 일이라 더 잘 해결할 시간을 얻은 거같지 않앙? 대단행! 이거 완전 럭키비키잔앙🍀"
  ]
  
  // MARK: - Initialization
  init(
    authService: AuthService,
    storageService: StorageService,
    initialState: State = .initial
  ) {
    self.authService = authService
    self.storageService = storageService
    self.state = initialState
  }
  
  // MARK: - Methods
  func send(_ action: Action) {
    switch action {
    case .startSignIn:
      state.isLoading = true
    case .completeSignIn(let result):
      state.isLoading = false
      switch result {
      case .success:
        isLoggedIn = true
      case .failure(let error):
        state.error = error
      }
    }
  }
  
  func handleAppleSignIn(
    credential: ASAuthorizationAppleIDCredential
  ) {
    Task {
      do {
        let user = try await authService.signIn(with: credential)
        let exists = try await authService.checkAndRestoreUserData(
          email: user.email,
          newUid: user.id
        )
        
        if exists {
          print("기존 사용자 데이터 복구 완료")
        } else {
          try await storageService.saveUserInfo(
            userID: user.id,
            name: user.name,
            email: user.email
          )
        }
        
        send(.completeSignIn(.success(user)))
      } catch {
        send(.completeSignIn(.failure(error)))
      }
    }
  }
  
  func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
    authService.prepareAppleSignInRequest(request)
  }
  
  func startTextAnimation() {
    animateText()
    startRotation()
  }
  
  private func animateText() {
    let words = texts[state.textIndex].split(separator: " ").map(String.init)
    state.currentText = ""
    state.wordIndex = 0
    
    func displayNextWord() {
      guard state.wordIndex < words.count else {
        let nextIndex = (state.textIndex + 1) % texts.count
        state.textIndex = nextIndex
        Task {
          try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
          await MainActor.run { animateText() }
        }
        return
      }
      
      withAnimation(.easeInOut(duration: 0.2)) {
        state.currentText
        += (state.currentText.isEmpty ? "" : " ") + words[state.wordIndex]
        
        state.wordIndex += 1
      }
      
      Task {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2초 대기
        await MainActor.run { displayNextWord() }
      }
    }
    
    displayNextWord()
  }
  
  private func startRotation() {
    withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
      state.rotation = 360
    }
  }
}
