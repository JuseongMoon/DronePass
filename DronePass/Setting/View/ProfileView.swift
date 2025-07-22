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
    
    var body: some View {
        VStack {
            Spacer()
            Text("Hello, World!")
            Spacer()
            Button(action: {
                showLogoutAlert = true
            }) {
                Text("로그아웃")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
            .padding(.bottom, 24)
            .alert("로그아웃하시겠습니까?", isPresented: $showLogoutAlert) {
                Button("로그아웃", role: .destructive) {
                    logout()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("로그아웃 시 앱의 일부 기능을 사용할 수 없습니다.")
            }
        }
        .padding()
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
