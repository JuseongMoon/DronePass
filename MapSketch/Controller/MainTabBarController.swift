//
//  MainTabBarController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    let mapTabIndex     = 0
    let savedTabIndex   = 1
    let settingTabIndex = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        definesPresentationContext = true
        resetAllTabIcons()
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .black
    }

    func resetAllTabIcons() {
        if let tabBarItems = tabBar.items {
            tabBarItems[mapTabIndex].image = UIImage(named: "tab_map_inactive")
            tabBarItems[savedTabIndex].image = UIImage(named: "tab_favorite_inactive")
            tabBarItems[settingTabIndex].image = UIImage(named: "tab_setting_inactive")
        }
    }

    func highlightTabIcon(at index: Int) {
        resetAllTabIcons()
        if let tabBarItems = tabBar.items {
            switch index {
            case mapTabIndex:
                tabBarItems[mapTabIndex].image = UIImage(named: "tab_map_active")
            case savedTabIndex:
                tabBarItems[savedTabIndex].image = UIImage(named: "tab_favorite_active")
            case settingTabIndex:
                tabBarItems[settingTabIndex].image = UIImage(named: "tab_setting_active")
            default: break
            }
        }
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        // 1. 기존 오버레이 제거
        children
            .filter { $0 is SavedBottomSheetViewController }
            .forEach {
                $0.willMove(toParent: nil)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }
        // 2. 저장 탭 클릭 시
        if viewController is SavedViewController {
            highlightTabIcon(at: savedTabIndex)
            presentSavedSheet()
            // 지도 탭에 selectedIndex를 고정
            selectedIndex = mapTabIndex // or 적절한 기본값 (일부러 저장탭이 선택되지 않게)
            return false
        }
        // 3. 지도/설정 탭 클릭 시 하이라이트 동기화
        if viewController is MapViewController {
            highlightTabIcon(at: mapTabIndex)
        }
        if viewController is SettingViewController {
            highlightTabIcon(at: settingTabIndex)
        }
        return true
    }
    
    

    private func presentSavedSheet() {
        
        // 기존에 붙은 시트 모두 제거
        children
            .filter { $0 is SavedBottomSheetViewController }
            .forEach {
                $0.willMove(toParent: nil)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }

        guard let sheetVC = storyboard?
                .instantiateViewController(withIdentifier: "SavedBottomSheetViewController")
                as? SavedBottomSheetViewController
        else { return }

        addChild(sheetVC)
        view.insertSubview(sheetVC.view, belowSubview: tabBar)
        sheetVC.didMove(toParent: self)

        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            sheetVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
