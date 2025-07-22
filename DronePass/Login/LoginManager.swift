//
//  LoginFirebaseAuth.swift
//  DronePass
//
//  Created by 문주성 on 7/22/25.
//

import Foundation
import FirebaseAuth
import CryptoKit

import Combine

public class LoginManager: ObservableObject {
    public static let shared = LoginManager()
    public init() {
        // 앱 시작 시 로그인 상태 동기화
        self.isLogin = Auth.auth().currentUser != nil
        // Firebase Auth 상태 변경 리스너 등록
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLogin = (user != nil)
            }
        }
    }

    // 로그인 상태 및 에러를 전역에서 관찰 가능하게 관리
    @Published public var isLogin: Bool = false
    @Published public var loginError: Error? = nil
    public var currentNonce: String? = nil

    // Nonce 생성
    public func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
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
    
    // SHA256 해시
    public func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Apple 로그인 인증 처리 (nonce 포함, Firebase 12 기준)
    public func loginWithApple(idTokenString: String, nonce: String, fullName: PersonNameComponents?) async throws {
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: fullName)
        try await Auth.auth().signIn(with: credential)
    }
}
