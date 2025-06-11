//
//  SceneDelegate.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

import UIKit // UIKit 프레임워크를 가져옵니다. (iOS 앱의 기본 UI 컴포넌트들을 사용하기 위함)
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate { // SceneDelegate 클래스를 정의합니다. UIResponder와 UIWindowSceneDelegate 프로토콜을 준수합니다.

    var window: UIWindow? // 앱의 메인 윈도우를 저장하는 프로퍼티입니다.


//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) { // Scene이 생성될 때 호출되는 메서드입니다.
//        // 이 메서드는 UIWindow를 Scene에 연결하고 설정하는 데 사용됩니다.
//        // Storyboard를 사용하는 경우, window 프로퍼티는 자동으로 초기화되고 Scene에 연결됩니다.
//        // 이 델리게이트는 연결되는 Scene이나 Session이 새로운 것임을 의미하지 않습니다.
//        guard let _ = (scene as? UIWindowScene) else { return } // Scene이 UIWindowScene 타입인지 확인합니다.
//    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: MainTabView()) // MainTabView로 변경!
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) { // Scene이 시스템에 의해 해제될 때 호출되는 메서드입니다.
        // Scene이 백그라운드로 전환되거나 세션이 삭제될 때 호출됩니다.
        // Scene과 관련된 리소스를 해제하고, 다음에 Scene이 연결될 때 다시 생성할 수 있도록 합니다.
        // Scene은 나중에 다시 연결될 수 있습니다.
    }

    func sceneDidBecomeActive(_ scene: UIScene) { // Scene이 비활성 상태에서 활성 상태로 전환될 때 호출되는 메서드입니다.
        // Scene이 비활성 상태였을 때 일시 중지되었거나 시작되지 않은 작업을 다시 시작하는 데 사용합니다.
    }

    func sceneWillResignActive(_ scene: UIScene) { // Scene이 활성 상태에서 비활성 상태로 전환될 때 호출되는 메서드입니다.
        // 일시적인 중단(예: 전화 수신)으로 인해 발생할 수 있습니다.
    }

    func sceneWillEnterForeground(_ scene: UIScene) { // Scene이 백그라운드에서 포그라운드로 전환될 때 호출되는 메서드입니다.
        // 백그라운드 진입 시 변경된 사항을 되돌리는 데 사용합니다.
    }

    func sceneDidEnterBackground(_ scene: UIScene) { // Scene이 포그라운드에서 백그라운드로 전환될 때 호출되는 메서드입니다.
        // 데이터를 저장하고, 공유 리소스를 해제하며, Scene의 현재 상태를 복원하기 위한 충분한 상태 정보를 저장하는 데 사용합니다.

        // 앱이 백그라운드로 전환될 때 CoreData의 변경사항을 저장합니다.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext() // AppDelegate의 saveContext() 메서드를 호출하여 CoreData 변경사항을 저장합니다.
    }
}

