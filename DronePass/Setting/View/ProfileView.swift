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
    @ObservedObject private var realtimeSyncManager = RealtimeSyncManager.shared
    
    // 동기화 상태 관련 State 변수들
    @State private var isSyncing = false
    @State private var showSyncResult = false
    @State private var syncResultMessage = ""
    @State private var syncResultIsSuccess = false
    
    var body: some View {
        VStack {
            List {
                // 실시간 클라우드 동기화 섹션
                Section {
                    // 실시간 클라우드 동기화 활성화 토글
                    Toggle(isOn: $settingManager.isCloudBackupEnabled) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("실시간 클라우드 동기화")
                                    .font(.headline)
                                Text(realtimeCloudSyncStatusText)
                                    .font(.caption)
                                    .foregroundColor(realtimeCloudSyncStatusColor)
                            }
                            if isSyncing || realtimeSyncManager.syncInProgress {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSyncing || realtimeSyncManager.syncInProgress)
                    .onChange(of: settingManager.isCloudBackupEnabled) { newValue in
                        if newValue && AppleLoginManager.shared.isLogin {
                            // 실시간 클라우드 동기화 활성화 시 즉시 백업 및 동기화
                            Task {
                                await syncToCloud()
                            }
                            
                            // 실시간 동기화 상태 강제 리셋 및 재시작
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                RealtimeSyncManager.shared.resetAndRestartRealtimeSync()
                            }
                        }
                    }
                    
                    // 마지막 동기화/백업 시간 표시
                    Text(lastSyncTimeText)
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    // 수동 백업 버튼 (실시간 클라우드 동기화가 활성화된 경우에만)
                    if settingManager.isCloudBackupEnabled && AppleLoginManager.shared.isLogin {
                        Button {
                            Task {
                                await syncToCloud()
                            }
                        } label: {
                            HStack {
                                Text("수동 백업하기")
                                if isSyncing || realtimeSyncManager.syncInProgress {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(isSyncing || realtimeSyncManager.syncInProgress)
                    }
                    
                } header: {
                    Text("동기화")
                } footer: {
                    Text(realtimeCloudSyncFooterText)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .alert("실시간 클라우드 동기화", isPresented: $showSyncResult) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(syncResultMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    // 실시간 클라우드 동기화 관련 computed properties
    private var realtimeCloudSyncStatusText: String {
        if isSyncing || realtimeSyncManager.syncInProgress {
            return "동기화 중..."
        } else if !AppleLoginManager.shared.isLogin {
            return "로그인이 필요합니다"
        } else if !settingManager.isCloudBackupEnabled {
            return "비활성화됨"
        } else if realtimeSyncManager.isRealtimeSyncEnabled {
            return "활성화 - 실시간 동기화중"
        } else {
            return "활성화 - 실시간 동기화 대기중"
        }
    }
    
    private var realtimeCloudSyncStatusColor: Color {
        if isSyncing || realtimeSyncManager.syncInProgress {
            return .blue
        } else if !AppleLoginManager.shared.isLogin {
            return .orange
        } else if !settingManager.isCloudBackupEnabled {
            return .gray
        } else if realtimeSyncManager.isRealtimeSyncEnabled {
            return .green
        } else {
            return .orange // 활성화되어 있지만 대기 중인 상태
        }
    }
    
    private var lastSyncTimeText: String {
        if let realtimeSync = realtimeSyncManager.lastSyncTime {
            return "마지막 동기화: \(DateFormatter.korean.string(from: realtimeSync))"
        } else if let lastBackupTime = UserDefaults.standard.object(forKey: "lastBackupTime") as? Date {
            return "마지막 백업: \(DateFormatter.korean.string(from: lastBackupTime))"
        } else {
            return "동기화 기록이 없습니다."
        }
    }
    
    private var realtimeCloudSyncFooterText: String {
        if !AppleLoginManager.shared.isLogin {
            return "실시간 클라우드 동기화를 사용하려면 먼저 로그인해주세요."
        } else if !settingManager.isCloudBackupEnabled {
            return "활성화하면 같은 계정으로 로그인한 모든 기기에서 도형 데이터가 실시간으로 동기화 및 백업됩니다."
        } else {
            return ""
        }
    }
    
    // MARK: - Methods
    
    private func syncToCloud() async {
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // 로컬에서 활성 도형만 로드 (삭제된 도형 제외)
            let activeLocalShapes = await MainActor.run {
                return ShapeFileStore.shared.shapes
            }
            
            print("📤 로컬에서 백업할 활성 도형: \(activeLocalShapes.count)개")
            
            // Firebase에 활성 도형만 저장
            try await ShapeFirebaseStore.shared.saveShapes(activeLocalShapes)
            
            // 동기화/백업 시간 저장
            await MainActor.run {
                UserDefaults.standard.set(Date(), forKey: "lastBackupTime")
                isSyncing = false
                syncResultMessage = "\(activeLocalShapes.count)개 도형의 동기화가 완료되었습니다."
                syncResultIsSuccess = true
                showSyncResult = true
            }
            
            print("✅ 실시간 클라우드 동기화 완료: \(activeLocalShapes.count)개 활성 도형")
            
        } catch {
            await MainActor.run {
                isSyncing = false
                syncResultMessage = "실시간 클라우드 동기화에 실패했습니다: \(error.localizedDescription)"
                syncResultIsSuccess = false
                showSyncResult = true
            }
            
            print("❌ 실시간 클라우드 동기화 실패: \(error)")
        }
    }
    
    private func logout() {
        isLoggingOut = true
        
        Task {
            // 로그아웃 전 로컬 데이터를 Firebase에 동기화
            if AppleLoginManager.shared.isLogin {
                do {
                    // 로컬에서 활성 도형만 가져와서 Firebase에 백업
                    let activeLocalShapes = await MainActor.run {
                        return ShapeFileStore.shared.shapes
                    }
                    
                    print("📤 로그아웃 전 동기화할 활성 로컬 도형: \(activeLocalShapes.count)개")
                    
                    // 활성 도형만 Firebase에 저장
                    if !activeLocalShapes.isEmpty {
                        try await ShapeFirebaseStore.shared.saveShapes(activeLocalShapes)
                        print("✅ 로그아웃 전 실시간 클라우드 동기화 완료: \(activeLocalShapes.count)개 활성 도형")
                    }
                } catch {
                    print("❌ 로그아웃 전 실시간 클라우드 동기화 실패: \(error)")
                }
            }
            
            // AuthManager를 통해 로그아웃
            await MainActor.run {
                // 맵 오버레이 정리
                NotificationCenter.default.post(name: Notification.Name("ClearMapOverlays"), object: nil)
                
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
