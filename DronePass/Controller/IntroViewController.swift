//
//  IntroViewController.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 앱 첫 실행 시 소개 화면을 보여주는 뷰 컨트롤러
// 연관기능: 앱 소개, 버전 정보, 메인 화면 진입
    
import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
    
class IntroViewController: UIViewController { // 앱 소개 화면을 담당하는 뷰 컨트롤러입니다.
    // MARK: - IBOutlets
    @IBOutlet private weak var descriptionLabel: UILabel! // 앱 설명을 표시하는 레이블입니다.
    @IBOutlet private weak var versionLabel: UILabel! // 앱 버전 정보를 표시하는 레이블입니다.
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard // 사용자 기본 설정을 저장하는 객체입니다.
    private let hasSeenIntroKey = "hasSeenIntro" // 인트로 화면을 본 적이 있는지 저장하는 키입니다.
    
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
    private func setupUI() { // UI를 설정하는 메서드입니다.
        print("📱 IntroViewController - setupUI")
        descriptionLabel.text = AppInfo.Description.intro // 앱 설명 텍스트 설정
        versionLabel.text = AppInfo.Version.current // 앱 버전 텍스트 설정
    }
    
    // MARK: - IBActions
    @IBAction private func didTapStartButton(_ sender: UIButton) { // 시작 버튼을 눌렀을 때 호출되는 메서드입니다.
        print("📱 IntroViewController - didTapStartButton")
        userDefaults.set(true, forKey: hasSeenIntroKey) // 인트로를 봤음을 저장
        moveToMain(animated: true) // 메인 화면으로 이동
    }
    
    // MARK: - Navigation
    private func moveToMain(animated: Bool) { // 메인 탭바 컨트롤러로 이동하는 메서드입니다.
        print("📱 IntroViewController - moveToMain")
        guard let tabBarVC = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") else {
            print("❌ Error: MainTabBarController not found in storyboard")
            return
        }
        tabBarVC.modalPresentationStyle = .fullScreen // 전체 화면으로 표시
        present(tabBarVC, animated: animated) // 화면 전환
        }
}
