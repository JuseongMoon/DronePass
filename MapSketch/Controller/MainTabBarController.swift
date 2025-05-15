//
//  MainTabBarController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private let mapTabIndex     = 0
    private let savedTabIndex   = 1
    private let settingTabIndex = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        definesPresentationContext = true
    }

    

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        print("🔔 shouldSelect:", type(of: viewController))

        // 1) “저장” 탭 누름 감지
        if viewController is SavedViewController {
            // 탭 전환 없이 시트만 띄움
            presentSavedSheet()
            return false
        }
        // 2) “설정” 탭 이전에 올라온 시트 제거
        if viewController is SettingViewController {
            children
              .filter { $0 is SavedBottomSheetViewController }
              .forEach {
                  $0.willMove(toParent: nil)
                  $0.view.removeFromSuperview()
                  $0.removeFromParent()
              }
        }
        // 그 외 탭(지도/설정 등)은 평소대로 전환
        return true
    }

    private func presentSavedSheet() {
        // 기존 시트 제거
        children
          .filter { $0 is SavedBottomSheetViewController }
          .forEach {
              $0.willMove(toParent: nil)
              $0.view.removeFromSuperview()
              $0.removeFromParent()
          }

        // 새 시트 생성 & 붙이기
        guard let sheetVC = storyboard?
                .instantiateViewController(
                  withIdentifier: "SavedBottomSheetViewController"
                ) as? SavedBottomSheetViewController
        else { return }

        addChild(sheetVC)
        view.insertSubview(sheetVC.view, belowSubview: tabBar)
        sheetVC.didMove(toParent: self)

        // Auto Layout 제약
        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          sheetVC.view.topAnchor.constraint(equalTo: view.topAnchor),
          sheetVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 즉시 레이아웃 반영
        view.setNeedsLayout()
        view.layoutIfNeeded()
        print("📐 sheetVC.view 제약 완료, frame:", sheetVC.view.frame)

    }
}
