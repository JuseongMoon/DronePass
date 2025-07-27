//
//  DronePassApp.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//


import SwiftUI
import FirebaseCore
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Firestore 설정을 앱 시작 시 한 번만 수행
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = true
    settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
    Firestore.firestore().settings = settings
    
    // 앱 시작 시 마이그레이션 한 번만 실행
    MigrationManager.shared.performAllMigrationsIfNeeded()
    print("✅ 앱 시작 시 마이그레이션 체크 완료")
    
    return true
  }
}


@main
struct DronePassApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            MainTabView() // MainTabView로 변경!
        }
    }
}


