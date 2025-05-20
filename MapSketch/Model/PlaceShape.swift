//
//  PlaceShape.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 도형 데이터 모델
// 연관기능: 지도, 저장, 설정에서 공통 사용


import Foundation
import CoreLocation

public enum ShapeType: String, Codable {
    case circle, rectangle, polygon, polyline
}

// ✅ color: PaletteColor(컬러매니저 기반 enum)로 변경
public struct PlaceShape: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var shapeType: ShapeType
    public var baseCoordinate: Coordinate
    public var address: String?

    // 추가 도형 타입별 옵션
    public var radius: Double?
    public var secondCoordinate: Coordinate? // 사각형 등
    public var polygonCoordinates: [Coordinate]?
    public var polylineCoordinates: [Coordinate]?

    public var memo: String?
    public var expireDate: Date?
    public let createdAt: Date

    /// **팔레트 컬러 (색상 팔레트에서 고름)**
    public var color: String

    public init(
        id: UUID = UUID(),
        title: String,
        shapeType: ShapeType = .circle,
        baseCoordinate: Coordinate,
        radius: Double? = nil,
        secondCoordinate: Coordinate? = nil,
        polygonCoordinates: [Coordinate]? = nil,
        polylineCoordinates: [Coordinate]? = nil,
        memo: String? = nil,
        expireDate: Date? = nil,         // ✅ color 앞에 배치
        createdAt: Date = Date(),
        color: String = "#007AFF",     // ✅ 마지막(혹은 뒤쪽)에 배치

    ) {
        self.id = id
        self.title = title
        self.shapeType = shapeType
        self.baseCoordinate = baseCoordinate
        self.radius = radius
        self.secondCoordinate = secondCoordinate
        self.polygonCoordinates = polygonCoordinates
        self.polylineCoordinates = polylineCoordinates
        self.memo = memo
        self.expireDate = expireDate
        self.createdAt = createdAt
        self.color = color

    }
}

// MARK: - CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
