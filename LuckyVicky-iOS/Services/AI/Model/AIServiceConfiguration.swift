//
//  AIServiceConfiguration.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/13/24.
//

import Foundation

/// AI Service의 설정을 관리하는 구조체입니다.
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
