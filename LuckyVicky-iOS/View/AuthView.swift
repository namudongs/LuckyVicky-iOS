//
//  AuthView.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import SwiftUI
import AlertToast
import AuthenticationServices
import FirebaseAuth

struct AuthView: View {
    @StateObject var fsManager: FirestoreManager
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showLoadingAlert: Bool = false
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    handleAuthorization(authResults)
                case .failure(let error):
                    print("Authorization failed: \(error.localizedDescription)")
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(width: 280, height: 45)
        .toast(isPresenting: $showLoadingAlert) {
            AlertToast(type: .loading)
        }
    }
}

extension AuthView {
    func handleAuthorization(_ authResults: ASAuthorization) {
        switch authResults.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nil)
            showLoadingAlert = true
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Firebase sign in failed: \(error.localizedDescription)")
                    return
                }
                print("User is signed in to Firebase with Apple")
                
                if let user = authResult?.user {
                    let name = appleIDCredential.fullName?.givenName ?? "Unknown"
                    let email = user.email ?? "Unknown"
                    
                    fsManager.checkUserExists(userID: user.uid) { exists in
                        if exists {
                            fsManager.fetchUserUsage(userID: user.uid) { result in
                                switch result {
                                case .success(let data):
                                    print("User data: \(data)")
                                case .failure(let error):
                                    print("Error fetching user info: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            fsManager.saveUserInfo(userID: user.uid, name: name, email: email)
                        }
                    }
                }
                
                isLoggedIn = true
            }
            
        default:
            break
        }
    }
    
    
    func deleteUserAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in")
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"]))
            return
        }
        
        let userID = user.uid
        
        fsManager.deleteUserInfo(userID: userID) { error in
            if let error = error {
                completion(error)
                return
            }
            
            user.delete { error in
                if let error = error {
                    print("Error deleting user account: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("User account successfully deleted")
                    completion(nil)
                }
            }
        }
    }
    
    /*
     fsManager.deleteUserAccount { error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
        } else {
            isLoggedIn = false
        }
     }
    */
}

#Preview {
    AuthView(fsManager: FirestoreManager(), isLoggedIn: false)
}
