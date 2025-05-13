//
//  IntroViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class IntroViewController: UIViewController {
    
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = AppInfo.description
        versionLabel.text = AppInfo.version
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 저장속성에서 임시 그룹 생성
        if ShapeGroupStore.shared.groups.isEmpty {
            let sampleGroup = ShapeGroup(
                name: "예시 그룹",
                colorHex: "#007AFF",
                alpha: 0.4,
                shapes: []
            )
            ShapeGroupStore.shared.addGroup(sampleGroup)
        }
        
//        
//        if UserDefaults.standard.bool(forKey: "hasSeenIntro") {
//            // 이미 본 적이 있다면 바로 메인으로 이동
//            moveToMain(animated: false)
//        }
    }
    
    @IBAction func didTapStartButton(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "hasSeenIntro")
        moveToMain(animated: true)
    }
    
    // 중복 제거: 화면 전환 메서드 분리
    private func moveToMain(animated: Bool) {
        if let tabBarVC = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") {
            tabBarVC.modalPresentationStyle = .fullScreen
            present(tabBarVC, animated: animated)
        }
    }
    


    
}
