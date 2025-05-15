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
    private var hasCenteredOnUser = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) 네이버맵 뷰 초기화
        naverMapView = NMFNaverMapView(frame: view.bounds)
        naverMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(naverMapView)
        naverMapView.showLocationButton = true

        // 2) 위치 권한 요청 및 업데이트 시작 (iOS 14+)
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

    
    
    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let latlng = NMGLatLng(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)

        // 오버레이 위치 갱신
        naverMapView.mapView.locationOverlay.location = latlng

        // 최초 한 번만 카메라 이동
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(latlng, zoom: 16))
            naverMapView.mapView.moveCamera(cameraUpdate)
        }
    }
}
