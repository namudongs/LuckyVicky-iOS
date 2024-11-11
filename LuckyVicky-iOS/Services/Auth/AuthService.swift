//
//  AuthService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import AuthenticationServices
import FirebaseAuth

protocol AuthService {
  /// 현재 로그인된 사용자를 반환합니다.
  var currentUser: User? { get }
  
  /// Apple ID로 로그인합니다.
  /// - Parameter credential: ASAuthorizationAppleIDCredential
  /// - Returns: 로그인된 User
  /// - Throws: AuthError
  func signIn(with credential: ASAuthorizationAppleIDCredential) async throws -> User
  
  /// 로그아웃합니다.
  /// - Throws: AuthError
  func signOut() throws
  
  /// 계정을 삭제합니다.
  /// - Throws: AuthError
  func deleteAccount() async throws
  
  /// Apple Sign In 요청을 준비합니다.
  /// - Parameter request: ASAuthorizationAppleIDRequest
  /// - Returns: 생성된 nonce
  func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String
  
  /// 저장된 사용자 정보를 확인하고 복구합니다.
  /// - Parameters:
  ///   - email: 사용자 이메일
  ///   - newUid: 새로운 UID
  /// - Returns: 기존 데이터 존재 여부
  func checkAndRestoreUserData(email: String, newUid: String) async throws -> Bool
}
