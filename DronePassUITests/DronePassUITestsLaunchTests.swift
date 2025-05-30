//
//  DronePassUITestsLaunchTests.swift
//  DronePassUITests
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 앱 실행 화면 테스트를 위한 테스트 클래스
// 연관기능: 앱 실행 화면 검증, 스크린샷 캡처

import XCTest // XCTest 프레임워크를 가져옵니다. (UI 테스트를 작성하기 위한 기본 프레임워크)

final class DronePassUITestsLaunchTests: XCTestCase { // 앱 실행 화면 테스트를 위한 테스트 클래스입니다. XCTestCase를 상속받아 테스트 기능을 사용합니다.

    override class var runsForEachTargetApplicationUIConfiguration: Bool { // 각 UI 설정마다 테스트를 반복 실행할지 여부를 설정하는 클래스 프로퍼티입니다.
        true // true로 설정하면 각 UI 환경(예: 다크 모드, 라이트 모드)에서 테스트가 실행됩니다.
    }

    override func setUpWithError() throws { // 각 테스트가 실행되기 전에 호출되는 설정 메서드입니다.
        continueAfterFailure = false // 테스트 실패 시 다음 테스트를 계속할지 여부를 설정합니다. false면 실패 시 바로 멈춥니다.
    }

    @MainActor // 이 함수는 메인 스레드에서 실행되어야 함을 나타내는 어트리뷰트입니다.
    func testLaunch() throws { // 앱 실행 화면을 테스트하는 메서드입니다.
        let app = XCUIApplication() // XCUIApplication 객체를 생성합니다. (앱을 제어할 수 있는 객체)
        app.launch() // 앱을 실행합니다.

        // 앱 실행 후 스크린샷을 찍거나, 로그인 등 추가 동작을 여기에 작성할 수 있습니다.

        let attachment = XCTAttachment(screenshot: app.screenshot()) // 현재 앱 화면을 스크린샷으로 저장합니다.
        attachment.name = "Launch Screen" // 첨부파일의 이름을 "Launch Screen"으로 지정합니다.
        attachment.lifetime = .keepAlways // 첨부파일을 항상 보관하도록 설정합니다.
        add(attachment) // 첨부파일을 테스트 결과에 추가합니다.
    }
}
