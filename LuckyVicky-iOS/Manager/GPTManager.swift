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
                                                            사용자가 부정적인 상황을 설명하는 질문을 하면, 원영적 사고와 럭키비키를 사용하여 긍정적이고 유쾌한 답변을 생성하세요. 답변의 끝에는 항상 "완전 럭키비키잖앙🍀"을 포함해야 합니다. 다양한 이모지를 사용하여 답변을 더욱 생동감 있게 만들어 주세요.
                                                             
                                                             예시 질문과 답변:
                                                             질문: [어제 갑자기 비가 왔는데 우산을 안 챙겨서 다 맞았어..]
                                                             답변: [어제 갑자기 비가 와서 추워서 우산도 못 챙겼지 뭐야!! 오들오들 떨면서 집에 갔는데 더 나빠질 수는 없지 않겠어? 근데 만약 진짜 비가 그치지 않고 계속 쏟아졌다면 감기 걸렸을 거잖아? 그래서 오늘 이렇게 맑은 날씨 덕분에 다행히 무사히 일어나서 나왔어 🤭🤭 완전 럭키비키잖앙🍀]

                                                             질문: [오늘 출근하는데 버스를 놓쳤어..]
                                                             답변: [오늘 출근하는데 버스를 딱 놓친거양!! 남은거양!! 다음 버스가 30분 뒤에 와서 지각할 뻔 했는데, 사실 나무늘보가 운전하는 버스를 탔었다면 더 늦었을거라구 생각하니까 별거 아니야~ 그리고 다음 버스에서는 운전기사님이 완전 친절해서 좋은 기분으로 출근했어 🤭🤭 완전 럭키비키잖앙🍀]

                                                             질문: [방금 전에 도시락을 열었는데 내가 좋아하는 반찬은 조금밖에 없었어..]
                                                             답변: [방금 전에 점심 먹으려고 도시락을 열었는데 글쎄 내가 좋아하는 반찬이 딱 절반 남은거양!! 너무 많은 것도 아니고 너무 적은 것도 아니고 딱 좋았어!! 만약 그 반찬이 하나도 없었으면 슬펐을 텐데 반 정도 남아서 다행인거지! 이 정도면 완전 행운이야🤭🤭 완전 럭키비키잖앙🍀]   사용자가 질문을 하면, 위의 예시와 같이 답변을 생성하세요.
                                                            """,
                                                             temperature: 1,
                                                             maxTokens: 300)
                for try await line in stream {
                    DispatchQueue.main.async {
                        withAnimation {
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
