//
//  LoginView.swift
//  DronePass
//
//  Created by 문주성 on 7/8/25.
//

import SwiftUI

struct LoginView: View {
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLocationTerms = false

    var body: some View {
        NavigationView {
            VStack {
                // 전체적으로 위로 밀기 위해 상단 패딩 추가
                Spacer(minLength: 16)
                
                // 앱 아이콘
                Image("DronePass_AppIcon_v2.2")
                    .resizable()
                    .frame(width: 100, height: 100)
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
                
                // Apple 로그인 버튼 (목업)
                Button(action: {}) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        Text("Apple로 계속하기")
                            .fontWeight(.semibold)
                            .font(.body)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .disabled(true) // 목업
                
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
                        Text(", ")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button(action: { showLocationTerms = true }) {
                            Text("위치기반 서비스 이용약관")
                                .underline()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
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
                .padding(.bottom, 244)
                
                Spacer(minLength: 0)
            }
            .padding(.top, 40)
            .background(Color(.systemBackground))
            .ignoresSafeArea()
            .navigationBarHidden(true)
            // NavigationLink 연결
            .background(
                Group {
                    NavigationLink(destination: TermsOfServiceView(), isActive: $showTerms) { EmptyView() }.hidden()
                    NavigationLink(destination: PrivacyPolicyView(), isActive: $showPrivacy) { EmptyView() }.hidden()
                    NavigationLink(destination: LocationTermsView(), isActive: $showLocationTerms) { EmptyView() }.hidden()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    LoginView()
}
