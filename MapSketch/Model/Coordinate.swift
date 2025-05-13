//
//  Coordinate.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: GPS 좌표값


import Foundation
import CoreLocation

/// GPS 좌표값을 저장하는 모델
public struct Coordinate: Codable {
    public let latitude: Double
    public let longitude: Double

    /// 위도/경도 직접 지정 초기화
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// CoreLocation 좌표로부터 초기화
    public init(from location: CLLocationCoordinate2D) {
        self.latitude = location.latitude
        self.longitude = location.longitude
    }

    /// CLLocationCoordinate2D로 변환
    public func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude,
                                      longitude: longitude)
    }
}
