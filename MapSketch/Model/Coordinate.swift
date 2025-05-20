//
//  Coordinate.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: GPS 좌표값


import Foundation
import CoreLocation
import NMapsMap

/// GPS 좌표값을 저장하는 모델
public struct Coordinate: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    public func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude,
                                      longitude: longitude)
    }

    /// NMGLatLng으로 변환 (네이버 지도 API용)
    public func toNMGLatLng() -> NMGLatLng {
        return NMGLatLng(lat: latitude, lng: longitude)
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
