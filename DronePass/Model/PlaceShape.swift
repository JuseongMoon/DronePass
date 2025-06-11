//
//  PlaceShape.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 도형 데이터 모델
// 연관기능: 지도, 저장, 설정에서 공통 사용

import Foundation // Foundation 프레임워크를 가져옵니다. (기본적인 데이터 타입과 기능을 사용하기 위함)
import CoreLocation // CoreLocation 프레임워크를 가져옵니다. (위치 관련 기능을 사용하기 위함)

public enum ShapeType: String, Codable { // 도형의 타입을 정의하는 열거형입니다. Codable 프로토콜을 준수하여 JSON 변환이 가능합니다.
    case circle // 원형 도형
    case rectangle // 사각형 도형
    case polygon // 다각형 도형
    case polyline // 선형 도형
    
    public var koreanName: String {
        switch self {
        case .circle:    return "원"
        case .rectangle: return "사각형"
        case .polygon:   return "다각형"
        case .polyline:  return "선"
        }
    }
}

// ✅ color: PaletteColor(컬러매니저 기반 enum)로 변경
public struct PlaceShape: Codable, Identifiable { // 지도에 표시될 도형의 데이터 모델입니다. Codable과 Identifiable 프로토콜을 준수합니다.
    public let id: UUID // 도형의 고유 식별자입니다.
    public var title: String // 도형의 제목입니다.
    public var shapeType: ShapeType // 도형의 타입입니다.
    public var baseCoordinate: Coordinate // 도형의 기준 좌표입니다.
    public var address: String? // 도형의 주소 정보입니다. (선택적)

    // 추가 도형 타입별 옵션
    public var radius: Double? // 원형 도형의 반경입니다. (선택적)
    public var secondCoordinate: Coordinate? // 사각형 도형의 두 번째 좌표입니다. (선택적)
    public var polygonCoordinates: [Coordinate]? // 다각형 도형의 좌표 배열입니다. (선택적)
    public var polylineCoordinates: [Coordinate]? // 선형 도형의 좌표 배열입니다. (선택적)

    public var memo: String? // 도형에 대한 메모입니다. (선택적)
    public var expireDate: Date? // 도형의 만료 날짜입니다.
    public let startedAt: Date // 도형이 생성된 날짜입니다.

    /// **팔레트 컬러 (색상 팔레트에서 고름)**
    public var color: String // 도형의 색상입니다. (16진수 색상 코드)

    public init( // 초기화 메서드입니다.
        id: UUID = UUID(), // UUID를 생성합니다. 기본값으로 새로운 UUID를 사용합니다.
        title: String, // 도형의 제목을 설정합니다.
        shapeType: ShapeType = .circle, // 도형의 타입을 설정합니다. 기본값은 원형입니다.
        baseCoordinate: Coordinate, // 도형의 기준 좌표를 설정합니다.
        radius: Double? = nil, // 원형 도형의 반경을 설정합니다. (선택적)
        secondCoordinate: Coordinate? = nil, // 사각형 도형의 두 번째 좌표를 설정합니다. (선택적)
        polygonCoordinates: [Coordinate]? = nil, // 다각형 도형의 좌표 배열을 설정합니다. (선택적)
        polylineCoordinates: [Coordinate]? = nil, // 선형 도형의 좌표 배열을 설정합니다. (선택적)
        memo: String? = nil, // 도형에 대한 메모를 설정합니다. (선택적)
        address: String? = nil, // 도형의 주소를 설정합니다. (선택적)
        expireDate: Date?, // 도형의 만료 날짜를 설정합니다. (선택적)
        startedAt: Date = Date(), // 도형의 생성 날짜를 설정합니다. 기본값은 현재 시간입니다.
        color: String = "#007AFF" // 도형의 색상을 설정합니다. 기본값은 파란색입니다.
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
        self.address = address
        self.expireDate = expireDate
        self.startedAt = startedAt
        self.color = color
    }
}

// MARK: - CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable { // CoreLocation의 CLLocationCoordinate2D를 Codable로 확장합니다.
    enum CodingKeys: String, CodingKey { // JSON 인코딩/디코딩에 사용할 키를 정의합니다.
        case latitude // 위도
        case longitude // 경도
    }
    
    public init(from decoder: Decoder) throws { // JSON에서 객체로 변환하는 초기화 메서드입니다.
        let container = try decoder.container(keyedBy: CodingKeys.self) // 디코딩 컨테이너를 생성합니다.
        let latitude = try container.decode(Double.self, forKey: .latitude) // 위도를 디코딩합니다.
        let longitude = try container.decode(Double.self, forKey: .longitude) // 경도를 디코딩합니다.
        self.init(latitude: latitude, longitude: longitude) // 좌표 객체를 생성합니다.
    }
    
    public func encode(to encoder: Encoder) throws { // 객체를 JSON으로 변환하는 메서드입니다.
        var container = encoder.container(keyedBy: CodingKeys.self) // 인코딩 컨테이너를 생성합니다.
        try container.encode(latitude, forKey: .latitude) // 위도를 인코딩합니다.
        try container.encode(longitude, forKey: .longitude) // 경도를 인코딩합니다.
    }
}
