//
//  PlaceShape.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 도형 데이터 모델
// 연관기능: 지도, 저장, 설정에서 공통 사용

import UIKit

public enum ShapeType: String, Codable {
    case circle, rectangle, polygon, polyline
}

public struct PlaceShape: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var shapeType: ShapeType
    public var baseCoordinate: Coordinate

    // circle 전용
    public var radius: Double?

    // rectangle 전용
    public var secondCoordinate: Coordinate?

    // polygon 전용
    public var polygonCoordinates: [Coordinate]?

    // polyline 전용
    public var polylineCoordinates: [Coordinate]?

    // 공통
    public var memo: String?
    public var expireDate: Date?
    public let createdAt: Date

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
        expireDate: Date? = nil,
        createdAt: Date = Date()
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
    }
}
