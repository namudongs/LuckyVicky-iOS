//
//  AppSettings.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// 앱 설정을 관리하는 구조체입니다.
struct AppSettings: Equatable {
  let maxUsageCount: Int
  let canDeleteAccount: Bool
}
