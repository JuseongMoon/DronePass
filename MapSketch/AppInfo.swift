//
//  AppInfo.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// AppInfo.swift
import Foundation

/// 앱 전역에서 참조할 정보를 관리하는 구조체
struct AppInfo {
    // MARK: - Constants
    private enum Constants {
        static let bundleVersionKey = "CFBundleShortVersionString"
        static let buildNumberKey = "CFBundleVersion"
    }
    
    // MARK: - App Description
    struct Description {
        static let intro: String = """
        MapSketch는 드론 비행 허가지를 시각화하고,
        반경 기반 도형을 지도 위에 생성·저장하는
        개인용 지도 메모 플랫폼입니다.
        """
        
        static let features: [String] = [
            "드론 비행 허가지 시각화",
            "반경 기반 도형 생성",
            "지도 메모 저장",
            "개인용 데이터 관리"
        ]
    }
    
    // MARK: - Version Info
    struct Version {
        static var current: String {
            let info = Bundle.main.infoDictionary
            let short = info?[Constants.bundleVersionKey] as? String ?? "1.0"
            let build = info?[Constants.buildNumberKey] as? String ?? "1"
            return "\(short) (\(build))"
        }
        
        static var shortVersion: String {
            Bundle.main.infoDictionary?[Constants.bundleVersionKey] as? String ?? "1.0"
        }
        
        static var buildNumber: String {
            Bundle.main.infoDictionary?[Constants.buildNumberKey] as? String ?? "1"
        }
    }
    
    // MARK: - App Settings
    struct Settings {
        static let defaultMapZoomLevel: Double = 15.0
        static let defaultRadius: Double = 100.0 // meters
        static let maxRadius: Double = 5000.0 // meters
    }
}
