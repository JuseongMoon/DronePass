//
//  AppInfo.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// AppInfo.swift
import Foundation // Foundation 프레임워크를 가져옵니다. (기본적인 데이터 타입과 기능을 사용하기 위함)

/// 앱 전역에서 참조할 정보를 관리하는 구조체
struct AppInfo { // AppInfo 구조체를 정의합니다. 앱 전체에서 사용되는 정보들을 관리합니다.
    // MARK: - Constants
    private enum Constants { // 상수들을 정의하는 열거형입니다.
        static let bundleVersionKey = "CFBundleShortVersionString" // 앱 버전 정보를 가져오기 위한 키입니다.
        static let buildNumberKey = "CFBundleVersion" // 빌드 번호를 가져오기 위한 키입니다.
    }
    
    // MARK: - App Description
    struct Description { // 앱 설명과 관련된 정보를 담는 구조체입니다.
        static let intro: String = """
  Flight Plans는 
  드론 비행 허가지를 시각화하고
  반경 기반 도형을 지도 위에 생성·저장하는
  개인용 지도 메모 어플입니다.
  """ // 앱의 소개 문구입니다.

        static let features: [String] = [ // 앱의 주요 기능들을 배열로 정의합니다.
            "드론 비행 허가지 시각화", // 드론 비행 허가 구역을 지도에 표시하는 기능
            "반경 기반 도형 생성", // 특정 반경을 가진 도형을 생성하는 기능
            "지도 메모 저장", // 지도에 메모를 저장하는 기능
            "개인용 데이터 관리" // 사용자의 데이터를 관리하는 기능
        ]
        
        static let contact: String = """
        Science Fiction Inc.
        hisnote@me.com
        """
    }
    
    // MARK: - Version Info
    struct Version { // 앱 버전 정보를 관리하는 구조체입니다.
        static var current: String { // 현재 앱의 전체 버전 정보를 반환하는 계산 프로퍼티입니다.
            let info = Bundle.main.infoDictionary // 앱의 Info.plist 정보를 가져옵니다.
            let short = info?[Constants.bundleVersionKey] as? String ?? "1.0" // 앱 버전을 가져옵니다. 없으면 "1.0"을 기본값으로 사용합니다.
            let build = info?[Constants.buildNumberKey] as? String ?? "1" // 빌드 번호를 가져옵니다. 없으면 "1"을 기본값으로 사용합니다.
            return "\(short) (\(build))" // "버전 (빌드번호)" 형식으로 반환합니다.
        }
        
        static var shortVersion: String { // 앱의 버전만 반환하는 계산 프로퍼티입니다.
            Bundle.main.infoDictionary?[Constants.bundleVersionKey] as? String ?? "1.0" // Info.plist에서 버전 정보를 가져옵니다.
        }
        
        static var buildNumber: String { // 앱의 빌드 번호만 반환하는 계산 프로퍼티입니다.
            Bundle.main.infoDictionary?[Constants.buildNumberKey] as? String ?? "1" // Info.plist에서 빌드 번호를 가져옵니다.
        }
    }
    
    // MARK: - App Settings
    struct Settings { // 앱의 기본 설정값들을 관리하는 구조체입니다.
        static let defaultMapZoomLevel: Double = 13.0 // 지도의 기본 줌 레벨입니다.
        static let defaultRadius: Double = 100.0 // meters // 기본 반경 값입니다. (미터 단위)
        static let maxRadius: Double = 5000.0 // meters // 최대 반경 값입니다. (미터 단위)
    }
}
