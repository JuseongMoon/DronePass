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
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @StateObject private var settingManager = SettingManager.shared
    
    // 동기화 상태 관련 State 변수들
    @State private var isSyncing = false
    @State private var showSyncResult = false
    @State private var syncResultMessage = ""
    @State private var syncResultIsSuccess = false
    
    var body: some View {
        VStack {
            List {
                Section {
                    Toggle(isOn: $settingManager.isCloudBackupEnabled) {
                        HStack {
                            Text("실시간 서버 백업")
                            if isSyncing {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSyncing)
                    .onChange(of: settingManager.isCloudBackupEnabled) { newValue in
                        if newValue && AppleLoginManager.shared.isLogin {
                            // 클라우드 백업 활성화 시 즉시 동기화
                            Task {
                                await syncToCloud()
                            }
                        }
                    }
                    
                    Button {
                        Task {
                            await syncToCloud()
                        }
                    } label: {
                        HStack {
                            Text("지금 백업하기")
                            if isSyncing {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(!settingManager.isCloudBackupEnabled || !AppleLoginManager.shared.isLogin || isSyncing)
                    
                    Text(lastBackupTimeText)
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
                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            if isLoggingOut {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("로그아웃")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoggingOut)
                }
            }
        }
        .navigationTitle("내 정보")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTerms) {
            NavigationView {
                TermsOfServiceView()
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationView {
                PrivacyPolicyView()
            }
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                logout()
            }
        } message: {
            Text("로그아웃하시겠습니까?")
        }
        .alert("동기화 결과", isPresented: $showSyncResult) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(syncResultMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var lastBackupTimeText: String {
        if let lastBackupTime = UserDefaults.standard.object(forKey: "lastBackupTime") as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "ko_KR")
            return "마지막 백업시간: \(formatter.string(from: lastBackupTime))"
        } else {
            return "백업 기록이 없습니다."
        }
    }
    
    // MARK: - Methods
    
    private func syncToCloud() async {
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // 로컬 파일에서 직접 모든 도형 데이터 로드 (삭제된 도형 포함)
            let allLocalShapes = await MainActor.run {
                return ShapeFileStore.shared.getAllShapesIncludingDeleted()
            }
            
            print("📤 로컬에서 백업할 모든 도형: \(allLocalShapes.count)개 (삭제된 도형 포함)")
            
            // Firebase에 모든 도형 저장 (삭제된 도형의 deletedAt 정보도 포함)
            try await ShapeFirebaseStore.shared.saveShapes(allLocalShapes)
            
            // 활성 도형 개수 계산 (사용자에게 표시용)
            let activeShapesCount = allLocalShapes.filter { $0.deletedAt == nil }.count
            
            // 백업 시간 저장
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: "lastBackupTime")
                isSyncing = false
                syncResultMessage = "클라우드 백업이 완료되었습니다. (\(activeShapesCount)개 도형)"
                syncResultIsSuccess = true
                showSyncResult = true
            }
            
            print("✅ 클라우드 백업 완료: 전체 \(allLocalShapes.count)개 (활성: \(activeShapesCount)개)")
            
        } catch {
            await MainActor.run {
                isSyncing = false
                syncResultMessage = "클라우드 백업에 실패했습니다: \(error.localizedDescription)"
                syncResultIsSuccess = false
                showSyncResult = true
            }
            
            print("❌ 클라우드 백업 실패: \(error)")
        }
    }
    
    private func logout() {
        isLoggingOut = true
        
        Task {
            // 로그아웃 전 로컬 데이터를 Firebase에 동기화
            if AppleLoginManager.shared.isLogin {
                do {
                    // 로컬의 모든 데이터를 직접 가져와서 Firebase에 백업 (삭제된 도형 포함)
                    let allLocalShapes = await MainActor.run {
                        return ShapeFileStore.shared.getAllShapesIncludingDeleted()
                    }
                    
                    let activeShapesCount = allLocalShapes.filter { $0.deletedAt == nil }.count
                    print("📤 로그아웃 전 백업할 모든 로컬 도형: \(allLocalShapes.count)개 (활성: \(activeShapesCount)개)")
                    
                    // 로컬 데이터를 Firebase에 저장 (삭제된 도형의 deletedAt 정보도 포함)
                    if !allLocalShapes.isEmpty {
                        try await ShapeFirebaseStore.shared.saveShapes(allLocalShapes)
                        print("✅ 로그아웃 전 로컬 → Firebase 동기화 완료: 전체 \(allLocalShapes.count)개 (활성: \(activeShapesCount)개)")
                    }
                } catch {
                    print("❌ 로그아웃 전 데이터 동기화 실패: \(error)")
                }
            }
            
            // AuthManager를 통해 로그아웃
            await MainActor.run {
                AuthManager.shared.signout()
                AppleLoginManager.shared.isLogin = false
                isLoggingOut = false
                dismiss()
            }
        }
    }
}

#Preview {
    ProfileView()
}
