//
//  SavedViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
// SavedViewController.swift
// MapSketch

import UIKit

class SavedViewController: UIViewController {
    
    /// 버튼이나 탭바 Delegate 에서 호출하세요
    @IBAction func didTapOpenSheet(_ sender: Any) {
        guard let sheetVC = storyboard?
                .instantiateViewController(
                  withIdentifier: "SavedBottomSheetViewController"
                )
                as? SavedBottomSheetViewController
        else { return }

        // iOS15+ UISheetPresentationController 설정
        if let pc = sheetVC.sheetPresentationController {
            pc.detents = [.medium(), .large()]       // 반 높이 ↔ 전체
            pc.prefersGrabberVisible = true          // 그랩바 표시
            pc.preferredCornerRadius = 16            // 모서리 둥글게
        }
        sheetVC.modalPresentationStyle = .pageSheet
        present(sheetVC, animated: true)
    }
}
