//
//  MainTabBarController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 앱의 메인 탭바 컨트롤러 (지도, 저장, 설정 탭 관리)
// 연관기능: 탭 전환, 바텀시트 오버레이, 탭 아이콘 상태 관리

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)

class MainTabBarController: UITabBarController, UITabBarControllerDelegate { // 메인 탭바 컨트롤러 클래스입니다.
    // MARK: - Properties
    let mapTabIndex     = 0 // 지도 탭 인덱스
    let savedTabIndex   = 1 // 저장 탭 인덱스
    let settingTabIndex = 2 // 설정 탭 인덱스
    
    private var currentBottomSheet: SavedBottomSheetViewController? // 현재 표시 중인 바텀시트 뷰 컨트롤러
    private var lastSelectedIndex = 0 // 마지막으로 선택된 탭 인덱스
    private var isSavedSheetPresented = false // 저장 바텀시트가 표시 중인지 여부

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 MainTabBarController - viewDidLoad")
        delegate = self // 탭바 컨트롤러 델리게이트 설정
        definesPresentationContext = true // 모달 표시 시 컨텍스트 유지
        setupTabBar() // 탭바 초기 설정
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 MainTabBarController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 MainTabBarController - viewDidAppear")
    }
    
    // MARK: - TabBar Setup Methods
    private func setupTabBar() { // 탭바 UI를 초기화하는 메서드입니다.
        print("📱 MainTabBarController - setupTabBar")
        tabBar.tintColor = .black // 선택된 아이템 색상
        tabBar.unselectedItemTintColor = .black // 선택되지 않은 아이템 색상
        
        // 초기 선택 탭 설정
        selectedIndex = mapTabIndex
        updateTabBarIcons() // 아이콘 상태 업데이트
    }
    
    // MARK: - Tab Bar Methods
    private func updateTabBarIcons() { // 탭바 아이콘을 상태에 따라 업데이트합니다.
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
                         shouldSelect viewController: UIViewController) -> Bool { // 탭이 선택되기 전에 호출되는 델리게이트 메서드입니다.
        print("📱 MainTabBarController - shouldSelect: \(type(of: viewController))")
        
        // 저장 탭 클릭 시
        if viewController is SavedViewController {
            if isSavedSheetPresented {
                print("📱 MainTabBarController - 닫기 시도")
                removeBottomSheet() // 바텀시트 닫기
                selectedIndex = mapTabIndex
                return false
            } else {
                print("📱 MainTabBarController - 열기 시도")
                presentBottomSheet() // 바텀시트 열기
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
                         didSelect viewController: UIViewController) { // 탭이 선택된 후 호출되는 델리게이트 메서드입니다.
        print("📱 MainTabBarController - didSelect: \(type(of: viewController))")
        updateTabBarIcons()
    }
    
    // MARK: - Bottom Sheet Methods
    private func presentBottomSheet() { // 저장 바텀시트를 표시하는 메서드입니다.
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
        
        // 바텀시트 뷰 설정
        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetVC.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            sheetVC.view.topAnchor.constraint(equalTo: tabBar.superview!.topAnchor)
        ])
        
        // 상태 관리
        currentBottomSheet = sheetVC
        isSavedSheetPresented = true
        updateTabBarIcons()
        print("📱 MainTabBarController - presentBottomSheet 완료")
    }
    
    func removeBottomSheet() { // 저장 바텀시트를 닫는 메서드입니다.
        print("📱 MainTabBarController - removeBottomSheet 시작")
        // 하이라이트 해제 Notification 전송
        NotificationCenter.default.post(name: .clearShapeHighlight, object: nil)
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

