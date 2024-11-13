//
//  FirebaseAuthService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Firebase Authentication을 사용한 실제 구현체입니다. (Firestore에 강하게 결합)
final class FirebaseAuthService: AuthService {
  private let auth = Auth.auth()
  private let db = Firestore.firestore()
  private var currentNonce: String?
  
  var currentUser: User? {
    guard let firebaseUser = auth.currentUser else { return nil }
    return User(from: firebaseUser)
  }
  
  func signIn(with credential: ASAuthorizationAppleIDCredential) async throws -> User {
    guard let nonce = currentNonce else {
      throw AuthError.invalidNonce
    }
    
    guard let token = credential.identityToken,
          let tokenString = String(data: token, encoding: .utf8) else {
      throw AuthError.invalidToken
    }
    
    // Handle Refresh Token
    if let authorizationCode = credential.authorizationCode {
      try await storeRefreshToken(String(data: authorizationCode, encoding: .utf8) ?? "")
    }
    
    let firebaseCredential = OAuthProvider.credential(
      providerID: AuthProviderID.apple,
      idToken: tokenString,
      rawNonce: nonce,
      accessToken: nil
    )
    
    do {
      let result = try await Auth.auth().signIn(with: firebaseCredential)
      return User(from: result.user)
    } catch {
      throw AuthError.signInFailed(error.localizedDescription)
    }
  }
  
  func signOut() throws {
    do {
      try auth.signOut()
    } catch {
      throw AuthError.signOutFailed(error.localizedDescription)
    }
  }
  
  func deleteAccount() async throws {
    do {
      // Revoke Refresh Token
      if let token = UserDefaults.standard.string(forKey: "refreshToken") {
        try await revokeRefreshToken(token)
        UserDefaults.standard.removeObject(forKey: "refreshToken")
      }
      
      try await auth.currentUser?.delete()
    } catch {
      throw AuthError.deleteAccountFailed(error.localizedDescription)
    }
  }
  
  func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
    let nonce = randomNonceString()
    currentNonce = nonce
    return sha256(nonce)
  }
  
  func checkAndRestoreUserData(email: String, newUid: String) async throws -> Bool {
    do {
      let querySnapshot = try await db.collection("users")
        .whereField("email", isEqualTo: email)
        .getDocuments()
      
      if let document = querySnapshot.documents.first,
         let isDeleted = document.data()["isDeleted"] as? Bool,
         isDeleted {
        let userId = document.documentID
        try await restoreUserData(userID: userId, newUid: newUid)
        return true
      }
      return false
    } catch {
      throw AuthError.unknown(error)
    }
  }
  
  // MARK: - Private Methods
  private func storeRefreshToken(_ codeString: String) async throws {
    let urlString = "https://us-central1-luckyvicky-ios.cloudfunctions.net/getRefreshToken?code=\(codeString)"
      .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    guard let url = URL(string: urlString) else {
      throw AuthError.refreshTokenError("Invalid URL")
    }
    
    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {
        throw AuthError.refreshTokenError("Invalid response")
      }
      
      if let refreshToken = String(data: data, encoding: .utf8) {
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
      } else {
        throw AuthError.refreshTokenError("Invalid token data")
      }
    } catch {
      throw AuthError.refreshTokenError(error.localizedDescription)
    }
  }
  
  private func revokeRefreshToken(_ token: String) async throws {
    let urlString = "https://us-central1-luckyvicky-ios.cloudfunctions.net/revokeToken?refresh_token=\(token)"
      .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    guard let url = URL(string: urlString) else {
      throw AuthError.refreshTokenError("Invalid URL")
    }
    
    let (_, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw AuthError.refreshTokenError("Failed to revoke token")
    }
  }
  
  private func restoreUserData(userID: String, newUid: String) async throws {
    let oldUserRef = db.collection("users").document(userID)
    let newUserRef = db.collection("users").document(newUid)
    
    do {
      let document = try await oldUserRef.getDocument()
      guard var data = document.data() else {
        throw AuthError.userNotFound
      }
      
      data.removeValue(forKey: "isDeleted")
      data.removeValue(forKey: "deleteRequestTime")
      
      try await newUserRef.setData(data, merge: true)
      try await oldUserRef.delete()
    } catch {
      throw AuthError.unknown(error)
    }
  }
}
