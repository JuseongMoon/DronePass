//
//  MigrationManager.swift
//  DronePass
//
//  Created by 문주성 on 7/27/25.
//

import Foundation

/**
 # MigrationManager
 
 앱 내 다양한 데이터와 설정의 버전 관리 및 마이그레이션을 담당하는 범용 관리자입니다.
 
 ## 주요 기능
 - 여러 데이터 타입별 독립적인 버전 관리
 - 순차적 마이그레이션 지원 (v1 → v2 → v3)
 - 중복 실행 방지
 - 확장 가능한 구조
 
 ## 사용 예시
 ```swift
 // 앱 시작 시 모든 마이그레이션 실행
 MigrationManager.shared.performAllMigrationsIfNeeded()
 
 // 특정 데이터 타입만 마이그레이션
 MigrationManager.shared.performMigration(for: .shape)
 ```
 
 ## 새로운 마이그레이션 추가 방법
 1. `MigrationType` enum에 새 타입 추가
 2. 해당 타입의 마이그레이션 정의 구조체 생성
 3. `migrationDefinitions`에 등록
 */
final class MigrationManager {
    
    // MARK: - Singleton
    
    static let shared = MigrationManager()
    private init() {}
    
    // MARK: - Runtime Duplicate Prevention
    
    /// 앱 런타임 중 마이그레이션이 이미 실행되었는지 추적하는 플래그
    private var hasPerformedMigrationInCurrentSession = false
    private let migrationQueue = DispatchQueue(label: "com.dronepass.migration", qos: .userInitiated)
    
    // MARK: - Migration Types
    
    /**
     마이그레이션 대상 데이터 타입
     
     새로운 데이터 타입을 추가할 때는 여기에 case를 추가하세요.
     */
    enum MigrationType: String, CaseIterable {
        case shape = "Shape"           // 도형 데이터
        case userSettings = "UserSettings"    // 사용자 설정 (향후 사용)
        case appConfig = "AppConfig"   // 앱 설정 (향후 사용)
        
        /// UserDefaults에서 사용할 키
        var versionKey: String {
            return "\(rawValue)MigrationVersion"
        }
    }
    
    // MARK: - Migration Definition Protocol
    
    /**
     마이그레이션 정의를 위한 프로토콜
     
     새로운 데이터 타입의 마이그레이션을 추가할 때 이 프로토콜을 구현하세요.
     */
    protocol MigrationDefinition {
        /// 현재 최신 버전
        var currentVersion: Int { get }
        /// 버전별 마이그레이션 작업들
        var migrationActions: [Int: () -> Void] { get }
    }
    
    // MARK: - Shape Migration Definition
    
    /**
     도형 데이터 마이그레이션 정의
     
     현재 구현된 도형 관련 마이그레이션을 관리합니다.
     */
    private struct ShapeMigrationDefinition: MigrationDefinition {
        let currentVersion: Int = 1
        
        let migrationActions: [Int: () -> Void] = [
            1: performV1Migration
            // 향후 버전 추가 예시:
            // 2: performV2Migration,
            // 3: performV3Migration
        ]
        
        /// 버전 1 마이그레이션: 날짜 필드 구조 변경 + 변경사항 감지 시스템 초기화
        /// startedAt/expireDate → createdAt/flightStartDate/flightEndDate/deletedAt
        /// 변경사항 감지 시스템 초기화
        static func performV1Migration() {
            print("📝 [Shape v1] 마이그레이션: 날짜 필드 구조 변경 + 변경사항 감지 시스템 초기화")
            print("   startedAt/expireDate → createdAt/flightStartDate/flightEndDate/deletedAt")
            print("   변경사항 감지 시스템 초기화")
            
            // 변경사항 감지 시스템 초기화
            initializeChangeDetectionSystem()
            
            // 실제 마이그레이션 로직은 ShapeModel의 커스텀 디코딩에서 처리
            // 여기서는 전역적인 마이그레이션 작업만 수행 (예: 설정 초기화 등)
        }
        
        /// 변경사항 감지 시스템 초기화
        private static func initializeChangeDetectionSystem() {
            // 기존 로컬 데이터가 있는지 확인
            let existingShapes = ShapeFileStore.shared.shapes
            let hasExistingData = !existingShapes.isEmpty
            
            if hasExistingData {
                // 기존 데이터가 있으면 과거 시간으로 설정하여 로컬 데이터가 우선적으로 업로드되도록 함
                UserDefaults.standard.set(Date.distantPast, forKey: "lastSyncTime")
                print("📝 기존 로컬 데이터 감지: \(existingShapes.count)개 도형")
                print("   → 로컬 데이터 우선 업로드 모드로 설정")
            } else {
                // 기존 데이터가 없으면 현재 시간으로 설정
                UserDefaults.standard.set(Date(), forKey: "lastSyncTime")
                print("📝 기존 로컬 데이터 없음")
                print("   → 일반 동기화 모드로 설정")
            }
            
            // 변경사항 감지 관련 설정 초기화
            UserDefaults.standard.set(true, forKey: "changeDetectionEnabled")
            
            print("✅ 변경사항 감지 시스템 초기화 완료")
        }
        
        /// 향후 버전 2 마이그레이션 (예시)
        static func performV2Migration() {
            print("📝 [Shape v2] 마이그레이션: 새로운 필드 추가")
            // 향후 필요한 마이그레이션 로직 추가
        }
        
        /// 향후 버전 3 마이그레이션 (예시)
        static func performV3Migration() {
            print("📝 [Shape v3] 마이그레이션: 데이터 구조 변경")
            // 향후 필요한 마이그레이션 로직 추가
        }
    }
    
    // MARK: - User Settings Migration Definition (향후 사용)
    
    /**
     사용자 설정 마이그레이션 정의 (예시)
     
     향후 사용자 설정 관련 마이그레이션이 필요할 때 활용할 수 있습니다.
     */
    private struct UserSettingsMigrationDefinition: MigrationDefinition {
        let currentVersion: Int = 1
        
        let migrationActions: [Int: () -> Void] = [
            1: performV1Migration
        ]
        
        static func performV1Migration() {
            print("📝 [UserSettings v1] 마이그레이션: 초기 설정 구조 생성")
            // 사용자 설정 관련 마이그레이션 로직
        }
    }
    
    // MARK: - Migration Definitions Registry
    
    /**
     마이그레이션 정의들을 등록하는 딕셔너리
     
     새로운 데이터 타입을 추가할 때는 여기에 등록하세요.
     */
    private lazy var migrationDefinitions: [MigrationType: MigrationDefinition] = [
        .shape: ShapeMigrationDefinition(),
        .userSettings: UserSettingsMigrationDefinition()
        // 새로운 타입 추가 시:
        // .appConfig: AppConfigMigrationDefinition()
    ]
    
    // MARK: - Public Methods
    
    /**
     모든 등록된 마이그레이션을 확인하고 필요한 경우 실행합니다.
     
     앱 시작 시 한 번 호출하는 것을 권장합니다.
     런타임 중 중복 실행을 방지합니다.
     */
    func performAllMigrationsIfNeeded() {
        // 런타임 중 중복 실행 방지
        guard !hasPerformedMigrationInCurrentSession else {
            print("⚠️ 마이그레이션이 이미 이번 세션에서 실행되었습니다. 건너뜀.")
            return
        }
        
        migrationQueue.sync {
            // Double-checked locking pattern
            guard !hasPerformedMigrationInCurrentSession else {
                print("⚠️ 마이그레이션이 이미 이번 세션에서 실행되었습니다. 건너뜀.")
                return
            }
            
            print("🔄 마이그레이션 관리자 시작: 등록된 타입 \(MigrationType.allCases.count)개")
            
            for migrationType in MigrationType.allCases {
                performMigration(for: migrationType)
            }
            
            print("✅ 모든 마이그레이션 확인 완료")
            
            // 마이그레이션 완료 플래그 설정
            hasPerformedMigrationInCurrentSession = true
        }
    }
    
    /**
     특정 데이터 타입의 마이그레이션을 확인하고 필요한 경우 실행합니다.
     
     - Parameter type: 마이그레이션할 데이터 타입
     */
    func performMigration(for type: MigrationType) {
        guard let definition = migrationDefinitions[type] else {
            print("⚠️ [\(type.rawValue)] 마이그레이션 정의를 찾을 수 없습니다.")
            return
        }
        
        let savedVersion = getCurrentVersion(for: type)
        let targetVersion = definition.currentVersion
        
        // 이미 최신 버전인 경우
        guard savedVersion < targetVersion else {
            if savedVersion > 0 {
                print("✅ [\(type.rawValue)] 마이그레이션 불필요: 현재 v\(savedVersion)")
            }
            return
        }
        
        print("🔄 [\(type.rawValue)] 마이그레이션 시작: v\(savedVersion) → v\(targetVersion)")
        
        // 순차적 마이그레이션 실행
        var successfulMigrations = 0
        for version in (savedVersion + 1)...targetVersion {
            if let migrationAction = definition.migrationActions[version] {
                print("🔄 [\(type.rawValue)] v\(version) 마이그레이션 실행 중...")
                
                do {
                    migrationAction()
                    successfulMigrations += 1
                    print("✅ [\(type.rawValue)] v\(version) 마이그레이션 완료")
                } catch {
                    print("❌ [\(type.rawValue)] v\(version) 마이그레이션 실패: \(error)")
                    // 마이그레이션 실패 시 중단하고 현재까지 성공한 버전만 저장
                    if successfulMigrations > 0 {
                        setCurrentVersion(savedVersion + successfulMigrations, for: type)
                    }
                    return
                }
            } else {
                print("⚠️ [\(type.rawValue)] v\(version) 마이그레이션 액션이 정의되지 않았습니다.")
            }
        }
        
        // 마이그레이션 완료 기록
        setCurrentVersion(targetVersion, for: type)
        print("✅ [\(type.rawValue)] 모든 마이그레이션 완료: v\(targetVersion)")
    }
    
    /**
     특정 데이터 타입의 현재 마이그레이션 버전을 확인합니다.
     
     - Parameter type: 확인할 데이터 타입
     - Returns: 현재 버전 번호 (기본값: 0)
     */
    func getCurrentVersion(for type: MigrationType) -> Int {
        return UserDefaults.standard.integer(forKey: type.versionKey)
    }
    
    /**
     특정 데이터 타입의 마이그레이션 버전을 리셋합니다.
     
     개발/테스트 용도로만 사용하세요.
     
     - Parameter type: 리셋할 데이터 타입
     */
    func resetMigrationVersion(for type: MigrationType) {
        UserDefaults.standard.removeObject(forKey: type.versionKey)
        UserDefaults.standard.synchronize()
        print("⚠️ [\(type.rawValue)] 마이그레이션 버전이 리셋되었습니다.")
    }
    
    /**
     모든 마이그레이션 버전을 리셋합니다.
     
     개발/테스트 용도로만 사용하세요.
     */
    func resetAllMigrationVersions() {
        for type in MigrationType.allCases {
            resetMigrationVersion(for: type)
        }
        print("⚠️ 모든 마이그레이션 버전이 리셋되었습니다.")
    }
    
    // MARK: - Private Methods
    
    /**
     특정 데이터 타입의 마이그레이션 버전을 저장합니다.
     
     - Parameters:
       - version: 저장할 버전 번호
       - type: 데이터 타입
     */
    private func setCurrentVersion(_ version: Int, for type: MigrationType) {
        UserDefaults.standard.set(version, forKey: type.versionKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Migration Manager Extensions

/**
 MigrationManager 사용을 위한 편의 확장
 */
extension MigrationManager {
    
    /**
     마이그레이션 상태 정보를 반환합니다.
     
     개발/디버깅 용도로 활용할 수 있습니다.
     */
    var migrationStatusInfo: String {
        var info = "=== 마이그레이션 상태 ===\n"
        
        for type in MigrationType.allCases {
            let currentVersion = getCurrentVersion(for: type)
            let targetVersion = migrationDefinitions[type]?.currentVersion ?? 0
            let status = currentVersion >= targetVersion ? "✅ 최신" : "⏳ 마이그레이션 필요"
            
            info += "[\(type.rawValue)] v\(currentVersion)/v\(targetVersion) \(status)\n"
        }
        
        return info
    }
    
    /**
     특정 타입의 마이그레이션이 필요한지 확인합니다.
     
     - Parameter type: 확인할 데이터 타입
     - Returns: 마이그레이션 필요 여부
     */
    func needsMigration(for type: MigrationType) -> Bool {
        guard let definition = migrationDefinitions[type] else { return false }
        return getCurrentVersion(for: type) < definition.currentVersion
    }
    
    /**
     마이그레이션이 필요한 데이터 타입들을 반환합니다.
     
     - Returns: 마이그레이션이 필요한 타입 배열
     */
    var typesNeedingMigration: [MigrationType] {
        return MigrationType.allCases.filter { needsMigration(for: $0) }
    }
}

