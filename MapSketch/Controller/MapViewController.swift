//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit
import NMapsMap
import CoreLocation

extension Notification.Name {
    static let clearShapeHighlight = Notification.Name("clearShapeHighlight")
}

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Properties
    @IBOutlet public var naverMapView: NMFNaverMapView! // 스토리보드에 연결
    
    private let locationManager = CLLocationManager()
    private var hasCenteredOnUser = false
    private var highlightedShapeID: UUID?
    private var overlays: [NMFOverlay] = []
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLocationManager()
        drawSampleShapes()
        NotificationCenter.default.addObserver(self, selector: #selector(moveToShape(_:)), name: ShapeSelectionCoordinator.shapeSelectedOnList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearHighlight), name: .clearShapeHighlight, object: nil)
    }
    
    // MARK: - Setup Methods
    private func setupMapView() {
        // 현위치 버튼 표시 및 활성화
        naverMapView.showLocationButton = true
        naverMapView.mapView.locationOverlay.hidden = false
        
        // 카메라 초기 위치 설정 (서울 중심 예시)
        let position = NMFCameraPosition(NMGLatLng(lat: 37.575563, lng: 126.976793), zoom: 14)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10미터마다 위치 업데이트
        
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
        let shapesToShow = SampleShapeLoader.loadSampleShapes()
        for shape in shapesToShow {
            addOverlay(for: shape)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latlng = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        
        // 현위치 오버레이 표시
        naverMapView.mapView.locationOverlay.location = latlng
        
        // 최초 한 번만 지도 카메라 이동
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(latlng, zoom: 16))
            cameraUpdate.animation = .easeIn
            naverMapView.mapView.moveCamera(cameraUpdate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - Overlay Drawing
    /// 저장된 PlaceShape를 지도 오버레이로 추가
    func addOverlay(for shape: PlaceShape) {
        switch shape.shapeType {
        case .circle:
            guard let radius = shape.radius else { return }
            let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
            // 기본 원
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = center
            circleOverlay.radius = radius
            let mainColor = UIColor(hex: shape.color)
            circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor
            circleOverlay.mapView = naverMapView.mapView
            overlays.append(circleOverlay) // 배열에 추가
            
            // 하이라이트 대상이면 두 번째(더 진한) 원 추가
            if shape.id == highlightedShapeID {
                let highlightOverlay = NMFCircleOverlay()
                highlightOverlay.center = center
                highlightOverlay.radius = radius + 8
                highlightOverlay.fillColor = UIColor.clear
                highlightOverlay.outlineWidth = 6
                highlightOverlay.outlineColor = .systemBlue
                highlightOverlay.mapView = naverMapView.mapView
                overlays.append(highlightOverlay) // 배열에 추가
            }
            // TODO: 사각형/다각형 등은 여기에 추가
        default:
            break
        }
    }
    
    // MARK: - (Optional) 유틸리티 함수, 도형 선택/이동 등
    // 필요 시 여기에 추가
    
    // MARK: - 리스트에서 터치하면 지도의 해당 장소로 시점을 이동
    @objc private func moveToShape(_ notification: Notification) {
        guard let shape = notification.object as? PlaceShape else { return }
        highlightedShapeID = shape.id // 하이라이트 ID 저장
        let lat = shape.baseCoordinate.latitude
        let lng = shape.baseCoordinate.longitude
        let radius = shape.radius ?? 500.0
        
        let zoom = zoomLevel(for: radius)
        
        // 반드시 다음 RunLoop에서 오프셋 계산 및 카메라 이동
        DispatchQueue.main.async {
            let offsetY = self.naverMapView.mapView.bounds.height * 0.25
            let center = NMGLatLng(lat: lat, lng: lng)
            let offsetCenter = self.offsetLatLng(center: center, mapView: self.naverMapView.mapView, offsetY: offsetY)
            let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(offsetCenter, zoom: zoom))
            cameraUpdate.animation = .easeIn
            self.naverMapView.mapView.moveCamera(cameraUpdate)
        }
        
        // 지도 오버레이 리로드
        reloadOverlays()
    }
    
    // 반경 → 줌레벨 변환 공식
    func zoomLevel(for radius: Double) -> Double {
        let minRadius: Double = 100
        let maxRadius: Double = 2000
        let minZoom: Double = 11
        let maxZoom: Double = 15
        
        if radius <= minRadius { return maxZoom }
        if radius >= maxRadius { return minZoom }
        // 선형 보간
        return maxZoom - (radius - minRadius) * (maxZoom - minZoom) / (maxRadius - minRadius)
    }
    
    // 중심 좌표를 Y축으로 오프셋
    func offsetLatLng(center: NMGLatLng, mapView: NMFMapView, offsetY: CGFloat) -> NMGLatLng {
        let projection = mapView.projection
        let screenPoint = projection.point(from: center)
        let offsetPoint = CGPoint(x: screenPoint.x, y: screenPoint.y + offsetY)
        return projection.latlng(from: offsetPoint)
    }
    
    private func reloadOverlays() {
        // 기존 오버레이 모두 제거
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
        // 다시 그리기
        let shapesToShow = SampleShapeLoader.loadSampleShapes()
        for shape in shapesToShow {
            addOverlay(for: shape)
        }
    }
    func removeAllOverlays() {
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
    }
    
    @objc private func clearHighlight() {
        highlightedShapeID = nil
        reloadOverlays()
    }
    
    private func dismissSheet() {
        NotificationCenter.default.post(name: .clearShapeHighlight, object: nil)
        // ... 기존 바텀시트 닫기 코드 ...
    }
}
