//
//  AuthView.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/7/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
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
    }
    
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
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Firebase sign in failed: \(error.localizedDescription)")
                    return
                }
                print("User is signed in to Firebase with Apple")
                isLoggedIn = true
            }
            
        default:
            break
        }
    }
}

#Preview {
    AuthView(isLoggedIn: false)
}
