//
//  StorageService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

protocol StorageService {
  /// 사용자의 사용량 정보를 조회합니다.
  func fetchUserUsage(userID: String) async throws -> UsageInfo
  
  /// 사용자의 사용량을 업데이트합니다.
  func updateUserUsage(userID: String, usedCount: Int) async throws
  
  /// 새로운 사용자 정보를 저장합니다.
  func saveUserInfo(userID: String, name: String, email: String) async throws
  
  /// 앱 설정을 조회합니다.
  func fetchAppSettings() async throws -> AppSettings
  
  /// 사용자의 사용량을 초기화합니다.
  func resetUserUsage(userID: String) async throws
  
  /// 계정 삭제를 요청합니다.
  func requestAccountDeletion(userID: String) async throws
}
