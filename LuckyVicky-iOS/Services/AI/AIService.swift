//
//  AIService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Combine
import Foundation

/// AI Service를 위한 프로토콜입니다.
protocol AIServiceProtocol {
  var textPublisher: PassthroughSubject<String, Never> { get }
  var completionPublisher: PassthroughSubject<Result<Void, Error>, Never> { get }
  
  func processText(_ text: String) async throws
}
