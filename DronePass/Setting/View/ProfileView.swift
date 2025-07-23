//
//  ProfileView.swift
//  DronePass
//
//  Created by 문주성 on 7/22/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    @State private var isServerBackupOn = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section {
                    Toggle(isOn: $isServerBackupOn) {
                        Text("실시간 서버 백업")
                    }
                    Text("지금 백업하기")
                    Text("마지막 백업시간: 2025년 7월 22일 오전 5시 30분")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                } header: {
                    Text("사용자 정보 백업")
                }
                Section {
                    Button {
                        showTerms = true
                    } label: {
                        HStack {
                            Text("이용약관")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    Button {
                        showPrivacy = true
                    } label: {
                        HStack {
                            Text("개인정보 취급방침")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                } header: {
                    Text("약관 및 정책")
                }
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("로그아웃")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .alert("로그아웃하시겠습니까?", isPresented: $showLogoutAlert) {
                        Button("로그아웃", role: .destructive) {
                            logout()
                        }
                        Button("취소", role: .cancel) {}
                    }
                } header: {
                    Text("회원정보관리")
                }
            }
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
        
    }
    
    private func logout() {
        isLoggingOut = true
        do {
            try Auth.auth().signOut()
            LoginManager.shared.isLogin = false
            dismiss()
        } catch {
            // 로그아웃 실패 시 에러 처리 (필요시 Alert 추가)
            isLoggingOut = false
        }
    }
}

#Preview {
    ProfileView()
}
