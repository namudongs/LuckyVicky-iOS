//
//  StorageService.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import FirebaseFirestore
import Foundation

/// Firebase Firestore를 사용한 실제 구현체입니다.
final class FirestoreService: StorageService {
  private let db: Firestore
  
  init(database: Firestore = Firestore.firestore()) {
    self.db = database
  }
  
  func fetchUserUsage(userID: String) async throws -> UsageInfo {
    let documentSnapshot = try await db.collection("users")
      .document(userID)
      .getDocument()
    
    guard let data = documentSnapshot.data() else {
      throw StorageError.noData
    }
    
    return UsageInfo(
      usedCount: data["usedCounts"] as? Int ?? 0,
      totalCount: data["totalCounts"] as? Int ?? 20,
      lastUsedTime: (data["lastUsedTime"] as? String ?? "")
    )
  }
  
  func updateUserUsage(userID: String, usedCount: Int) async throws {
    try await db.collection("users")
      .document(userID)
      .updateData([
        "usedCounts": usedCount,
        "lastUsedTime": Date().toString()
      ])
  }
  
  func saveUserInfo(userID: String, name: String, email: String) async throws {
    try await db.collection("users")
      .document(userID)
      .setData([
        "name": name,
        "email": email,
        "usedCounts": 0,
        "lastUsedTime": Date().toString()
      ])
  }
  
  func fetchAppSettings() async throws -> AppSettings {
    let documentSnapshot = try await db.collection("settings")
      .document("app")
      .getDocument()
    
    guard let data = documentSnapshot.data() else {
      throw StorageError.noData
    }
    
    return AppSettings(
      maxUsageCount: data["usage"] as? Int ?? 20,
      canDeleteAccount: data["deleteable"] as? Bool ?? false
    )
  }
  
  func resetUserUsage(userID: String) async throws {
    try await db.collection("users")
      .document(userID)
      .updateData([
        "usedCounts": 0,
        "lastUsedTime": Date().toString()
      ])
  }
  
  func requestAccountDeletion(userID: String) async throws {
    let deleteTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    guard let deleteTime else { throw StorageError.updateFailed("날짜 설정 실패") }
    
    try await db.collection("users")
      .document(userID)
      .updateData([
        "isDeleted": true,
        "deleteRequestTime": deleteTime
      ])
  }
}
