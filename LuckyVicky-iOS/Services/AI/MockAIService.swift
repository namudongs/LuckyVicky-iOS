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
  var simulatedResponses: [String] = ["긍정적인 ", "응답을 ", "시뮬레이션 ", "합니다!"]
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
