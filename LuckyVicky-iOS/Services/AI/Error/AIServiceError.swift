//
//  AIServiceError.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/13/24.
//

import Foundation

/// AI Service의 Error를 정의하는 열거형입니다.
enum AIServiceError: LocalizedError {
  case invalidAPIKey
  case invalidResponse
  case streamingFailed(String)
  case connectionFailed(String)
  case rateLimitExceeded
  case unknown(Error)
  
  var errorDescription: String? {
    switch self {
    case .invalidAPIKey:
      return "유효하지 않은 API 키입니다"
    case .invalidResponse:
      return "유효하지 않은 응답입니다"
    case .streamingFailed(let message):
      return "스트리밍 실패: \(message)"
    case .connectionFailed(let message):
      return "연결 실패: \(message)"
    case .rateLimitExceeded:
      return "API 사용량이 초과되었습니다"
    case .unknown(let error):
      return "알 수 없는 오류: \(error.localizedDescription)"
    }
  }
}
