//
//  AppDelegate.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit
import CoreData
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MapSketch")
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.handleCoreDataError(error)
            }
        }
        return container
    }()
    
    // MARK: - Application Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppearance()
        return true
    }

    // MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 필요한 리소스 정리
    }

    // MARK: - Core Data Saving support
    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        
            do {
                try context.save()
            } catch {
            handleCoreDataError(error as NSError)
        }
    }
    
    // MARK: - Private Methods
    private func setupAppearance() {
        // 앱 전체적인 UI 설정
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func handleCoreDataError(_ error: NSError) {
        // 에러 로깅 및 사용자에게 알림
        print("CoreData Error: \(error.localizedDescription)")
        // TODO: 적절한 에러 처리 로직 구현
    }
}

