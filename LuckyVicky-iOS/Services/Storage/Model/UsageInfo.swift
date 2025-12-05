//
//  UsageInfo.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// 유저의 사용량을 관리하는 구조체입니다.
struct UsageInfo: Equatable {
  let usedCount: Int
  let lastUsedTime: String
}
