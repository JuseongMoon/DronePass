//
//  LoginView.swift
//  DronePass
//
//  Created by 문주성 on 7/8/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLocationTerms = false
    @StateObject private var loginManager = AppleLoginManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 기기 유형에 따른 동적 여백 값
    private var topSpacer: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 72 : 40
    }
    private var verticalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24
    }
    private var bottomExtraPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 40 : 24
    }

    
    var body: some View {
        NavigationView {
            VStack {
                // 상단/하단 여백을 기기 유형에 맞춰 확보
                Spacer(minLength: topSpacer)
                
                // 앱 아이콘
                
                Image("LaunchLogo")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.bottom, 32)
                
                // 타이틀
                Text("로그인 / 회원가입")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.bottom, 24)
                
                Divider()
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)
                
                // SwiftUI용 Apple 로그인 버튼
                SignInWithAppleButtonView(isLogin: $loginManager.isLogin, loginError: $loginManager.loginError)
                    .frame(height: 50)
                    .frame(maxWidth: 350) // 최대 너비 제한 추가
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                
                // 약관 안내 (Apple 버튼 바로 아래로 이동)
                VStack(spacing: 0) {
                    Text("로그인 / 회원가입 시")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    HStack(spacing: 0) {
                        Button(action: { showTerms = true }) {
                            Text("이용약관")
                                .underline()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        Text(", ")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button(action: { showPrivacy = true }) {
                            Text("개인정보 취급방침")
                                .underline()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        
                        /// 위치기반서비스 미활용으로 인한 비활성화
//                        Text(", ")
//                            .font(.footnote)
//                            .foregroundColor(.secondary)
//                        Button(action: { showLocationTerms = true }) {
//                            Text("위치기반 서비스 이용약관")
//                                .underline()
//                        }
//                        .font(.footnote)
//                        .foregroundColor(.blue)
                        Text("에")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    HStack {
                        Text(" 동의하게 됩니다.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, bottomExtraPadding)
                
                Spacer(minLength: topSpacer)
            }
            .padding(.vertical, verticalPadding)
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            // NavigationLink 연결
            .background(
                Group {
                    NavigationLink(destination: TermsOfServiceView(), isActive: $showTerms) { EmptyView() }.hidden()
                    NavigationLink(destination: PrivacyPolicyView(), isActive: $showPrivacy) { EmptyView() }.hidden()
                    
                    /// 위치기반서비스 미활용으로 인한 비활성화
//                    NavigationLink(destination: LocationTermsView(), isActive: $showLocationTerms) { EmptyView() }.hidden()
                }
            )
            .alert(isPresented: Binding<Bool>(get: { loginManager.loginError != nil }, set: { _ in loginManager.loginError = nil })) {
                Alert(title: Text("로그인 오류"), message: Text(loginManager.loginError?.localizedDescription ?? "알 수 없는 오류"), dismissButton: .default(Text("확인")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loginManager.isLogin = Auth.auth().currentUser != nil
        }
        .onChange(of: loginManager.isLogin) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

// SwiftUI용 Apple 로그인 버튼 구현
struct SignInWithAppleButtonView: View {
    @Binding var isLogin: Bool
    @Binding var loginError: Error?
    @State private var currentNonce: String?
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                let nonce = AppleLoginManager.shared.randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleLoginManager.shared.sha256(nonce)
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                       let nonce = currentNonce,
                       let appleIDToken = appleIDCredential.identityToken,
                       let idTokenString = String(data: appleIDToken, encoding: .utf8) {
                        Task {
                            do {
                                try await AppleLoginManager.shared.loginWithApple(
                                    idTokenString: idTokenString, 
                                    nonce: nonce, 
                                    fullName: appleIDCredential.fullName
                                )
                                // AuthManager와 AppleLoginManager의 자동 동기화로 인해 
                                // 수동으로 isLogin을 설정할 필요 없음
                            } catch {
                                await MainActor.run { 
                                    self.loginError = error 
                                }
                            }
                        }
                    } else {
                        self.loginError = NSError(
                            domain: "AppleLogin", 
                            code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 토큰을 가져올 수 없습니다."]
                        )
                    }
                case .failure(let error):
                    self.loginError = error
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .cornerRadius(12)
        .accessibilityLabel("Apple로 계속하기")
    }
}
