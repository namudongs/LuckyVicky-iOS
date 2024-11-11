//
//  AuthView.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import AlertToast
import AuthenticationServices
import SwiftUI

struct AuthView: View {
  // MARK: - Properties
  private let container: DependencyContainer
  @StateObject private var viewModel: AuthViewModel
  
  init(container: DependencyContainer) {
    self.container = container
    // StateObject를 위한 임시 초기화
    self._viewModel = StateObject(
      wrappedValue: AuthViewModel(
        authService: container.authService,
        storageService: container.storageService
      )
    )
  }
  
  // MARK: - Body
  var body: some View {
    ZStack {
      Color.accentColor
        .ignoresSafeArea()
      
      VStack {
        Spacer()
        
        logo
        
        animatedText
        
        Spacer()
        
        signInButton
      }
      .padding()
    }
    .toast(isPresenting: .constant(viewModel.state.isLoading)) {
      AlertToast(type: .loading)
    }
    .onAppear {
      viewModel.startTextAnimation()
    }
  }
  
  // MARK: - Subviews
  private var logo: some View {
    Image(.luckyvicky)
      .resizable()
      .scaledToFit()
      .blendMode(.screen)
      .frame(width: 100)
      .rotationEffect(.degrees(viewModel.state.rotation))
  }
  
  private var animatedText: some View {
    Text(viewModel.state.currentText)
      .foregroundColor(.white)
      .frame(width: 300, height: 300, alignment: .top)
      .nanumsquareneo(weight: .bold, size: 26)
      .multilineTextAlignment(.center)
      .padding(.top, 5)
  }
  
  private var signInButton: some View {
    SignInWithAppleButton(
      .signIn,
      onRequest: { request in
        request.requestedScopes = [.fullName, .email]
        request.nonce = viewModel.prepareAppleSignInRequest(request)
      },
      onCompletion: { result in
        viewModel.send(.startSignIn)
        switch result {
        case .success(let authResults):
          guard let credential = authResults.credential as? ASAuthorizationAppleIDCredential
          else { return }
          viewModel.handleAppleSignIn(credential: credential)
        case .failure(let error):
          viewModel.send(.completeSignIn(.failure(error)))
        }
      }
    )
    .signInWithAppleButtonStyle(.black)
    .frame(width: 280, height: 45)
  }
}

// MARK: - Previews
struct AuthView_Previews: PreviewProvider {
  static var previews: some View {
    AuthView(container: DependencyContainer.shared.makeMockContainer())
  }
}
