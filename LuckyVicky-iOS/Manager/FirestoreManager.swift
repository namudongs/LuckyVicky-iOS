//
//  FirestoreManager.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import SwiftUI
import FirebaseFirestore

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
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
