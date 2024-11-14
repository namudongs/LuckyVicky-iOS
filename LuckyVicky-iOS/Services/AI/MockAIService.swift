//
//  MockAIService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/13/24.
//

import Combine
import Foundation

/// 테스팅을 위한 Mock 구현체입니다.
#if DEBUG
final class MockAIService: AIServiceProtocol {
  var textPublisher = PassthroughSubject<String, Never>()
  var completionPublisher = PassthroughSubject<Result<Void, Error>, Never>()
  let configuration: AIServiceConfiguration
  var simulatedResponses: [String] = [
    "우와앙! ",
    "그걸 이렇게 생각해보는 건 어떨까옹? ",
    "사실 이게 숨겨진 선물일지도..? 🎁 ",
    "우리 함께 긍정적으로 생각해보장! ",
    "이런 기회가 또 없을 수도 있잖앙! ✨ ",
    "이거 완전 럭키비키잔앙! 🍀"
  ]
  var processingDelay: TimeInterval = 0.5
  
  init(
    configuration: AIServiceConfiguration
  ) {
    self.configuration = configuration
  }
  
  func processText(_ text: String) async throws {
    do {
      let stream = try await generateTextStream(
        inputText: simulatedResponses.joined()
      )
      
      for try await line in stream {
        textPublisher.send(line)
      }
      
      completionPublisher.send(.success(()))
      
    } catch {
      let serviceError: AIServiceError
      
      if error.localizedDescription.contains("authentication") {
        serviceError = .invalidAPIKey
      } else if error.localizedDescription.contains("rate limit") {
        serviceError = .rateLimitExceeded
      } else if error.localizedDescription.contains("network") {
        serviceError = .connectionFailed("네트워크 연결에 실패했습니다")
      } else if error.localizedDescription.contains("context length") {
        serviceError = .streamingFailed("응답이 너무 깁니다")
      } else {
        serviceError = .unknown(error)
      }
      
      completionPublisher.send(.failure(serviceError as Error))
      throw serviceError
    }
  }
  
  private func generateTextStream(inputText: String) async throws -> AsyncStream<String> {
    AsyncStream<String> { continuation in
      Task {
        for response in simulatedResponses {
          continuation.yield(response)
          try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        }
        continuation.finish()
      }
    }
  }

}
#endif
