//
//  StorageError.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// Storage Service의 Error를 정의하는 열거형입니다.
enum StorageError: LocalizedError {
  case noData
  case invalidData
  case updateFailed(String)
  case fetchFailed(String)
  
  var errorDescription: String? {
    switch self {
    case .noData:
      return "데이터를 찾을 수 없습니다"
    case .invalidData:
      return "유효하지 않은 데이터입니다"
    case .updateFailed(let message):
      return "업데이트 실패: \(message)"
    case .fetchFailed(let message):
      return "데이터 조회 실패: \(message)"
    }
  }
}
