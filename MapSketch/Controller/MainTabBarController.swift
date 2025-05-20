//
//  MainTabBarController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    // MARK: - Properties
    let mapTabIndex     = 0
    let savedTabIndex   = 1
    let settingTabIndex = 2
    
    private var currentBottomSheet: SavedBottomSheetViewController?
    private var lastSelectedIndex = 0
    private var isSavedSheetPresented = false

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 MainTabBarController - viewDidLoad")
        delegate = self
        definesPresentationContext = true
        setupTabBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 MainTabBarController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 MainTabBarController - viewDidAppear")
    }
    
    // MARK: - Setup Methods
    private func setupTabBar() {
        print("📱 MainTabBarController - setupTabBar")
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .black
        
        // 초기 선택 탭 설정
        selectedIndex = mapTabIndex
        updateTabBarIcons()
    }
    
    // MARK: - Tab Bar Methods
    private func updateTabBarIcons() {
        print("📱 MainTabBarController - updateTabBarIcons")
        guard let items = tabBar.items else { return }
        
        // 모든 아이콘을 비활성화 상태로 설정
        items[mapTabIndex].image = UIImage(named: "tab_map_inactive")
        items[savedTabIndex].image = UIImage(named: "tab_favorite_inactive")
        items[settingTabIndex].image = UIImage(named: "tab_setting_inactive")
        
        // 현재 선택된 탭과 저장 시트 상태에 따라 아이콘 활성화
        if isSavedSheetPresented {
            items[savedTabIndex].image = UIImage(named: "tab_favorite_active")
        } else {
            switch selectedIndex {
            case mapTabIndex:
                items[mapTabIndex].image = UIImage(named: "tab_map_active")
            case savedTabIndex:
                items[savedTabIndex].image = UIImage(named: "tab_favorite_active")
            case settingTabIndex:
                items[settingTabIndex].image = UIImage(named: "tab_setting_active")
            default:
                break
            }
        }
    }

    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController,
                         shouldSelect viewController: UIViewController) -> Bool {
        print("📱 MainTabBarController - shouldSelect: \(type(of: viewController))")
        
        // 저장 탭 클릭 시
        if viewController is SavedViewController {
            if isSavedSheetPresented {
                print("📱 MainTabBarController - 닫기 시도")
                removeBottomSheet()
                selectedIndex = mapTabIndex
                return false
            } else {
                print("📱 MainTabBarController - 열기 시도")
                presentBottomSheet()
                selectedIndex = mapTabIndex
                return false
            }
        }
        
        // 다른 탭 클릭 시
        if isSavedSheetPresented {
            print("📱 MainTabBarController - 다른 탭 선택으로 시트 닫기")
            removeBottomSheet()
        }
        lastSelectedIndex = selectedIndex
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController,
                         didSelect viewController: UIViewController) {
        print("📱 MainTabBarController - didSelect: \(type(of: viewController))")
        updateTabBarIcons()
    }
    
    // MARK: - Bottom Sheet Methods
    private func presentBottomSheet() {
        print("📱 MainTabBarController - presentBottomSheet 시작")
        // 이미 표시된 바텀시트가 있다면 제거
        if let existingSheet = children.first(where: { $0 is SavedBottomSheetViewController }) {
            existingSheet.willMove(toParent: nil)
            existingSheet.view.removeFromSuperview()
            existingSheet.removeFromParent()
        }
        // 새로운 바텀시트 생성
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let sheetVC = storyboard.instantiateViewController(withIdentifier: "SavedBottomSheetViewController") as? SavedBottomSheetViewController else {
            print("📱 MainTabBarController - SavedBottomSheetViewController 생성 실패")
            return
        }
        print("📱 MainTabBarController - SavedBottomSheetViewController 생성 성공")
        // delegate 연결
        sheetVC.delegate = self
        // 바텀시트 추가
        addChild(sheetVC)
        view.addSubview(sheetVC.view)
        sheetVC.didMove(toParent: self)
        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetVC.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
        // 상태 관리
        currentBottomSheet = sheetVC
        isSavedSheetPresented = true
        updateTabBarIcons()
        print("📱 MainTabBarController - presentBottomSheet 완료")
    }
    
    func removeBottomSheet() {
        print("📱 MainTabBarController - removeBottomSheet 시작")
        currentBottomSheet?.willMove(toParent: nil)
        currentBottomSheet?.view.removeFromSuperview()
        currentBottomSheet?.removeFromParent()
        currentBottomSheet = nil
        isSavedSheetPresented = false
        updateTabBarIcons()
        print("📱 MainTabBarController - removeBottomSheet 완료")
    }
}

// MARK: - SavedBottomSheetDelegate
extension MainTabBarController: SavedBottomSheetDelegate {
    func savedBottomSheetDidDismiss() {
        removeBottomSheet()
    }
}

