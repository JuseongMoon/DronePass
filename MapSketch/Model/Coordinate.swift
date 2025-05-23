//
//  Coordinate.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: GPS 좌표값을 관리하는 모델
// 연관기능: 지도 표시, 위치 검색, 도형 생성

import Foundation // Foundation 프레임워크를 가져옵니다. (기본적인 데이터 타입과 기능을 사용하기 위함)
import CoreLocation // CoreLocation 프레임워크를 가져옵니다. (위치 관련 기능을 사용하기 위함)
import NMapsMap // 네이버 지도 SDK를 가져옵니다. (지도 표시 기능을 사용하기 위함)

/// GPS 좌표값을 저장하는 모델
public struct Coordinate: Codable, Equatable { // GPS 좌표를 나타내는 구조체입니다. Codable과 Equatable 프로토콜을 준수합니다.
    public let latitude: Double // 위도 값입니다.
    public let longitude: Double // 경도 값입니다.

    public init(latitude: Double, longitude: Double) { // 위도와 경도를 직접 받아 초기화하는 생성자입니다.
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ coordinate: CLLocationCoordinate2D) { // CoreLocation의 좌표 객체로부터 초기화하는 생성자입니다.
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    public func toCLLocationCoordinate2D() -> CLLocationCoordinate2D { // CoreLocation의 좌표 객체로 변환하는 메서드입니다.
        return CLLocationCoordinate2D(latitude: latitude,
                                      longitude: longitude)
    }

    /// NMGLatLng으로 변환 (네이버 지도 API용)
    public func toNMGLatLng() -> NMGLatLng { // 네이버 지도의 좌표 객체로 변환하는 메서드입니다.
        return NMGLatLng(lat: latitude, lng: longitude)
    }

    var clCoordinate: CLLocationCoordinate2D { // CoreLocation 좌표 객체를 반환하는 계산 프로퍼티입니다.
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
