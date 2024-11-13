//
//  GPTService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Combine
import ChatGPTSwift
import Foundation

/// ChatGPT API를 사용한 실제 구현체입니다.
final class ChatGPTService: AIServiceProtocol {
  var textPublisher = PassthroughSubject<String, Never>()
  var completionPublisher = PassthroughSubject<Result<Void, Error>, Never>()
  let configuration: AIServiceConfiguration
  
  init(configuration: AIServiceConfiguration) {
    self.configuration = configuration
  }
  
  func processText(_ text: String) async throws {
    do {
      let api = ChatGPTAPI(apiKey: configuration.apiKey)
      let stream = try await api.sendMessageStream(
        text: text,
        model: ChatGPTModel(rawValue: configuration.model as String) ?? .gpt_hyphen_4o_mini,
        systemText: configuration.systemPrompt,
        temperature: configuration.temperature,
        maxTokens: configuration.maxTokens
      )
      
      for try await line in stream {
        textPublisher.send(line)
      }
      
      completionPublisher.send(.success(()))
      
    } catch let error {
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
      
      throw serviceError as Error
    }
  }
}

// MARK: - Factory
extension ChatGPTService {
  static func createDefault() -> ChatGPTService {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY_GPT") as! String
    let configuration = AIServiceConfiguration(
      apiKey: apiKey,
      model: "gpt-4o-mini",
      temperature: 1.0,
      maxTokens: 550,
      systemPrompt: """
            Turn negative thoughts into super positive thinking using emojis. \
            Keep the tone of the examples and say "완전 럭키비키잔앙🍀" after making it positive. \
            Speak informally and friendly.
            
            Q: 버스를 놓쳤어
            A: 우왕! 더 마음 편한 다음 차를 탈 수 있는 기회가 생겼넹! 이따가 올 다음 차는 더 편하게 탈 수 있겠넹😎 완전 럭키비키잔앙🍀
            
            Q: 밤을 새서 너무 피곤해
            A: 대단행! 오늘 밤은 엄청 잔 거잔앙! 내일은 더 상쾌하게 일어날 수 있겠넹😴 완전 럭키비키잔앙🍀
            
            Q: 마우스를 잃어버렸어..
            A: 헐! 새 마우스를 사는 건 즐거운 경험이 될 거얌! 새로운 기능을 가진 마우스로 더 편하게 컴퓨터를 사용할 수 있겠넹🖱 완전 럭키비키잔앙🍀
            
            Q: 택시랑 버스가 하나도 없어.. 날씨도 너무 더워..
            A: 우와앙! 산책하면서 햇살도 쬐면서 기분 전환할 수 있엉! 맛있는 아이스크림도 먹으면서 좋은 시간 보낼 수 있겠넹🍦 완전 럭키비키잔앙🍀
            """
    )
    return ChatGPTService(configuration: configuration)
  }
}
