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
    private var naverMapView: NMFNaverMapView!
    private let locationManager = CLLocationManager()
    /// 사용자 위치로 최초 한 번만 카메라 이동 플래그
    private var hasCenteredOnUser = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) NMFNaverMapView(컨테이너) 추가
        naverMapView = NMFNaverMapView(frame: view.bounds)
        naverMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(naverMapView)

        // 2) 내 위치 버튼 활성화 (SDK 내장 버튼)
        naverMapView.showLocationButton = true

        // 3) 위치 오버레이 설정
        let overlay = naverMapView.mapView.locationOverlay
        overlay.hidden = false
        overlay.circleRadius = 20
        overlay.circleColor = UIColor.systemBlue.withAlphaComponent(0.3)

        // 4) 위치 권한 요청 및 업데이트 시작
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let latlng = NMGLatLng(lat: loc.coordinate.latitude,
                               lng: loc.coordinate.longitude)

        // 오버레이 위치만 매번 갱신
        naverMapView.mapView.locationOverlay.location = latlng

        // 최초 한 번만 카메라 이동
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            let cameraUpdate = NMFCameraUpdate(
                position: NMFCameraPosition(latlng, zoom: 16)
            )
            naverMapView.mapView.moveCamera(cameraUpdate)
        }
    }
}
