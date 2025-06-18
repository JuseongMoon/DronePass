//
////
////  SampleShapeLoader.swift
////  DronePass
////
////  Created by 문주성 on 5/19/25.
////
//
//
//import Foundation
//import CoreLocation
//
//// MARK: - Sample Data Loader
//enum SampleShapeLoader {
//    static func loadSampleShapes() -> [PlaceShape] {
//        return [
//            PlaceShape(
//                title: "서울시청",
//                shapeType: .circle,
//                baseCoordinate: Coordinate(latitude: 37.5665, longitude: 126.9780),
//                radius: 500,
//                memo: "서울시청 주변 비행 금지 구역",
//                address: "서울특별시 중구 태평로1가 31",
//                expireDate: Date().addingTimeInterval(86400 * 7),
//                color: "#FF0000"
//            ),
//            PlaceShape(
//                title: "경복궁",
//                shapeType: .polygon,
//                baseCoordinate: Coordinate(latitude: 37.5796, longitude: 126.9770),
//                polygonCoordinates: [
//                    Coordinate(latitude: 37.5796, longitude: 126.9770),
//                    Coordinate(latitude: 37.5796, longitude: 126.9780),
//                    Coordinate(latitude: 37.5786, longitude: 126.9780),
//                    Coordinate(latitude: 37.5786, longitude: 126.9770)
//                ],
//                memo: "경복궁 보존 구역",
//                address: "서울특별시 종로구 사직로 161",
//                expireDate: Date().addingTimeInterval(86400 * 30),
//                color: "#00FF00"
//            )
//        ]
//    }
//} 
