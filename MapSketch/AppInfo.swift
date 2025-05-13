//
//  AppInfo.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// AppInfo.swift
import Foundation

/// 앱 전역에서 참조할 정보(설명, 버전 등)
struct AppInfo {
  /// Intro에 표시할 설명 텍스트
  static let description: String = """
  MapSketch는 드론 비행 허가지를 시각화하고,
  반경 기반 도형을 지도 위에 생성·저장하는
  개인용 지도 메모 플랫폼입니다.
  """

  /// Info.plist에 설정된 앱 버전과 빌드 넘버를 읽어서 리턴
  static var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = info?["CFBundleVersion"] as? String ?? "1"
    return "\(short) (\(build))"
  }
}
