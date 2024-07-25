//
//  FirestoreManager.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class FirestoreManager: ObservableObject {
    let db = Firestore.firestore()
    
    func saveUserInfo(userID: String, name: String, email: String) {
        let userRef = db.collection("users").document(userID)
        userRef.setData([
            "name": name,
            "email": email,
            "usedCounts": 0,
            "lastUsedTime": Date().toString()
        ]) { error in
            if let error = error {
                print("Error saving user info: \(error.localizedDescription)")
            } else {
                print("User info successfully saved")
            }
        }
    }
    
    func deleteUserInfo(userID: String, completion: @escaping (Error?) -> Void) {
        /*
        let userRef = db.collection("users").document(userID)
        
        userRef.delete { error in
            if let error = error {
                print("Error deleting user data: \(error.localizedDescription)")
                completion(error)
            } else {
                print("User data successfully deleted")
                completion(nil)
            }
        }
         */
    }
    
    func fetchUserUsage(userID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(), let usedCounts = data["usedCounts"], let lastUsedTime = data["lastUsedTime"] {
                    completion(.success(["usedCounts": usedCounts, "lastUsedTime": lastUsedTime]))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data found"])))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
            }
        }
    }
    
    func updateUserUsage(userID: String, usedCounts: Int, lastUsedTime: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userID)
        userRef.updateData([
            "usedCounts": usedCounts,
            "lastUsedTime": lastUsedTime
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
                completion(error)
            } else {
                print("User info successfully updated")
                completion(nil)
            }
        }
    }
    
    func resetUserUsage(userID: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userID)
        userRef.updateData([
            "usedCounts": 0,
            "lastUsedTime": Date().toString()
        ]) { error in
            if let error = error {
                print("Error updating user info: \(error.localizedDescription)")
                completion(error)
            } else {
                print("User info successfully updated")
                completion(nil)
            }
        }
    }
    
    func checkUserExists(userID: String, completion: @escaping (Bool) -> Void) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { document, _ in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - 탈퇴 및 재가입 로직
    func registerUser(email: String, password: String) {
        checkAndRestoreUserData(email: email, newUid: Auth.auth().currentUser?.uid ?? "") { exists in
            if exists {
                print("Existing user data restored")
            } else {
                // 새로운 사용자 등록 로직
                Auth.auth().createUser(withEmail: email, password: password) { _, error in
                    if let error = error {
                        print("Error creating user: \(error)")
                    } else {
                        print("User successfully created")
                    }
                }
            }
        }
    }
    
    func requestAccountDeletion(userID: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        let deletionTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        if let deletionTime = deletionTime {
            userRef.updateData([
                "isDeleted": true,
                "deleteRequestTime": deletionTime
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                    completion(error)
                } else {
                    print("Document successfully updated")
                    completion(nil)
                }
            }
        } else {
            print("Error deletionTime not exist")
        }
    }
    
    func checkAndRestoreUserData(email: String, newUid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        
        usersRef.whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(false)
            } else {
                if let document = querySnapshot?.documents.first, document.data()["isDeleted"] as? Bool == true {
                    // 기존 데이터가 존재하고 비활성화된 상태일 경우
                    let userId = document.documentID
                    self.restoreUserData(userID: userId, newUid: newUid)
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func restoreUserData(userID: String, newUid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        let newUserRef = db.collection("users").document(newUid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var data = document.data() ?? [:]
                data["isDeleted"] = FieldValue.delete()
                data["deleteRequestTime"] = FieldValue.delete()
                
                newUserRef.setData(data, merge: true) { error in
                    if let error = error {
                        print("Error setting new document: \(error)")
                    } else {
                        userRef.delete { error in
                            if let error = error {
                                print("Error deleting old document: \(error)")
                            } else {
                                print("User data successfully restored and old document deleted")
                            }
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}
