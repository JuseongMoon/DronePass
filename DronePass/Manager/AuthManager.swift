//
//  AuthManager.swift
//  DronePass
//
//  Created by 문주성 on 7/26/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@Observable
class AuthManager {
    
    static let shared = AuthManager()
    
    var currentAuthUser: FirebaseAuth.User?
    var currentUser: User?
    var isAuthenticated: Bool {
        return currentAuthUser != nil
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var isLoadingUserData = false // 중복 호출 방지 플래그
    
    init() {
        currentAuthUser = Auth.auth().currentUser
        
        // AppleLoginManager의 로그인 상태 변경을 구독
        AppleLoginManager.shared.$isLogin
            .sink { [weak self] isLoggedIn in
                if isLoggedIn {
                    self?.currentAuthUser = Auth.auth().currentUser
                    Task {
                        await self?.loadCurrentUserData()
                    }
                } else {
                    self?.currentAuthUser = nil
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
        
        // 앱 시작 시 현재 사용자 데이터 로드
        if currentAuthUser != nil {
            Task {
                await loadCurrentUserData()
            }
        }
    }
    
    /// Firebase Auth의 현재 사용자 객체가 준비될 때까지 대기하고 `currentAuthUser`를 설정합니다.
    /// 로그인 직후 즉시 접근 시점 경합을 방지하기 위한 안전장치입니다.
    /// - Parameter timeout: 최대 대기 시간(초)
    /// - Returns: 인증 사용자 객체가 준비되었는지 여부
    @discardableResult
    func ensureAuthUserAvailable(timeout: TimeInterval = 3.0) async -> Bool {
        // 이미 설정되어 있으면 즉시 성공
        if let user = self.currentAuthUser ?? Auth.auth().currentUser {
            self.currentAuthUser = user
            return true
        }
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if let user = Auth.auth().currentUser {
                await MainActor.run {
                    self.currentAuthUser = user
                }
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        return self.currentAuthUser != nil
    }

    // Apple 로그인 완료 후 사용자 데이터 생성 또는 업데이트
    func handleAppleLoginSuccess(email: String?) async {
        // 로그인 직후 Auth.user가 nil일 수 있어 보장 루틴 수행
        let authReady = await ensureAuthUserAvailable()
        guard authReady, let userId = (self.currentAuthUser ?? Auth.auth().currentUser)?.uid else {
            print("DEBUG: No current auth user found")
            return
        }
        
        print("🔍 DEBUG: Firebase Auth UID: \(userId)")
        print("🔍 DEBUG: Email: \(email ?? "Hidden")")
        
        // 사용자 데이터 정리 (중복 문서 확인 및 제거)
        await cleanupUserData(correctUserId: userId, email: email)
        
        // 기존 사용자 데이터가 있는지 확인
        if await loadUserData(userId: userId) == nil {
            // 새 사용자인 경우 데이터 생성
            await uploadUserData(userId: userId, email: email)
        } else {
            // 기존 사용자인 경우 현재 데이터 로드
            await loadCurrentUserData()
        }
        
        // 로그인 성공 시 클라우드 백업 자동 활성화
        await MainActor.run {
            if !SettingManager.shared.isCloudBackupEnabled {
                SettingManager.shared.isCloudBackupEnabled = true
                print("✅ 로그인 시 클라우드 백업 자동 활성화")
            }
        }
        
        // 로그인 성공 후 실시간 백업이 활성화된 경우 자동 동기화
        await performAutoSyncIfEnabled()

        // 실시간 동기화 리스너도 즉시 재가동하여 재시작 없이 동작 보장
        await MainActor.run {
            RealtimeSyncManager.shared.resetAndRestartRealtimeSync()
        }
    }
    
    /// 로컬 데이터 백업 생성
    private func createLocalDataBackup() async {
        await MainActor.run {
            let localShapes = ShapeFileStore.shared.shapes
            if !localShapes.isEmpty {
                // 백업 파일 생성
                let backupURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("shapes_backup_\(Date().timeIntervalSince1970).json")
                
                do {
                    let data = try JSONEncoder().encode(localShapes)
                    try data.write(to: backupURL)
                    print("💾 로컬 데이터 백업 생성: \(backupURL.lastPathComponent)")
                } catch {
                    print("❌ 로컬 데이터 백업 생성 실패: \(error)")
                }
            }
        }
    }
    
    /// 로컬 데이터 백업에서 복구
    private func restoreFromLocalBackup() async -> Bool {
        await MainActor.run {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            do {
                let backupFiles = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                    .filter { $0.lastPathComponent.hasPrefix("shapes_backup_") }
                    .sorted { $0.lastPathComponent > $1.lastPathComponent } // 최신 파일 우선
                
                if let latestBackup = backupFiles.first {
                    let data = try Data(contentsOf: latestBackup)
                    let shapes = try JSONDecoder().decode([ShapeModel].self, from: data)
                    
                    ShapeFileStore.shared.shapes = shapes
                    ShapeFileStore.shared.saveShapes()
                    
                    print("✅ 로컬 백업에서 복구 완료: \(shapes.count)개 도형")
                    return true
                }
            } catch {
                print("❌ 로컬 백업 복구 실패: \(error)")
            }
            
            return false
        }
    }
    
    // Apple 로그인용 사용자 데이터 업로드
    private func uploadUserData(userId: String, email: String?) async {
        let user = User(id: userId, email: email)
        self.currentUser = user
        
        do {
            // User 구조체를 딕셔너리로 변환
            let userData: [String: Any] = [
                "id": user.id,
                "email": user.email as Any,
                "createdAt": Timestamp(date: user.createdAt)
            ]
            
            try await Firestore.firestore().collection("users").document(user.id).setData(userData)
            print("DEBUG: Successfully uploaded user data - UID: \(userId), Email: \(email ?? "Hidden")")
        } catch {
            print("DEBUG: Failed to upload user data with error \(error.localizedDescription)")
        }
    }
    
    // 현재 사용자 데이터 로드
    func loadCurrentUserData() async {
        // 중복 호출 방지
        if isLoadingUserData {
            print("DEBUG: 사용자 데이터 로딩 중... 중복 호출 방지")
            return
        }
        
        guard let userId = self.currentAuthUser?.uid else { 
            print("DEBUG: No auth user available to load data")
            return 
        }
        
        isLoadingUserData = true
        defer { isLoadingUserData = false }
        
        do {
            let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                self.currentUser = parseUserFromData(data)
                print("DEBUG: Successfully loaded current user data - UID: \(userId)")
            } else {
                print("DEBUG: User document does not exist, creating new user data")
                // 문서가 없으면 현재 Firebase Auth 정보로 새로 생성
                let email = currentAuthUser?.email
                await uploadUserData(userId: userId, email: email)
            }
        } catch {
            print("DEBUG: Failed to load user data with error \(error.localizedDescription)")
            // 에러 발생 시 기본 사용자 데이터 생성
            let email = currentAuthUser?.email
            await uploadUserData(userId: userId, email: email)
        }
    }
    
    // 특정 사용자 데이터 로드
    func loadUserData(userId: String) async -> User? {
        do {
            let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                return parseUserFromData(data)
            } else {
                return nil
            }
        } catch {
            print("DEBUG: Failed to load user data with error \(error.localizedDescription)")
            return nil
        }
    }
    
    // Firestore 데이터를 User 객체로 변환
    private func parseUserFromData(_ data: [String: Any]) -> User? {
        guard let id = data["id"] as? String else {
            print("DEBUG: Failed to parse user ID from Firestore data")
            return nil
        }
        
        let email = data["email"] as? String
        return User(id: id, email: email)
    }
    
    // 로그아웃
    func signout() {
        do {
            try Auth.auth().signOut()
            currentAuthUser = nil
            currentUser = nil
            
            // 로그아웃 시 도형 데이터 정리
            Task { @MainActor in
                // ShapeFileStore에서 중복 제거
                let currentShapes = ShapeFileStore.shared.shapes
                let uniqueShapes = Array(Set(currentShapes.map { $0.id })).compactMap { id in
                    currentShapes.first { $0.id == id }
                }
                
                if uniqueShapes.count != currentShapes.count {
                    print("🧹 로그아웃 시 중복 도형 제거: \(currentShapes.count)개 → \(uniqueShapes.count)개")
                    ShapeFileStore.shared.shapes = uniqueShapes
                    ShapeFileStore.shared.saveShapes()
                }
            }
            
            print("DEBUG: Successfully signed out")
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    /// 로그인 성공 후 실시간 백업이 활성화된 경우 자동 동기화
    private func performAutoSyncIfEnabled() async {
        if SettingManager.shared.isCloudBackupEnabled {
            print("🔄 로그인 후 자동 동기화 시작...")
            
            // 동기화 전 로컬 데이터 백업 생성
            await createLocalDataBackup()
            
            do {
                // 인증 준비 보장 (로그인 직후 경합 방지)
                _ = await ensureAuthUserAvailable()
                // 1. 로컬 데이터 상태 확인
                let localShapes = await MainActor.run {
                    return ShapeFileStore.shared.shapes
                }
                let hasLocalData = !localShapes.isEmpty
                
                // 2. 마지막 동기화 시간 확인
                let lastSyncTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date ?? Date.distantPast
                let isFirstSync = lastSyncTime == Date.distantPast
                
                // 3. 로컬 변경사항 확인
                let hasLocalChanges = await MainActor.run {
                    return UserDefaults.standard.object(forKey: "lastLocalModificationTime") != nil
                }
                
                print("🔍 동기화 상태 분석:")
                print("   - 로컬 데이터: \(localShapes.count)개")
                print("   - 첫 동기화: \(isFirstSync ? "예" : "아니오")")
                print("   - 로컬 변경사항: \(hasLocalChanges ? "있음" : "없음")")
                
                // 4. 동기화 전략 결정
                if hasLocalData && (isFirstSync || hasLocalChanges) {
                    // 로컬 데이터가 있고 첫 동기화이거나 변경사항이 있는 경우
                    print("📤 로컬 데이터를 Firebase에 우선 업로드합니다...")
                    
                    let activeLocalShapes = await MainActor.run {
                        return ShapeFileStore.shared.shapes
                    }
                    
                    if !activeLocalShapes.isEmpty {
                        try await ShapeFirebaseStore.shared.saveShapes(activeLocalShapes)
                        print("✅ 로컬 데이터 Firebase 업로드 완료: \(activeLocalShapes.count)개 활성 도형")
                        
                        // 변경 추적 초기화
                        await MainActor.run {
                            UserDefaults.standard.removeObject(forKey: "lastLocalModificationTime")
                        }
                    }
                    
                    // 로컬 데이터를 유지하면서 Firebase의 추가 데이터 병합 + 색상 동기화
                    print("🔄 로컬 데이터를 유지하면서 Firebase의 추가 데이터 병합...")
                    let firebaseShapes = try await ShapeFirebaseStore.shared.loadShapes()
                    
                    await MainActor.run {
                        let currentLocalShapes = ShapeFileStore.shared.shapes
                        let localShapeIds = Set(currentLocalShapes.map { $0.id })
                        
                        // Firebase에만 있는 도형들을 로컬에 추가 (로컬 데이터는 보존)
                        let shapesToAdd = firebaseShapes.filter { !localShapeIds.contains($0.id) }
                        
                        var mutatedLocal = currentLocalShapes
                        if !shapesToAdd.isEmpty {
                            mutatedLocal.append(contentsOf: shapesToAdd)
                            print("✅ Firebase의 추가 도형 \(shapesToAdd.count)개를 로컬에 병합 완료")
                        } else {
                            print("✅ Firebase에 추가 데이터가 없어 로컬 데이터 유지")
                        }
                        
                        // 서버 기준으로 활성 도형 색상 통일 (만료된 도형 제외)
                        if let unifiedColor = firebaseShapes.first(where: { $0.deletedAt == nil })?.color {
                            var changedCount = 0
                            for i in 0..<mutatedLocal.count {
                                if mutatedLocal[i].deletedAt == nil && mutatedLocal[i].color != unifiedColor {
                                    mutatedLocal[i].color = unifiedColor
                                    changedCount += 1
                                }
                            }
                            if changedCount > 0 {
                                print("🎨 로컬 활성 도형 색상 통일: \(changedCount)개 → \(unifiedColor)")
                            }
                        }
                        
                        // 동일 ID 도형은 서버 updatedAt이 더 최신인 경우에만 서버로 덮어쓰기 (LWW)
                        let serverById = Dictionary(uniqueKeysWithValues: firebaseShapes.map { ($0.id, $0) })
                        var overwriteCount = 0
                        for i in 0..<mutatedLocal.count {
                            if let serverShape = serverById[mutatedLocal[i].id], serverShape.updatedAt >= mutatedLocal[i].updatedAt {
                                if mutatedLocal[i] != serverShape {
                                    mutatedLocal[i] = serverShape
                                    overwriteCount += 1
                                }
                            }
                        }
                        if overwriteCount > 0 {
                            print("🔁 서버 값으로 덮어쓰기(LWW): \(overwriteCount)개")
                        }
                        
                        ShapeFileStore.shared.shapes = mutatedLocal
                        ShapeFileStore.shared.saveShapes()
                    }
                    
                } else if !hasLocalData {
                    // 로컬 데이터가 없는 경우 Firebase에서 다운로드
                    print("📝 로컬 데이터가 없어 Firebase에서 데이터를 다운로드합니다...")
                    
                    print("📥 Firebase에서 도형 데이터 다운로드 시작...")
                    let firebaseShapes = try await ShapeFirebaseStore.shared.loadShapes()
                    
                    print("📥 Firebase 데이터로 로컬 업데이트합니다...")
                    await MainActor.run {
                        ShapeFileStore.shared.shapes = firebaseShapes
                        ShapeFileStore.shared.saveShapes()
                    }
                    print("✅ Firebase 데이터로 로컬 업데이트 완료: \(firebaseShapes.count)개")
                    
                } else {
                    // 로컬 데이터가 있고 변경사항이 없는 경우 변경사항만 확인
                    print("📝 로컬 데이터가 있고 변경사항이 없어 변경사항만 확인합니다...")
                    
                    // Firebase에서 변경사항 확인
                    let hasChanges = try await ShapeFirebaseStore.shared.hasChanges()
                    
                    if hasChanges {
                        print("🔄 Firebase에 변경사항이 감지되어 병합합니다...")
                        let firebaseShapes = try await ShapeFirebaseStore.shared.loadShapes()
                        
                        await MainActor.run {
                            let currentLocalShapes = ShapeFileStore.shared.shapes
                            let localShapeIds = Set(currentLocalShapes.map { $0.id })
                            
                            // Firebase에만 있는 도형들을 로컬에 추가
                            let shapesToAdd = firebaseShapes.filter { !localShapeIds.contains($0.id) }
                            
                            var mutatedLocal = currentLocalShapes
                            if !shapesToAdd.isEmpty {
                                mutatedLocal.append(contentsOf: shapesToAdd)
                                print("✅ Firebase의 추가 도형 \(shapesToAdd.count)개를 로컬에 병합 완료")
                            } else {
                                print("✅ Firebase에 추가 데이터가 없음")
                            }
                            
                            // 서버 기준으로 활성 도형 색상 통일 (만료된 도형 제외)
                            if let unifiedColor = firebaseShapes.first(where: { $0.deletedAt == nil })?.color {
                                var changedCount = 0
                                for i in 0..<mutatedLocal.count {
                                    if mutatedLocal[i].deletedAt == nil && mutatedLocal[i].color != unifiedColor {
                                        mutatedLocal[i].color = unifiedColor
                                        changedCount += 1
                                    }
                                }
                                if changedCount > 0 {
                                    print("🎨 로컬 활성 도형 색상 통일: \(changedCount)개 → \(unifiedColor)")
                                }
                            }
                            
                            // 동일 ID 도형은 서버 updatedAt이 더 최신인 경우에만 서버로 덮어쓰기 (LWW)
                            let serverById = Dictionary(uniqueKeysWithValues: firebaseShapes.map { ($0.id, $0) })
                            var overwriteCount = 0
                            for i in 0..<mutatedLocal.count {
                                if let serverShape = serverById[mutatedLocal[i].id], serverShape.updatedAt >= mutatedLocal[i].updatedAt {
                                    if mutatedLocal[i] != serverShape {
                                        mutatedLocal[i] = serverShape
                                        overwriteCount += 1
                                    }
                                }
                            }
                            if overwriteCount > 0 {
                                print("🔁 서버 값으로 덮어쓰기(LWW): \(overwriteCount)개")
                            }
                            
                            ShapeFileStore.shared.shapes = mutatedLocal
                            ShapeFileStore.shared.saveShapes()
                        }
                    } else {
                        print("✅ 변경사항이 없어 동기화를 건너뜁니다.")
                    }
                }
                
                // 동기화 시간 업데이트
                UserDefaults.standard.set(Date(), forKey: "lastSyncTime")
                UserDefaults.standard.set(Date(), forKey: "lastBackupTime")
                
            } catch {
                print("❌ 로그인 후 자동 동기화 실패: \(error)")
                
                // 동기화 실패 시 백업에서 복구 시도
                print("🔄 동기화 실패로 인한 백업 복구 시도...")
                let restored = await restoreFromLocalBackup()
                if restored {
                    print("✅ 백업에서 복구 성공")
                } else {
                    print("❌ 백업 복구 실패")
                }
            }
        } else {
            print("📝 실시간 백업이 비활성화되어 있어 자동 동기화를 건너뜁니다.")
        }
    }
    
    // 사용자 데이터 정리 (중복 문서 제거)
    private func cleanupUserData(correctUserId: String, email: String?) async {
        print("🔧 DEBUG: 사용자 데이터 정리 시작 - 올바른 UID: \(correctUserId)")
        
        do {
            // users 컬렉션의 모든 문서 검색 (같은 이메일을 가진 문서들)
            let query = Firestore.firestore().collection("users")
            let querySnapshot = try await query.getDocuments()
            
            var foundCorrectDocument = false
            var documentsToDelete: [String] = []
            
            for document in querySnapshot.documents {
                let docId = document.documentID
                let data = document.data()
                let docEmail = data["email"] as? String
                
                print("🔍 DEBUG: 문서 발견 - ID: \(docId), Email: \(docEmail ?? "nil")")
                
                if docId == correctUserId {
                    // 올바른 문서 발견
                    foundCorrectDocument = true
                    print("✅ DEBUG: 올바른 사용자 문서 발견: \(docId)")
                } else if docEmail == email && email != nil {
                    // 같은 이메일을 가진 다른 문서 (삭제 대상)
                    documentsToDelete.append(docId)
                    print("⚠️ DEBUG: 중복 사용자 문서 발견 (삭제 예정): \(docId)")
                }
            }
            
            // 중복 문서들 삭제
            for docId in documentsToDelete {
                do {
                    // 해당 사용자의 shapes 데이터가 있다면 올바른 사용자로 이전
                    await migrateShapesIfNeeded(fromUserId: docId, toUserId: correctUserId)
                    
                    // 중복 사용자 문서 삭제
                    try await Firestore.firestore().collection("users").document(docId).delete()
                    print("🗑️ DEBUG: 중복 사용자 문서 삭제 완료: \(docId)")
                } catch {
                    print("❌ DEBUG: 중복 문서 삭제 실패 - \(docId): \(error.localizedDescription)")
                }
            }
            
            if !foundCorrectDocument {
                print("📝 DEBUG: 올바른 사용자 문서가 없음. 새로 생성해야 함.")
            }
            
        } catch {
            print("❌ DEBUG: 사용자 데이터 정리 실패: \(error.localizedDescription)")
        }
    }
    
    // shapes 데이터가 있다면 올바른 사용자로 이전
    private func migrateShapesIfNeeded(fromUserId: String, toUserId: String) async {
        do {
            // 이전할 사용자의 shapes 컬렉션 확인
            let shapesQuery = Firestore.firestore().collection("users").document(fromUserId).collection("shapes")
            let shapesSnapshot = try await shapesQuery.getDocuments()
            
            if !shapesSnapshot.documents.isEmpty {
                print("📦 DEBUG: \(fromUserId)에서 \(toUserId)로 \(shapesSnapshot.documents.count)개 도형 이전 시작")
                
                // 각 shape 문서를 올바른 사용자로 복사
                for shapeDoc in shapesSnapshot.documents {
                    let shapeData = shapeDoc.data()
                    let shapeId = shapeDoc.documentID
                    
                    // 올바른 사용자의 shapes 컬렉션에 추가
                    try await Firestore.firestore()
                        .collection("users")
                        .document(toUserId)
                        .collection("shapes")
                        .document(shapeId)
                        .setData(shapeData)
                    
                    print("✅ DEBUG: 도형 이전 완료: \(shapeId)")
                }
                
                print("🎉 DEBUG: 모든 도형 이전 완료")
            } else {
                print("📭 DEBUG: \(fromUserId)에 이전할 도형 없음")
            }
        } catch {
            print("❌ DEBUG: 도형 이전 실패: \(error.localizedDescription)")
        }
    }
}
