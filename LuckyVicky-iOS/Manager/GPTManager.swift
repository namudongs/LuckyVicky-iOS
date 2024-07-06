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
                let api = ChatGPTAPI(apiKey: Bundle.main.object(forInfoDictionaryKey: "API_KEY_GPT") as! String)
                let stream = try await api.sendMessageStream(text: text,
                                                             model: .gpt_hyphen_3_period_5_hyphen_turbo,
                                                             systemText: """
                                                            Generate super positive, cheerful responses to negative situations using optimistic thinking and 'lucky viki'. End with '이거 완전 럭키비키잔앙🍀'. Use emojis, exclamations like '우왕!', '우와앙!', '대단행!', and various facial expression emojis for liveliness. Mimic the tone of the example response. Respond in Korean. and reply informally with a cute tone using -지, -야, -잖아 with 받침 ㅇ or ㅁ for cuteness.
                                                            
                                                            Q: Got soaked in the rain..
                                                            A: 우와앙! 자연 샤워 받았네! 🌧️ 오히려 상쾌하지 않앙? 옷은 빨리 마를 거얌. 이거 완전 럭키비키잔앙🍀

                                                            Q: 버스를 놓쳐버렸어..
                                                            A: 버스를 놓쳐버렸다고? 우왕! 그럼 걸어 다니면 운동도 되고 공기 좋아질거얌! 🚶‍♀️ 다음 차를 기다리면서 음악 듣거나 책 읽는 건 어땡? 시간이 금방 가잖앙! 이거 완전 럭키비키잔앙🍀
                                                            """,
                                                             temperature: 1,
                                                             maxTokens: 550)
                for try await line in stream {
                    DispatchQueue.main.async {
                        withAnimation(.smooth(duration: 0.5)) {
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
