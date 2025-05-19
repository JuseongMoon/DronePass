//
//  TestShape.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//
import UIKit

struct TestShape {
    // 각 원의 정보
    static let circle01 = PlaceShape(
        id: UUID(),
        title: "Circle 01",
        shapeType: .circle,
        baseCoordinate: Coordinate(latitude: 37.5666102, longitude: 126.9783881),
        radius: 400,
        memo: "Circle 01",
        expireDate: nil,
        createdAt: Date(),
        color: PaletteColor.red.rawValue      // <- enum → String(HEX)
    )

    static let circle02 = PlaceShape(
        id: UUID(),
        title: "Circle 02",
        shapeType: .circle,
        baseCoordinate: Coordinate(latitude: 37.565000, longitude: 126.979000),
        radius: 300,
        memo: "Circle 02",
        expireDate: nil,
        createdAt: Date(),
        color: PaletteColor.red.rawValue   // <- enum → String(HEX)
    )

    static let circle03 = PlaceShape(
        id: UUID(),
        title: "Circle 03",
        shapeType: .circle,
        baseCoordinate: Coordinate(latitude: 37.567000, longitude: 126.975000),
        radius: 500,
        memo: "Circle 03",
        expireDate: nil,
        createdAt: Date(),
        color: PaletteColor.red.rawValue    // <- enum → String(HEX)
    )

    static let circle04 = PlaceShape(
        id: UUID(),
        title: "Circle 04",
        shapeType: .circle,
        baseCoordinate: Coordinate(latitude: 37.570000, longitude: 126.973000),
        radius: 450,
        memo: "Circle 04",
        expireDate: nil,
        createdAt: Date(),
        color: PaletteColor.red.rawValue   // <- enum → String(HEX)
    )

    /// 전체 배열
    static let all: [PlaceShape] = [circle01, circle02, circle03, circle04]

    /// 원하는 원만 뽑아서 배열로 반환 (예: 1번, 3번)
    static func selectedCircles(_ circles: [PlaceShape]) -> [PlaceShape] {
        return circles
    }
}
