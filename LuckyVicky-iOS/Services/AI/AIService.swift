//
//  AIService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// AI 서비스의 응답을 처리하는 프로토콜
protocol AIServiceDelegate: AnyObject {
  /// 새로운 텍스트 청크가 생성될 때마다 호출
  func aiService(_ service: AIServiceProtocol, didGenerateText text: String)
  /// AI 응답 생성이 완료되었을 때 호출
  func aiService(_ service: AIServiceProtocol, didCompleteWithResult result: Result<Void, Error>)
}

/// AI 서비스 관련 에러
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

/// AI 서비스의 설정을 위한 구조체
struct AIServiceConfiguration {
  let apiKey: String
  let model: String
  let temperature: Double
  let maxTokens: Int
  let systemPrompt: String
  
  init(
    apiKey: String,
    model: String,
    temperature: Double = 1.0,
    maxTokens: Int = 550,
    systemPrompt: String
  ) {
    self.apiKey = apiKey
    self.model = model
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.systemPrompt = systemPrompt
  }
}

/// AI 서비스를 위한 프로토콜
protocol AIServiceProtocol {
  var delegate: AIServiceDelegate? { get set }
  var configuration: AIServiceConfiguration { get }
  
  /// 텍스트를 AI 서비스로 전송하여 응답을 받습니다
  /// - Parameter text: 변환할 텍스트
  func processText(_ text: String) async throws
}

#if DEBUG
// MARK: - Mock Implementation for Testing
final class MockAIService: AIServiceProtocol {
  weak var delegate: AIServiceDelegate?
  let configuration: AIServiceConfiguration
  var error: AIServiceError?
  var simulatedResponses: [String]
  var processingDelay: TimeInterval
  
  init(
    configuration: AIServiceConfiguration,
    simulatedResponses: [String] = ["긍정적인 ", "응답을 ", "시뮬레이션 ", "합니다!"],
    processingDelay: TimeInterval = 0.5
  ) {
    self.configuration = configuration
    self.simulatedResponses = simulatedResponses
    self.processingDelay = processingDelay
  }
  
  func processText(_ text: String) async throws {
    if let error = error {
      throw error
    }
    
    for response in simulatedResponses {
      try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
      delegate?.aiService(self, didGenerateText: response)
    }
    delegate?.aiService(self, didCompleteWithResult: .success(()))
  }
}
#endif
