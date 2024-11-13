//
//  User.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 11/12/24.
//

import Foundation
import FirebaseAuth

/// User 정보를 관리하는 구조체입니다.
struct User: Identifiable, Equatable {
  let id: String
  let email: String
  let name: String
  var usageCount: Int
  var lastUsedTime: Date
  var isDeleted: Bool
  
  init(id: String,
       email: String,
       name: String,
       usageCount: Int = 0,
       lastUsedTime: Date = Date(),
       isDeleted: Bool = false
  ) {
    self.id = id
    self.email = email
    self.name = name
    self.usageCount = usageCount
    self.lastUsedTime = lastUsedTime
    self.isDeleted = isDeleted
  }
}

/// FirebaseAuth를 위한 초기화 Extension
extension User {
  init(from firebaseUser: FirebaseAuth.User) {
    self.id = firebaseUser.uid
    self.email = firebaseUser.email ?? ""
    self.name = firebaseUser.displayName ?? "Unknown"
    self.usageCount = 0
    self.lastUsedTime = Date()
    self.isDeleted = false
  }
}
