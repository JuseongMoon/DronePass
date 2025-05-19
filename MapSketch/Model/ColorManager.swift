//
//  ColorManager.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

import UIKit

/// HEX로 UIColor 생성 (확장)
extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

/// 팔레트용 컬러 모델
public enum PaletteColor: String, CaseIterable, Codable {
    // 원하는 색상을 여기에 추가 (10개 예시)
    case red        = "#FF3B30"
    case orange     = "#FF9500"
    case yellow     = "#FFD700"
    case green      = "#34C759"
    case teal       = "#30CFCF"
    case blue       = "#007AFF"
    case indigo     = "#5856D6"
    case purple     = "#AF52DE"
    case pink       = "#FF2D55"
    case gray       = "#8E8E93"
    
    /// UIColor 변환
    var uiColor: UIColor { UIColor(hex: self.rawValue) }
    
    /// HEX String
    var hex: String { self.rawValue }
}

/// 팔레트 전체 배열 (색상 선택시 활용)
struct ColorManager {
    static let palette: [PaletteColor] = PaletteColor.allCases

    /// 인덱스로 팔레트 색상 반환
    static func color(at index: Int) -> PaletteColor {
        let idx = index % palette.count
        return palette[idx]
    }

    /// HEX → UIColor 변환 직접 사용 예시
    static func uiColor(forHex hex: String) -> UIColor {
        return UIColor(hex: hex)
    }
    
    /// 팔레트 HEX String만 배열로 받고 싶을 때
    static var hexValues: [String] { palette.map { $0.hex } }
}
