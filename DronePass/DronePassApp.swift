//
//  DronePassApp.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//


import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif


#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    #if canImport(FirebaseCore)
    FirebaseApp.configure()
    #endif
    // 최초 설치 시 기본 설정 등록: 일단위 입력 기본 ON
    UserDefaults.standard.register(defaults: [
      "isDateOnlyMode": true
    ])
    
    // Firestore 설정을 앱 시작 시 한 번만 수행
    #if canImport(FirebaseFirestore)
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = true
    settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
    Firestore.firestore().settings = settings
    #endif
    
    // 앱 시작 시 마이그레이션 한 번만 실행
    MigrationManager.shared.performAllMigrationsIfNeeded()
    print("✅ 앱 시작 시 마이그레이션 체크 완료")
    
    // 실시간 동기화 매니저 초기화 (로그인 상태에 따라 자동으로 시작/중지됨)
    _ = RealtimeSyncManager.shared
    print("✅ 실시간 동기화 매니저 초기화 완료")
    
    return true
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // 실시간 동기화가 비활성화된 경우에만 변경사항 체크
    if !RealtimeSyncManager.shared.isRealtimeSyncEnabled {
      ChangeDetectionManager.shared.checkForChangesIfNeeded()
    } else {
      print("📝 실시간 동기화가 활성화되어 있어 수동 변경사항 체크를 건너뜁니다.")
    }
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // 앱이 백그라운드로 갈 때 변경사항 체크 상태 리셋
    ChangeDetectionManager.shared.resetCheckStatus()
  }
}
#endif


@main
struct DronePassApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    var body: some Scene {
        WindowGroup {
            MainTabView() // MainTabView로 변경!
        }
    }
}


