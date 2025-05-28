//
//  ColorManager.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

// 역할: 색상 팔레트 및 HEX-UIColor 변환 유틸리티
// 연관기능: 도형 색상 선택, 팔레트 관리, HEX 변환
import UIKit

// HEX로 UIColor 생성 (확장)
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

public enum PaletteColor: String, CaseIterable, Codable {
    case red = "#FF3B30"
    case orange = "#FF9500"
    case yellow = "#FFCC00"
    case green = "#34C759"
    case teal = "#5AC8FA"
    case blue = "#007AFF"
    case indigo = "#5856D6"
    case purple = "#AF52DE"
    case pink = "#FF2D55"
    case gray = "#8E8E93"
    
    var uiColor: UIColor { UIColor(hex: self.rawValue) ?? .systemBlue }
    var hex: String { self.rawValue }
}

final class ColorManager {
    static let shared = ColorManager()
    private let defaultColorKey = "defaultShapeColor"
    
    // 항상 첫 번째 도형의 색상을 변수로 보유

    private(set) var firstShapeColor: PaletteColor = .blue

    
    private init() {
        if UserDefaults.standard.string(forKey: defaultColorKey) == nil {
            UserDefaults.standard.set(PaletteColor.blue.rawValue, forKey: defaultColorKey)
        }
        // 앱 시작 시 도형이 있으면 첫 번째 색상을 동기화
        syncFirstShapeColor()
        // 도형이 바뀔 때마다 색상을 갱신하도록 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(syncFirstShapeColor), name: .shapesDidUpdate, object: nil)

    }
    
    var defaultColor: PaletteColor {
        get {
            if let colorString = UserDefaults.standard.string(forKey: defaultColorKey),
               let color = PaletteColor.allCases.first(where: { $0.rawValue == colorString }) {
                return color
            }
            return .blue
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultColorKey)
        }
    }
    
    static var palette: [PaletteColor] {
        PaletteColor.allCases
    }
    
    /// 첫 번째 도형의 색상값을 동기화하는 함수 (옵저버에서도 호출)
    @objc func syncFirstShapeColor() {
        if let firstShape = PlaceShapeStore.shared.shapes.first,
           let color = PaletteColor.allCases.first(where: { $0.hex.lowercased() == firstShape.color.lowercased() }) {
            firstShapeColor = color
        } else {
            firstShapeColor = .blue
        }
    }
}
