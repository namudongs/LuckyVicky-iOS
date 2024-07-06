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
    @State private var rotation: Double = 0.0
    @State private var currentText: String = "\n"
    @State private var textIndex: Int = 0
    @State private var wordIndex: Int = 0
    
    let texts = [
        "버스를 놓쳐버렸다고? 우왕! 그럼 걸어 다니면 운동도 되고 기분도 좋아져! 🚶‍♀️ 다음 차를 기다리면서 음악 듣거나 책 읽는 건 어때? 시간이 금방 가잖아! 이거 완전 럭키비키잔앙🍀",
        "숙취가 심하다니 우왕! 파티를 너무 즐겼넹! 🥳 오늘은 몸과 마음 푹 쉬면 됑! 쉬면 다 나아질 거얌. 이거 완전 럭키비키잔앙🍀",
        "우와앙! 택시를 놓쳤다니 우연히 도보로 즐거운 산책을 할 수 있었넹! 🚶‍♂️ 아무래도 기분 전환도 되었겠징? 그리고 다음에 더 좋은 놀이가 기다리고 있옹. 이거 완전 럭키비키잔앙🍀",
        "우왕! 영화 티켓 매진이라니! 그럼 이번 주말을 더 특별하게 보낼 수 있겠징! 🎥 다른 좋은 영화를 보거나, 즐거운 액티비티를 즐길 수도 있엉! 이거 완전 럭키비키잔앙🍀🌟🎬",
        "빨래를 했는데 비가 와서 다 젖었다니 우왕! 빨래가 자연 린스 효과 받았넹! 🌧️ 이렇게 세탁해주는 하늘의 선물이얌! 다 빨리 마르겠지? 이거 완전 럭키비키잔앙🍀✨",
        "중요한 일을 해야하는데 인터넷이 끊겼다니 우와앙! 인터넷 쉬는 시간이얌! 😌 이제는 조금 쉬면서 더 잘 할 수 있엉! ✨ 중요한 일이라 더 잘 해결할 시간을 얻은 거같지 않앙? 대단행! 이거 완전 럭키비키잔앙🍀"
    ]
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Image(.luckyvicky)
                    .resizable()
                    .scaledToFit()
                    .blendMode(.screen)
                    .frame(width: 100)
                    .rotationEffect(.degrees(rotation))
                
                Text(currentText)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 300, alignment: .top)
                    .font(.system(size: 24, weight: .black))
                    .onAppear {
                        startTranslate()
                        changeText()
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
                
                Spacer()
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
            .padding()
        }
        .toast(isPresenting: $showLoadingAlert) {
            AlertToast(type: .loading)
        }
    }
    
    private func changeText() {
        let words = texts[textIndex].split(separator: " ").map(String.init)
        currentText = ""
        wordIndex = 0
        
        func displayNextWord() {
            if wordIndex < words.count {
                withAnimation(.easeIn(duration: 0.2)) {
                    currentText += (currentText.isEmpty ? "" : " ") + words[wordIndex]
                }
                wordIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    displayNextWord()
                }
            } else {
                textIndex = (textIndex + 1) % texts.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    changeText()
                }
            }
        }
        
        displayNextWord()
    }
    
    private func startTranslate() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotation = 360
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
