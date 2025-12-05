//
//  AuthError.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

enum AuthError: LocalizedError {
  case invalidCredential
  case invalidToken
  case invalidNonce
  case signInFailed(String)
  case signOutFailed(String)
  case deleteAccountFailed(String)
  case requiresRecentLogin
  case userNotFound
  case networkError
  case refreshTokenError(String)
  case unknown(Error)

  var errorDescription: String? {
    switch self {
    case .invalidCredential:
      return "유효하지 않은 인증 정보입니다"
    case .invalidToken:
      return "유효하지 않은 토큰입니다"
    case .invalidNonce:
      return "유효하지 않은 Nonce입니다"
    case .signInFailed(let message):
      return "로그인 실패: \(message)"
    case .signOutFailed(let message):
      return "로그아웃 실패: \(message)"
    case .deleteAccountFailed(let message):
      return "계정 삭제 실패: \(message)"
    case .requiresRecentLogin:
      return "계정 삭제를 위해 다시 로그인해 주세요"
    case .userNotFound:
      return "사용자를 찾을 수 없습니다"
    case .networkError:
      return "네트워크 오류가 발생했습니다"
    case .refreshTokenError(let message):
      return "토큰 갱신 실패: \(message)"
    case .unknown(let error):
      return "알 수 없는 오류: \(error.localizedDescription)"
    }
  }
}
