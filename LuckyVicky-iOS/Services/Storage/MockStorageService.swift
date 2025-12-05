//
//  MockStorageService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation

/// 테스팅을 위한 Mock 구현체입니다.
#if DEBUG
final class MockStorageService: StorageService {
  var userUsage = UsageInfo(usedCount: 5, lastUsedTime: Date().toString())
  var appSettings = AppSettings(maxUsageCount: 20, canDeleteAccount: true)
  var error: StorageError?
  
  func fetchUserUsage(userID: String) async throws -> UsageInfo {
    if let error = error { throw error }
    return userUsage
  }
  
  func updateUserUsage(userID: String, usedCount: Int) async throws {
    if let error = error { throw error }
  }
  
  func saveUserInfo(userID: String, name: String, email: String) async throws {
    if let error = error { throw error }
  }
  
  func fetchAppSettings() async throws -> AppSettings {
    if let error = error { throw error }
    return appSettings
  }
  
  func resetUserUsage(userID: String) async throws {
    if let error = error { throw error }
    userUsage = UsageInfo(usedCount: 0, lastUsedTime: Date().toString())
  }
  
  func requestAccountDeletion(userID: String) async throws {
    if let error = error { throw error }
  }
}
#endif
