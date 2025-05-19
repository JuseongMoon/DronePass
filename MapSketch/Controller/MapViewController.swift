//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.

// MARK: — MapViewController.swift


import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet public var naverMapView: NMFNaverMapView! // 스토리보드에 연결

    private let locationManager = CLLocationManager()
    private var hasCenteredOnUser = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // 현위치 버튼 표시
        naverMapView.showLocationButton = true


        // 카메라 초기 위치 설정 (서울 중심 예시)
        let position = NMFCameraPosition(NMGLatLng(lat: 37.575563, lng: 126.976793), zoom: 14)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))

        // 위치 권한 요청 및 업데이트
        locationManager.delegate = self
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }

        // 저장된 모든 도형 오버레이로 그리기
        for shape in PlaceShapeStore.shared.shapes {
            addOverlay(for: shape)
        }
        
        // 테스트용 원 오버레이
        let circleOverlay = NMFCircleOverlay(NMGLatLng(lat: 37.5666102, lng: 126.9783881), radius: 5000)
        circleOverlay.fillColor = UIColor.red.withAlphaComponent(0.2)
        circleOverlay.outlineColor = UIColor.red
        circleOverlay.outlineWidth = 2
        circleOverlay.mapView = naverMapView.mapView
        
    }

    // CLLocationManagerDelegate: 권한 변경 시 위치 업데이트
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    // CLLocationManagerDelegate: 위치 업데이트 시 지도 중심 이동
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let latlng = NMGLatLng(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)

        // 현위치 오버레이 표시
        naverMapView.mapView.locationOverlay.location = latlng

        // 최초 한 번만 지도 카메라 이동
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(latlng, zoom: 16))
            naverMapView.mapView.moveCamera(cameraUpdate)
        }
    }

    // 저장된 PlaceShape를 지도 오버레이로 추가
    func addOverlay(for shape: PlaceShape) {
        switch shape.shapeType {
        case .circle:
            guard let radius = shape.radius else { return }
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
            circleOverlay.radius = radius
            circleOverlay.fillColor = UIColor.blue.withAlphaComponent(0.4)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = .systemBlue
            circleOverlay.mapView = naverMapView.mapView
        // 추후 .rectangle, .polygon, .polyline 등도 여기에 추가
        default:
            break
        }
    }

    // (필요하다면) 저장탭에서 도형 선택 시 지도 이동/하이라이트 처리용 메서드도 여기에 추가
}
