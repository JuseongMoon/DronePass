//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 네이버 지도를 표시하고 도형 오버레이를 관리하는 뷰 컨트롤러
// 연관기능: 위치 추적, 도형 표시, 하이라이트, 지도 이동

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
import NMapsMap // 네이버 지도 SDK를 가져옵니다. (지도 표시 기능)
import CoreLocation // CoreLocation 프레임워크를 가져옵니다. (위치 관련 기능)

extension Notification.Name {
    static let clearShapeHighlight = Notification.Name("clearShapeHighlight") // 도형 하이라이트 해제 알림 이름 정의
}

class MapViewController: UIViewController, CLLocationManagerDelegate { // 지도 및 위치 관리를 담당하는 뷰 컨트롤러입니다.
    
    // MARK: - Properties
    @IBOutlet public var naverMapView: NMFNaverMapView! // 스토리보드에 연결된 네이버 지도 뷰입니다.
    
    private let locationManager = CLLocationManager() // 위치 관리를 위한 매니저 객체입니다.
    private var hasCenteredOnUser = false // 사용자의 위치로 카메라를 이동했는지 여부
    private var highlightedShapeID: UUID? // 하이라이트된 도형의 ID
    private var overlays: [NMFOverlay] = [] // 지도에 표시된 오버레이 배열
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView() // 지도 뷰 설정
        setupLocationManager() // 위치 매니저 설정
        drawSampleShapes() // 샘플 도형 표시
        NotificationCenter.default.addObserver(self, selector: #selector(moveToShape(_:)), name: ShapeSelectionCoordinator.shapeSelectedOnList, object: nil) // 리스트에서 도형 선택 시 이동
        NotificationCenter.default.addObserver(self, selector: #selector(clearHighlight), name: .clearShapeHighlight, object: nil) // 하이라이트 해제 알림 등록
    }
    
    // MARK: - Setup Methods
    private func setupMapView() { // 지도 뷰의 초기 설정을 담당합니다.
        // 현위치 버튼 표시 및 활성화
        naverMapView.showLocationButton = true
        naverMapView.mapView.locationOverlay.hidden = false
        
        // 카메라 초기 위치 설정 (서울 중심 예시)
        let position = NMFCameraPosition(NMGLatLng(lat: 37.575563, lng: 126.976793), zoom: 14)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
    }
    
    private func setupLocationManager() { // 위치 매니저의 초기 설정을 담당합니다.
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
    
    private func drawSampleShapes() { // 샘플 도형을 지도에 표시하는 메서드입니다.
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
    func addOverlay(for shape: PlaceShape) { // 도형 데이터를 지도에 오버레이로 추가하는 메서드입니다.
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
    @objc private func moveToShape(_ notification: Notification) { // 리스트에서 도형을 선택하면 해당 위치로 이동하는 메서드입니다.
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
    func zoomLevel(for radius: Double) -> Double { // 반경에 따라 적절한 줌레벨을 계산하는 메서드입니다.
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
    func offsetLatLng(center: NMGLatLng, mapView: NMFMapView, offsetY: CGFloat) -> NMGLatLng { // 중심 좌표를 Y축으로 오프셋하는 메서드입니다.
        let projection = mapView.projection
        let screenPoint = projection.point(from: center)
        let offsetPoint = CGPoint(x: screenPoint.x, y: screenPoint.y + offsetY)
        return projection.latlng(from: offsetPoint)
    }
    
    private func reloadOverlays() { // 지도 오버레이를 모두 다시 그리는 메서드입니다.
        // 기존 오버레이 모두 제거
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
        // 다시 그리기
        let shapesToShow = SampleShapeLoader.loadSampleShapes()
        for shape in shapesToShow {
            addOverlay(for: shape)
        }
    }
    func removeAllOverlays() { // 모든 오버레이를 지도에서 제거하는 메서드입니다.
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
    }
    
    @objc private func clearHighlight() { // 하이라이트를 해제하고 오버레이를 리로드하는 메서드입니다.
        highlightedShapeID = nil
        reloadOverlays()
    }
    
    private func dismissSheet() { // 바텀시트 닫기 시 호출되는 메서드입니다.
        NotificationCenter.default.post(name: .clearShapeHighlight, object: nil)
        // ... 기존 바텀시트 닫기 코드 ...
    }
}
