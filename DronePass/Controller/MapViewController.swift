//
//  MapViewController.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.

// 역할: 네이버 지도를 표시하고 도형 오버레이를 관리하는 뷰 컨트롤러
// 연관기능: 위치 추적, 도형 표시, 하이라이트, 지도 이동

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
import NMapsMap // 네이버 지도 SDK를 가져옵니다. (지도 표시 기능)
import CoreLocation // CoreLocation 프레임워크를 가져옵니다. (위치 관련 기능)
import Combine

extension Notification.Name {
    static let clearShapeHighlight = Notification.Name("clearShapeHighlight") // 도형 하이라이트 해제 알림 이름 정의
    static let shapeColorDidChange = Notification.Name("shapeColorDidChange")
}

final class MapViewController: UIViewController, CLLocationManagerDelegate { // 지도 및 위치 관리를 담당하는 뷰 컨트롤러입니다.

    // MARK: - Properties
    @IBOutlet public var naverMapView: NMFNaverMapView! // 스토리보드에 연결된 네이버 지도 뷰입니다.
    
    private let locationManager = CLLocationManager() // 위치 관리를 위한 매니저 객체입니다.
    private var hasCenteredOnUser = false // 사용자의 위치로 카메라를 이동했는지 여부
    private var highlightedShapeID: UUID? // 하이라이트된 도형의 ID
    private var overlays: [NMFOverlay] = [] // 지도에 표시된 오버레이 배열
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLocationManager()
        setupLongPressGesture()
        setupShapeStoreObserver() // PlaceShapeStore 옵저버 추가
        drawSampleShapes()
        NotificationCenter.default.addObserver(self, selector: #selector(moveToShape(_:)), name: ShapeSelectionCoordinator.shapeSelectedOnList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearHighlight), name: .clearShapeHighlight, object: nil)
        // ⭐️ 오버레이 터치 알림 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(handleOverlayTapped(_:)), name: Notification.Name("ShapeOverlayTapped"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShapeColorChange(_:)), name: .shapeColorDidChange, object: nil)
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
    
    // MARK: - 도형 표시

    private func drawSampleShapes() {
        let savedShapes = PlaceShapeStore.shared.shapes
        for shape in savedShapes {
            addOverlay(for: shape)
        }
    }

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        naverMapView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: naverMapView)
            let latLng = naverMapView.mapView.projection.latlng(from: point)
            let coordinate = Coordinate(latitude: latLng.lat, longitude: latLng.lng)
            
            // 리버스 지오코딩으로 주소 조회
            NaverGeocodingService.shared.fetchAddress(latitude: coordinate.latitude, longitude: coordinate.longitude) { [weak self] result in
                DispatchQueue.main.async {
                    let addVC = AddShapePopupViewController(coordinate: coordinate) { [weak self] newShape in
                        PlaceShapeStore.shared.addShape(newShape)
                        self?.addOverlay(for: newShape)
                    }
                    addVC.modalPresentationStyle = .fullScreen
                    
                    switch result {
                    case .success(let address):
                        addVC.setInitialAddress(address)
                    case .failure:
                        addVC.setInitialAddress(nil)
                    }
                    
                    self?.present(addVC, animated: true)
                }
            }
        }
    }
    
    // MARK: - Geocoding
    private func fetchAddressForCoordinate(_ coordinate: Coordinate, completion: @escaping (String?) -> Void) {
        NaverGeocodingService.shared.fetchAddress(latitude: coordinate.latitude, longitude: coordinate.longitude) { result in
            switch result {
            case .success(let address):
                completion(address)
            case .failure(let error):
                print("주소 조회 실패:", error.localizedDescription)
                completion(nil)
            }
        }
    }
    
    // PlaceShapeStore 변경 감지 및 지도 업데이트
    private func setupShapeStoreObserver() {
        PlaceShapeStore.shared.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadOverlays()
            }
            .store(in: &cancellables)
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
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = center
            circleOverlay.radius = radius
            
            // 만료 여부 확인
            let isExpired = shape.expireDate?.compare(Date()) == .orderedAscending
            
            // 만료된 경우 회색으로, 아닌 경우 원래 색상 사용
            let mainColor: UIColor
            if isExpired {
                mainColor = .systemGray
            } else {
                mainColor = UIColor(hex: shape.color) ?? .black
            }
            
            circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor
            circleOverlay.mapView = naverMapView.mapView
            overlays.append(circleOverlay)

            // 하이라이트 대상이면 두 번째(더 진한) 원 추가
            if shape.id == highlightedShapeID {
                let highlightOverlay = NMFCircleOverlay()
                highlightOverlay.center = center
                highlightOverlay.radius = radius + 2
                highlightOverlay.fillColor = UIColor.clear
                highlightOverlay.outlineWidth = 5
                highlightOverlay.outlineColor = .systemRed
                highlightOverlay.mapView = naverMapView.mapView
                overlays.append(highlightOverlay)
            }

            // ⭐️ 오버레이 터치 이벤트 등록 및 추적 로그
            print("[DEBUG] addOverlay: 도형 오버레이 등록됨, id=\(shape.id)")
            circleOverlay.touchHandler = { [weak self] _ in
                print("[DEBUG] 오버레이 터치됨! id=\(shape.id)")
                NotificationCenter.default.post(name: Notification.Name("ShapeOverlayTapped"), object: shape)
                return true
            }
        // TODO: 사각형/다각형 등은 여기에 추가
        default:
            break
        }
    }

    
    // MARK: - 지도 이동 관련 메서드
//    @objc private func moveToShape(_ notification: Notification) {
//        guard let shape = notification.object as? PlaceShape else { return }
//        highlightedShapeID = shape.id
//        reloadOverlays()
//
//        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
//        let offsetCenter = offsetLatLng(center: center, mapView: naverMapView.mapView, offsetY: 100)
//        let radius = shape.radius ?? 500.0
//
//        // 위도 1도 ≈ 111,000m, 경도 1도 ≈ 111,000m * cos(위도)
//        let latDelta = radius / 111_000.0
//        let lngDelta = radius / (111_000.0 * cos(center.lat * .pi / 180))
//        let southWest = NMGLatLng(lat: offsetCenter.lat - latDelta, lng: offsetCenter.lng - lngDelta)
//        let northEast = NMGLatLng(lat: offsetCenter.lat + latDelta, lng: offsetCenter.lng + lngDelta)
//        let bounds = NMGLatLngBounds(southWest: southWest, northEast: northEast)
//        let cameraUpdate = NMFCameraUpdate(fit: bounds, padding: 100)
//        cameraUpdate.animation = .easeIn
//        cameraUpdate.animationDuration = 0.2
//
//        DispatchQueue.main.async { [weak self] in
//            self?.naverMapView.mapView.moveCamera(cameraUpdate)
//        }
//    }
    
//    @objc private func moveToShape(_ notification: Notification) {
//        guard let shape = notification.object as? PlaceShape else { return }
//        highlightedShapeID = shape.id
//        reloadOverlays()
//        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
//        let zoom = calculateZoomLevel(for: shape.radius ?? 500.0)
//        let offsetCenter = offsetLatLng(center: center, mapView: naverMapView.mapView, offsetY: 200)
//        let cameraPosition = NMFCameraPosition(offsetCenter, zoom: zoom)
//        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
//        cameraUpdate.animation = .easeIn
//        cameraUpdate.animationDuration = 0.2
//        DispatchQueue.main.async { [weak self] in
//            self?.naverMapView.mapView.moveCamera(cameraUpdate)
//        }
//    }
    
//    @objc private func moveToShape(_ notification: Notification) {
//        guard let shape = notification.object as? PlaceShape else { return }
//        highlightedShapeID = shape.id
//        reloadOverlays()
//
//        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
//        let zoom = calculateZoomLevel(for: shape.radius ?? 500.0)
//
//        // 1. 첫 번째 이동: 중심점+줌(오프셋 없이) 이동
//        let cameraPosition1 = NMFCameraPosition(center, zoom: zoom)
//        let cameraUpdate1 = NMFCameraUpdate(position: cameraPosition1)
//        cameraUpdate1.animation = .easeIn
//        cameraUpdate1.animationDuration = 0.01
//
//        self.naverMapView.mapView.moveCamera(cameraUpdate1)
//
//        // 2. 애니메이션 끝난 후 오프셋 적용한 위치로 재이동 (0.18초 후)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
//            guard let self = self else { return }
//            let offsetCenter = self.offsetLatLng(center: center, mapView: self.naverMapView.mapView, offsetY: 200)
//            let cameraPosition2 = NMFCameraPosition(offsetCenter, zoom: zoom)
//            let cameraUpdate2 = NMFCameraUpdate(position: cameraPosition2)
//            cameraUpdate2.animation = .easeIn
//            cameraUpdate2.animationDuration = 0.01
//            self.naverMapView.mapView.moveCamera(cameraUpdate2)
//        }
//    }
    
    // 아주 빠르게 두번 이동
//    @objc private func moveToShape(_ notification: Notification) {
//        guard let shape = notification.object as? PlaceShape else { return }
//        highlightedShapeID = shape.id
//        reloadOverlays()
//
//        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
//        let zoom = calculateZoomLevel(for: shape.radius ?? 500.0)
//
//        // 1. 첫 번째 이동: 즉시(center, zoom) (애니메이션 없이)
//        let cameraPosition1 = NMFCameraPosition(center, zoom: zoom)
//        let cameraUpdate1 = NMFCameraUpdate(position: cameraPosition1)
//        cameraUpdate1.animation = .none
//        self.naverMapView.mapView.moveCamera(cameraUpdate1)
//
//        // 2. projection이 반영된 후(0.01~0.02초 후), 오프셋 적용 위치로 이동(애니메이션 on)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
//            guard let self = self else { return }
//            let offsetCenter = self.offsetLatLng(center: center, mapView: self.naverMapView.mapView, offsetY: 200)
//            let cameraPosition2 = NMFCameraPosition(offsetCenter, zoom: zoom)
//            let cameraUpdate2 = NMFCameraUpdate(position: cameraPosition2)
//            cameraUpdate2.animation = .none
//            self.naverMapView.mapView.moveCamera(cameraUpdate2)
//        }
//    }

    // 아주 빠르게 두번 이동 + 같은 도형일 경우 동작 안하기
    @objc private func moveToShape(_ notification: Notification) {
        guard let shape = notification.object as? PlaceShape else { return }

        // 1. 이미 하이라이트된 도형이면, 즉시 리턴 (이동 X, 화면 깜빡임 방지)
        if highlightedShapeID == shape.id {
            return
        }
        highlightedShapeID = shape.id
        reloadOverlays()

        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
        let zoom = calculateZoomLevel(for: shape.radius ?? 500.0)

        // 1. 첫 번째 이동: 즉시(center, zoom) (애니메이션 없이)
        let cameraPosition1 = NMFCameraPosition(center, zoom: zoom)
        let cameraUpdate1 = NMFCameraUpdate(position: cameraPosition1)
        cameraUpdate1.animation = .none
        self.naverMapView.mapView.moveCamera(cameraUpdate1)

        // 2. projection이 반영된 후(0.02초 후), 오프셋 적용 위치로 이동(애니메이션 on)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard let self = self else { return }
            let offsetCenter = self.offsetLatLng(center: center, mapView: self.naverMapView.mapView, offsetY: 200)
            let cameraPosition2 = NMFCameraPosition(offsetCenter, zoom: zoom)
            let cameraUpdate2 = NMFCameraUpdate(position: cameraPosition2)
            cameraUpdate2.animation = .none
            self.naverMapView.mapView.moveCamera(cameraUpdate2)
        }
    }
    
    
    
    
//      지도뷰를 아예 껐다가 켜기
//
//    @objc private func moveToShape(_ notification: Notification) {
//        guard let shape = notification.object as? PlaceShape else { return }
//        highlightedShapeID = shape.id
//        reloadOverlays()
//
//        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
//        let zoom = calculateZoomLevel(for: shape.radius ?? 500.0)
//
//        // 1. 지도 뷰 숨김 (유저에게 아무것도 안보이게)
//        self.naverMapView.isHidden = true
//
//        // 2. 즉시 이동 (첫 이동)
//        let cameraPosition1 = NMFCameraPosition(center, zoom: zoom)
//        let cameraUpdate1 = NMFCameraUpdate(position: cameraPosition1)
//        cameraUpdate1.animation = .none
//        self.naverMapView.mapView.moveCamera(cameraUpdate1)
//
//        // 3. projection 반영된 뒤 오프셋 이동
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
//            guard let self = self else { return }
//            let offsetCenter = self.offsetLatLng(center: center, mapView: self.naverMapView.mapView, offsetY: 200)
//            let cameraPosition2 = NMFCameraPosition(offsetCenter, zoom: zoom)
//            let cameraUpdate2 = NMFCameraUpdate(position: cameraPosition2)
//            cameraUpdate2.animation = .none
//            self.naverMapView.mapView.moveCamera(cameraUpdate2)
//            
//            // 4. 지도 뷰를 다시 보여줌 (딜레이 주면 더 자연스럽게)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//                self.naverMapView.isHidden = false
//            }
//        }
//    }
    

    
    
    /// 도형에 대한 카메라 위치 계산
    private func calculateCameraPosition(for shape: PlaceShape) -> NMFCameraPosition {
        // 도형의 중심 좌표
        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
        // 반경에 따른 줌 레벨 계산
        let radius = shape.radius ?? 500.0
        let zoom = calculateZoomLevel(for: radius)
        // 오프셋 없이 중심 좌표 그대로 사용
        return NMFCameraPosition(center, zoom: zoom)
    }
    
    /// 반경에 따른 줌 레벨 계산
    private func calculateZoomLevel(for radius: Double) -> Double {
        let minRadius: Double = 100
        let maxRadius: Double = 2000
        let minZoom: Double = 11
        let maxZoom: Double = 15
        
        // 경계값 처리
        if radius <= minRadius { return maxZoom }
        if radius >= maxRadius { return minZoom }
        
        // 선형 보간으로 줌 레벨 계산
        let zoomRange = maxZoom - minZoom
        let radiusRange = maxRadius - minRadius
        let normalizedRadius = radius - minRadius
        
        return maxZoom - (normalizedRadius * zoomRange / radiusRange)
    }
    
    // 아래쪽으로 100 이동
    private func offsetLatLng(center: NMGLatLng, mapView: NMFMapView, offsetY: CGFloat) -> NMGLatLng {
        let point = mapView.projection.point(from: center)
        let offsetPoint = CGPoint(x: point.x, y: point.y + 200) // Y는 -값: 화면 위로 올라감
        return mapView.projection.latlng(from: offsetPoint)
    }
    
    private func reloadOverlays() {
        // 기존 오버레이 모두 제거
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
        
        // PlaceShapeStore의 도형들 다시 그리기
        let savedShapes = PlaceShapeStore.shared.shapes
        for shape in savedShapes {
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
    }

    @objc private func handleOverlayTapped(_ notification: Notification) {
        guard let shape = notification.object as? PlaceShape else { return }
        highlightedShapeID = shape.id
        reloadOverlays()
        if let tabBarController = self.tabBarController as? MainTabBarController {
            tabBarController.openSavedTabAndHighlightShape(shape)
        }
    }

    @objc private func handleShapeColorChange(_ notification: Notification) {
        guard let newColor = notification.object as? PaletteColor else { return }
        PlaceShapeStore.shared.updateAllShapesColor(to: newColor.rawValue)
        reloadOverlays()
    }
}

extension MainTabBarController {
    func openSavedTabAndHighlightShape(_ shape: PlaceShape) {
        if !isSavedSheetPresented {
            presentBottomSheet()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: Notification.Name("HighlightShapeInList"), object: shape)
            }
        } else {
            NotificationCenter.default.post(name: Notification.Name("HighlightShapeInList"), object: shape)
        }
    }
    
    // 저장 탭의 높이 상태를 저장하는 프로퍼티
    var savedSheetHeight: SheetHeight {
        get {
            if let savedVC = viewControllers?[1] as? SavedBottomSheetViewController {
                let height = savedVC.currentSheetHeight
                if height <= 250 {
                    return .low
                } else if height >= 430 {
                    return .high
                } else {
                    return .medium
                }
            }
            return .low
        }
    }
}

// 저장 탭의 높이 상태를 나타내는 열거형
enum SheetHeight {
    case low
    case medium
    case high
}

