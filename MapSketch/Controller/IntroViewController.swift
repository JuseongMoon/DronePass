//
//  IntroViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class IntroViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let hasSeenIntroKey = "hasSeenIntro"
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 IntroViewController - viewDidLoad")
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 IntroViewController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 IntroViewController - viewDidAppear")
        // 자동 이동 제거
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        print("📱 IntroViewController - setupUI")
        descriptionLabel.text = AppInfo.Description.intro
        versionLabel.text = AppInfo.Version.current
    }
    
    // MARK: - IBActions
    @IBAction private func didTapStartButton(_ sender: UIButton) {
        print("📱 IntroViewController - didTapStartButton")
        userDefaults.set(true, forKey: hasSeenIntroKey)
        moveToMain(animated: true)
    }
    
    // MARK: - Navigation
    private func moveToMain(animated: Bool) {
        print("📱 IntroViewController - moveToMain")
        guard let tabBarVC = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") else {
            print("❌ Error: MainTabBarController not found in storyboard")
            return
        }
        
        tabBarVC.modalPresentationStyle = .fullScreen
        present(tabBarVC, animated: animated)
    }
}
