//
//  MockAuthService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import AuthenticationServices

// MARK: - Mock Services for Testing
#if DEBUG
final class MockAuthService: AuthService {
  var currentUser: User?
  var error: Error?
  
  func signIn(with credential: ASAuthorizationAppleIDCredential) async throws -> User {
    if let error = error { throw error }
    let user = User(id: "test_id", email: "test@email.com", name: "Test User")
    currentUser = user
    return user
  }
  
  func signOut() throws {
    if let error = error { throw error }
    currentUser = nil
  }
  
  func deleteAccount() async throws {
    if let error = error { throw error }
    currentUser = nil
  }
  
  func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
    "test_nonce"
  }
  
  func checkAndRestoreUserData(email: String, newUid: String) async throws -> Bool {
    if let error = error { throw error }
    return true
  }
}
#endif
