//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: - Properties
    @IBOutlet public var naverMapView: NMFNaverMapView! // 스토리보드에 연결

    private let locationManager = CLLocationManager()
    private var hasCenteredOnUser = false

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLocationManager()
        drawSampleShapes()
    }

    // MARK: - Setup Methods
    private func setupMapView() {
        // 현위치 버튼 표시
        naverMapView.showLocationButton = true

        // 카메라 초기 위치 설정 (서울 중심 예시)
        let position = NMFCameraPosition(NMGLatLng(lat: 37.575563, lng: 126.976793), zoom: 14)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
    }

    private func setupLocationManager() {
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
    }

    private func drawSampleShapes() {
        // 샘플 도형 불러오기 (TestShape.swift)
//        let shapesToShow = [TestShape.circle01, TestShape.circle02, TestShape.circle03, TestShape.circle04]
        // JSON 파일에서 샘플도형 불러오기
        let shapesToShow = SampleShapeLoader.loadSampleShapes()
        // 특정 도형만 불러오기
//        let shapesToShow = SampleShapeLoader.loadSampleShapes().filter { $0.color == .red || $0.color == .green }

        for shape in shapesToShow {
            addOverlay(for: shape)
        }
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

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

    // MARK: - Overlay Drawing
    /// 저장된 PlaceShape를 지도 오버레이로 추가
    func addOverlay(for shape: PlaceShape) {
        switch shape.shapeType {
        case .circle:
            guard let radius = shape.radius else { return }
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
            circleOverlay.radius = radius
            // ✅ 팔레트 컬러 적용
            let mainColor = UIColor(hex: shape.color)
            circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor
            circleOverlay.mapView = naverMapView.mapView
        // TODO: 사각형/다각형 등은 여기에 추가
        default:
            break
        }
    }

    // MARK: - (Optional) 유틸리티 함수, 도형 선택/이동 등
    // 필요 시 여기에 추가
}
