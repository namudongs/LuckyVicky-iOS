//
//  AuthService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import AuthenticationServices

/// Auth Service를 위한 프로토콜입니다.
protocol AuthService {
  /// 현재 로그인된 사용자를 반환합니다.
  var currentUser: User? { get }
  
  /// Apple ID로 로그인합니다.
  func signIn(with credential: ASAuthorizationAppleIDCredential) async throws -> User
  
  /// 로그아웃합니다.
  func signOut() throws
  
  /// 계정을 삭제합니다.
  func deleteAccount() async throws
  
  /// Apple Sign In 요청을 준비하며 Nonce, SHA256 등 암호화를 실행합니다.
  func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String
  
  /// 저장된 사용자 정보를 확인하고 복구합니다.
  func checkAndRestoreUserData(email: String, newUid: String) async throws -> Bool
}
