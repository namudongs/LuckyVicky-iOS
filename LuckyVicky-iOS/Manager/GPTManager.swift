//
//  GPTManager.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI
import ChatGPTSwift

class GPTManager: ObservableObject {
    @Published var response: String = ""
    
    func sendMessage(from text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let api = ChatGPTAPI(apiKey: Bundle.main.object(forInfoDictionaryKey: "API_KEY") as! String)
                let stream = try await api.sendMessageStream(text: text,
                                                             model: .gpt_hyphen_3_period_5_hyphen_turbo,
                                                             systemText: """
                                                            "Generate super positive thinking, cheerful responses to negative situations using optimistic thinking and 'lucky viki'. End with '이거 완전 럭키비키잔앙🍀'. Use emojis, exclamations like '우왕!', '우와앙!', '대단행!', and various facial expression emojis for liveliness. Mimic the tone of the example response. Respond in Korean. Example:
                                                            
                                                            Q: Got soaked in the rain..
                                                            A: 우와앙! 자연 샤워 받았네! 🌧️ 오히려 상쾌하지 않앙? 옷은 빨리 마를 거얌. 이거 완전 럭키비키잔앙🍀"
                                                            """,
                                                             temperature: 1,
                                                             maxTokens: 400)
                for try await line in stream {
                    DispatchQueue.main.async {
                        withAnimation(.bouncy(duration: 0.5)) {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.response += line
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
