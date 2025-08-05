//
//  RealtimeSyncManager.swift
//  DronePass
//
//  Created by 문주성 on 1/29/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// 두 디바이스 간의 실시간 동기화를 관리하는 매니저
final class RealtimeSyncManager: ObservableObject {
    
    static let shared = RealtimeSyncManager()
    
    private let db = Firestore.firestore()
    private var metadataListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    // 동기화 상태 추적 (@Published로 SwiftUI 반응성 확보)
    @Published var isRealtimeSyncEnabled = false
    @Published var lastSyncTime: Date?
    @Published var syncInProgress = false
    
    // 중복 동기화 방지
    private let syncQueue = DispatchQueue(label: "com.dronepass.realtimesync", qos: .userInitiated)
    private var syncDebounceTimer: Timer?
    private let syncDebounceInterval: TimeInterval = 2.0 // 2초 디바운싱
    
    private init() {
        setupObservers()
    }
    
    /// 로그인 상태와 클라우드 백업 설정 변경을 감지
    private func setupObservers() {
        Publishers.CombineLatest(
            AppleLoginManager.shared.$isLogin,
            SettingManager.shared.$isCloudBackupEnabled
        )
        .sink { [weak self] isLogin, isCloudBackupEnabled in
            guard let self = self else { return }
            
            print("🔄 실시간 동기화 조건 변경 감지:")
            print("   - 로그인 상태: \(isLogin)")
            print("   - 클라우드 백업: \(isCloudBackupEnabled)")
            
            if isLogin && isCloudBackupEnabled {
                print("✅ 실시간 동기화 조건 충족 - 동기화 시작")
                self.startRealtimeSync()
            } else {
                print("❌ 실시간 동기화 조건 미충족 - 동기화 중지")
                self.stopRealtimeSync()
            }
        }
        .store(in: &cancellables)
    }
    
    /// 실시간 동기화 시작
    func startRealtimeSync() {
        // 기존 리스너가 있다면 먼저 정리
        if metadataListener != nil {
            metadataListener?.remove()
            metadataListener = nil
        }
        
        // 기존 타이머가 있다면 정리
        syncDebounceTimer?.invalidate()
        syncDebounceTimer = nil
        
        guard AppleLoginManager.shared.isLogin,
              SettingManager.shared.isCloudBackupEnabled,
              let userId = AuthManager.shared.currentAuthUser?.uid else {
            print("❌ 실시간 동기화 조건 미충족: 로그인 상태 또는 클라우드 백업 설정 확인 필요")
            isRealtimeSyncEnabled = false
            return
        }
        
        print("🚀 실시간 동기화 시작 - 사용자: \(userId)")
        
        // 메타데이터 실시간 리스너 설정
        let metadataRef = db.collection("users").document(userId).collection("metadata").document("server")
        
        metadataListener = metadataRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 실시간 동기화 리스너 오류: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("📝 메타데이터 문서가 존재하지 않습니다.")
                return
            }
            
            // 서버의 lastModified 시간 확인
            if let timestamp = document.data()?["lastModified"] as? Timestamp {
                let serverLastModified = timestamp.dateValue()
                self.handleServerDataChange(serverLastModified: serverLastModified)
            }
        }
        
        isRealtimeSyncEnabled = true
        print("✅ 실시간 동기화 리스너 설정 완료")
    }
    
    /// 실시간 동기화 중지
    func stopRealtimeSync() {
        print("🛑 실시간 동기화 중지")
        
        metadataListener?.remove()
        metadataListener = nil
        syncDebounceTimer?.invalidate()
        syncDebounceTimer = nil
        
        isRealtimeSyncEnabled = false
        print("✅ 실시간 동기화 리스너 제거 완료")
    }
    
    /// 서버 데이터 변경 감지 처리
    private func handleServerDataChange(serverLastModified: Date) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 마지막 동기화 시간과 비교
            let lastSyncTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date ?? Date.distantPast
            let lastLocalModification = UserDefaults.standard.object(forKey: "lastLocalModificationTime") as? Date
            
            print("🔍 서버 변경 감지:")
            print("   - 서버 마지막 수정: \(DateFormatter.korean.string(from: serverLastModified))")
            print("   - 마지막 동기화: \(DateFormatter.korean.string(from: lastSyncTime))")
            print("   - 마지막 로컬 수정: \(lastLocalModification != nil ? DateFormatter.korean.string(from: lastLocalModification!) : "없음")")
            
            // 자신이 방금 수정한 경우 동기화 건너뛰기 (무한 루프 방지)
            if let localModTime = lastLocalModification {
                let timeDifference = abs(serverLastModified.timeIntervalSince(localModTime))
                if timeDifference < 3.0 { // 3초 이내의 변경은 같은 디바이스의 변경으로 간주
                    print("⏭️ 자신의 변경사항으로 판단되어 동기화를 건너뜁니다.")
                    return
                }
            }
            
            // 서버 데이터가 더 최신인 경우에만 동기화
            if serverLastModified > lastSyncTime {
                print("🔄 서버에 새로운 변경사항이 감지되었습니다. 동기화를 시작합니다.")
                self.scheduleSync()
            } else {
                print("✅ 서버 데이터가 최신 상태입니다.")
            }
        }
    }
    
    /// 디바운싱을 적용한 동기화 스케줄링
    private func scheduleSync() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 기존 타이머 취소
            self.syncDebounceTimer?.invalidate()
            
            // 새로운 타이머 설정
            self.syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: self.syncDebounceInterval, repeats: false) { _ in
                Task {
                    await self.performRealtimeSync()
                }
            }
        }
    }
    
    /// 실제 실시간 동기화 수행
    private func performRealtimeSync() async {
        guard !syncInProgress else {
            print("⚠️ 동기화가 이미 진행 중입니다.")
            return
        }
        
        guard AppleLoginManager.shared.isLogin,
              SettingManager.shared.isCloudBackupEnabled else {
            print("❌ 동기화 조건 미충족: 로그인 상태 또는 클라우드 백업 설정 확인 필요")
            return
        }
        
        syncInProgress = true
        defer { syncInProgress = false }
        
        do {
            print("📥 실시간 동기화 시작: Firebase에서 최신 데이터 가져오기")
            
            // Firebase에서 최신 도형 데이터 가져오기
            let latestShapes = try await ShapeFirebaseStore.shared.loadShapes()
            
            await MainActor.run {
                // 로컬 데이터 업데이트
                let currentLocalCount = ShapeFileStore.shared.shapes.count
                ShapeFileStore.shared.shapes = latestShapes
                ShapeFileStore.shared.saveShapes()
                
                print("✅ 실시간 동기화 완료:")
                print("   - 이전 로컬 도형: \(currentLocalCount)개")
                print("   - 새로운 도형: \(latestShapes.count)개")
                
                // 동기화 시간 업데이트
                let now = Date()
                UserDefaults.standard.set(now, forKey: "lastSyncTime")
                self.lastSyncTime = now
                
                // 로컬 변경 추적 초기화 (동기화 후에는 로컬 변경사항이 없음)
                UserDefaults.standard.removeObject(forKey: "lastLocalModificationTime")
                
                // 색상 변경 시점 초기화 (동기화 후에는 색상 변경사항이 없음)
                ColorManager.shared.resetColorChangeTime()
                
                // UI 업데이트 알림 전송
                NotificationCenter.default.post(name: .shapesDidChange, object: nil)
                print("🔔 UI 업데이트 알림 전송 완료")
            }
            
            // 성공적인 동기화 후 재시도 카운터 초기화
            resetRetryCount()
            
        } catch {
            print("❌ 실시간 동기화 실패: \(error.localizedDescription)")
            
            // 실패한 경우 재시도 스케줄링 (최대 3회)
            scheduleRetrySync()
        }
    }
    
    /// 동기화 실패 시 재시도 스케줄링
    private func scheduleRetrySync() {
        let retryCount = UserDefaults.standard.integer(forKey: "syncRetryCount")
        
        if retryCount < 3 {
            let nextRetryCount = retryCount + 1
            UserDefaults.standard.set(nextRetryCount, forKey: "syncRetryCount")
            
            let retryDelay = Double(nextRetryCount * 5) // 5초, 10초, 15초 간격으로 재시도
            
            print("🔄 \(retryDelay)초 후 동기화 재시도 (\(nextRetryCount)/3)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                Task {
                    await self.performRealtimeSync()
                }
            }
        } else {
            print("❌ 최대 재시도 횟수 초과. 실시간 동기화를 일시 중지합니다.")
            UserDefaults.standard.removeObject(forKey: "syncRetryCount")
        }
    }
    
    /// 성공적인 동기화 후 재시도 카운터 초기화
    private func resetRetryCount() {
        UserDefaults.standard.removeObject(forKey: "syncRetryCount")
    }
    
    /// 수동 동기화 강제 실행 (디버깅 및 테스트용)
    func forceSyncNow() async {
        print("🔧 수동 동기화 강제 실행")
        await performRealtimeSync()
    }
    
    /// 현재 동기화 상태 정보
    var syncStatusInfo: String {
        var info = ""
        info += "실시간 동기화: \(isRealtimeSyncEnabled ? "활성화" : "비활성화")\n"
        info += "동기화 진행 중: \(syncInProgress ? "예" : "아니오")\n"
        
        if let lastSync = lastSyncTime {
            info += "마지막 동기화: \(DateFormatter.korean.string(from: lastSync))\n"
        } else {
            info += "마지막 동기화: 없음\n"
        }
        
        let retryCount = UserDefaults.standard.integer(forKey: "syncRetryCount")
        if retryCount > 0 {
            info += "재시도 횟수: \(retryCount)/3\n"
        }
        
        return info
    }
    
    /// 실시간 동기화 상태를 강제로 리셋하고 재시작
    func resetAndRestartRealtimeSync() {
        print("🔄 실시간 동기화 상태 강제 리셋 및 재시작")
        
        // 기존 상태 정리
        stopRealtimeSync()
        
        // 잠시 대기 후 재시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if AppleLoginManager.shared.isLogin && SettingManager.shared.isCloudBackupEnabled {
                print("✅ 조건 충족 - 실시간 동기화 재시작")
                self.startRealtimeSync()
            } else {
                print("❌ 조건 미충족 - 실시간 동기화 재시작 취소")
            }
        }
    }
    
    deinit {
        stopRealtimeSync()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let realtimeSyncStarted = Notification.Name("realtimeSyncStarted")
    static let realtimeSyncCompleted = Notification.Name("realtimeSyncCompleted")
    static let realtimeSyncFailed = Notification.Name("realtimeSyncFailed")
}