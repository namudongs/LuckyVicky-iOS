//
//  GPTManager.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import ChatGPTSwift
import SwiftUI

class GPTManager: ObservableObject {
    @Published var response: String = ""
    func sendMessage(from text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let api = ChatGPTAPI(apiKey: Bundle.main.object(forInfoDictionaryKey: "API_KEY_GPT") as! String)
                let stream = try await api.sendMessageStream(text: text,
                                                             model: .gpt_hyphen_3_period_5_hyphen_turbo,
                                                             systemText: """
                                                            Turn negative thoughts into super positive thinking using emojis. Keep the tone of the examples and say "완전 럭키비키잔앙🍀" after making it positive. Speak informally and friendly.

                                                            Q: 버스를 놓쳤어
                                                            A: 우왕! 더 마음 편한 다음 차를 탈 수 있는 기회가 생겼넹! 이따가 올 다음 차는 더 편하게 탈 수 있겠넹😎 완전 럭키비키잔앙🍀

                                                            Q: 밤을 새서 너무 피곤해
                                                            A: 대단행! 오늘 밤은 엄청 잔 거잔앙! 내일은 더 상쾌하게 일어날 수 있겠넹😴 완전 럭키비키잔앙🍀

                                                            Q: 마우스를 잃어버렸어..
                                                            A: 헐! 새 마우스를 사는 건 즐거운 경험이 될 거얌! 새로운 기능을 가진 마우스로 더 편하게 컴퓨터를 사용할 수 있겠넹🖱 완전 럭키비키잔앙🍀

                                                            Q: 택시랑 버스가 하나도 없어.. 날씨도 너무 더워..
                                                            A: 우와앙! 산책하면서 햇살도 쬐면서 기분 전환할 수 있엉! 맛있는 아이스크림도 먹으면서 좋은 시간 보낼 수 있겠넹🍦 완전 럭키비키잔앙🍀
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
