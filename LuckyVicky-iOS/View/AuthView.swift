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
import CryptoKit

struct AuthView: View {
    @StateObject var fsManager: FirestoreManager
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showLoadingAlert: Bool = false
    @State private var rotation: Double = 0.0
    @State private var currentText: String = "\n"
    @State private var textIndex: Int = 0
    @State private var wordIndex: Int = 0
    @State private var currentNonce: String?
    
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
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else { return }
                            authenticate(credential: appleIDCredential) { title, message in
                                // Handle failure
                            }
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
    func authenticate(credential: ASAuthorizationAppleIDCredential, failHandler: @escaping (String, String) -> Void) {
        guard let token = credential.identityToken else {
            print("Error with Firebase - Apple Login: GETTING TOKEN")
            failHandler("토큰 획득 실패!", "다시 시도해주세요")
            return
        }
        guard let tokenString = String(data: token, encoding: .utf8) else {
            print("Error with Firebase - Apple Login: In Token Parsing to String")
            failHandler("토큰 파싱 실패!", "다시 시도해주세요")
            return
        }
        guard let nonce = currentNonce else {
            print("Invalid state: A login callback was received, but no login request was sent.")
            failHandler("Nonce 오류", "다시 시도해주세요")
            return
        }
        
        // authorization Code to Unregister! => get user authorizationCode when login.
        if let authorizationCode = credential.authorizationCode,
           let codeString = String(data: authorizationCode, encoding: .utf8) {
            let urlString = "https://us-central1-luckyvicky-ios.cloudfunctions.net/getRefreshToken?code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                failHandler("URL 오류", "다시 시도해주세요")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Network request failed: \(error.localizedDescription)")
                    failHandler("네트워크 오류", "다시 시도해주세요")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    failHandler("데이터 없음", "다시 시도해주세요")
                    return
                }
                
                let refreshToken = String(data: data, encoding: .utf8) ?? ""
                print("Refresh Token: \(refreshToken)")
                UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                UserDefaults.standard.synchronize()
            }
            task.resume()
        }

        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        Auth.auth().signIn(with: firebaseCredential) { (result, err) in
            if let err = err {
                print("Error signing in with Apple: \(err.localizedDescription)")
                failHandler("로그인 실패", err.localizedDescription)
                return
            }
            // Handle successful login
            fsManager.checkUserExists(userID: result!.user.uid) { exists in
                if exists {
                    fsManager.fetchUserUsage(userID: result!.user.uid) { result in
                        switch result {
                        case .success(let data):
                            print("User data: \(data)")
                            isLoggedIn = true
                        case .failure(let error):
                            print("Error fetching user info: \(error.localizedDescription)")
                        }
                    }
                } else {
                    fsManager.saveUserInfo(userID: result?.user.uid ?? "", name: result?.user.displayName ?? "", email: result?.user.email ?? "")
                    isLoggedIn = true
                }
            }
        }
    }
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

#Preview {
    AuthView(fsManager: FirestoreManager(), isLoggedIn: false)
}
