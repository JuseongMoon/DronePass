//
//  AppDelegate.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

import UIKit // UIKit 프레임워크를 가져옵니다. (iOS 앱의 기본 UI 컴포넌트들을 사용하기 위함)
import CoreData // CoreData 프레임워크를 가져옵니다. (데이터 영구 저장을 위한 프레임워크)
import Combine // Combine 프레임워크를 가져옵니다. (반응형 프로그래밍을 위한 프레임워크)

//@main // 이 클래스가 앱의 진입점임을 나타냅니다.
class AppDelegate: UIResponder, UIApplicationDelegate { // AppDelegate 클래스를 정의합니다. UIResponder와 UIApplicationDelegate 프로토콜을 준수합니다.
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>() // Combine 구독을 저장하고 관리하기 위한 Set입니다.

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = { // CoreData의 영구 저장소를 관리하는 컨테이너입니다.
        let container = NSPersistentContainer(name: "DronePass") // "DronePass"라는 이름의 CoreData 모델을 사용하는 컨테이너를 생성합니다.
        container.loadPersistentStores { [weak self] (storeDescription, error) in // 영구 저장소를 로드합니다.
            if let error = error as NSError? { // 에러가 발생했다면
                self?.handleCoreDataError(error) // 에러 처리 함수를 호출합니다.
            }
        }
        return container // 생성된 컨테이너를 반환합니다.
    }()
    
    // MARK: - Application Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { // 앱이 처음 실행될 때 호출되는 메서드입니다.
        setupAppearance() // 앱의 전반적인 UI 설정을 초기화합니다.
        return true // 앱 실행을 계속합니다.
    }

    // MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration { // 새로운 Scene이 생성될 때 호출되는 메서드입니다.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role) // 기본 Scene 설정을 반환합니다.
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { // Scene이 삭제될 때 호출되는 메서드입니다.
        // 필요한 리소스 정리
    }

    // MARK: - Core Data Saving support
    func saveContext() { // CoreData의 변경사항을 저장하는 메서드입니다.
        let context = persistentContainer.viewContext // CoreData의 메인 컨텍스트를 가져옵니다.
        guard context.hasChanges else { return } // 변경사항이 없다면 저장하지 않고 리턴합니다.

            do {
            try context.save() // 변경사항을 저장합니다.
            } catch {
            handleCoreDataError(error as NSError) // 저장 중 에러가 발생하면 에러 처리 함수를 호출합니다.
        }
    }
    
    // MARK: - Private Methods
    private func setupAppearance() { // 앱의 전반적인 UI 설정을 하는 메서드입니다.
        // 앱 전체적인 UI 설정
        if #available(iOS 15.0, *) { // iOS 15.0 이상에서만 실행되는 코드입니다.
            let appearance = UINavigationBarAppearance() // 네비게이션 바의 외관을 설정하는 객체를 생성합니다.
            appearance.configureWithOpaqueBackground() // 불투명한 배경으로 설정합니다.
            UINavigationBar.appearance().standardAppearance = appearance // 기본 상태의 외관을 설정합니다.
            UINavigationBar.appearance().scrollEdgeAppearance = appearance // 스크롤 시의 외관을 설정합니다.
        }
    }
    
    private func handleCoreDataError(_ error: NSError) { // CoreData 관련 에러를 처리하는 메서드입니다.
        // 에러 로깅 및 사용자에게 알림
        print("CoreData Error: \(error.localizedDescription)") // 에러 메시지를 콘솔에 출력합니다.
        // TODO: 적절한 에러 처리 로직 구현
    }
}

