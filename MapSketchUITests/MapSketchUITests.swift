//
//  MapSketchUITests.swift
//  MapSketchUITests
//
//  Created by 문주성 on 5/13/25.
//

// 역할: UI 테스트를 위한 테스트 클래스
// 연관기능: 앱의 UI 동작 검증, 성능 테스트

import XCTest // XCTest 프레임워크를 가져옵니다. (UI 테스트를 작성하기 위한 기본 프레임워크)

final class MapSketchUITests: XCTestCase { // UI 테스트를 위한 테스트 클래스입니다. XCTestCase를 상속받아 테스트 기능을 사용합니다.

    override func setUpWithError() throws { // 각 테스트가 실행되기 전에 호출되는 설정 메서드입니다.
        // 테스트 실행 전 준비 작업을 여기에 작성합니다.

        // 테스트 실패 시 다음 테스트를 계속할지 여부를 설정합니다. false면 실패 시 바로 멈춥니다.
        continueAfterFailure = false

        // 테스트 실행 전 초기 상태(예: 화면 방향 등)를 설정할 수 있습니다.
    }

    override func tearDownWithError() throws { // 각 테스트가 끝난 후 호출되는 정리 메서드입니다.
        // 테스트가 끝난 후 정리 작업을 여기에 작성합니다.
    }

    @MainActor // 이 함수는 메인 스레드에서 실행되어야 함을 나타내는 어트리뷰트입니다.
    func testExample() throws { // 실제 UI 테스트를 작성하는 예시 메서드입니다.
        // 테스트할 앱을 실행합니다.
        let app = XCUIApplication() // XCUIApplication 객체를 생성합니다. (앱을 제어할 수 있는 객체)
        app.launch() // 앱을 실행합니다.

        // XCTAssert 같은 함수를 사용해 테스트 결과를 확인할 수 있습니다.
    }

    @MainActor // 메인 스레드에서 실행되어야 함을 나타내는 어트리뷰트입니다.
    func testLaunchPerformance() throws { // 앱 실행 속도를 측정하는 테스트 메서드입니다.
        // 앱 실행 시간을 측정합니다.
        measure(metrics: [XCTApplicationLaunchMetric()]) { // XCTApplicationLaunchMetric을 사용해 앱 실행 속도를 측정합니다.
            XCUIApplication().launch() // 앱을 실행합니다.
        }
    }
}
