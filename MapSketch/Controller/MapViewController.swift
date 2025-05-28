//
//  MapViewController.swift
//  MapSketch
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
//        // 샘플 도형 표시
//        let sampleShapes = SampleShapeLoader.loadSampleShapes()
//        for shape in sampleShapes {
//            addOverlay(for: shape)
//        }
        
        // PlaceShapeStore의 도형들도 표시
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
            let mainColor = UIColor(hex: shape.color)
            circleOverlay.fillColor = mainColor?.withAlphaComponent(0.3) ?? .black
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor ?? .black
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

    // MARK: - 도형 추가
    
//    @objc func addShapeButtonTapped() {
//        let coordinate = ... // 유저가 지도에서 지정한 위치
//        let newShape = PlaceShape(
//            title: "새 도형",
//            shapeType: .circle,
//            baseCoordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
//            radius: 200, // 기본값, 사용자 입력 가능
//            memo: "직접 추가",
//            color: PaletteColor.blue.hex // 색상 선택 가능
//        )
//        // 도형 추가는 뷰모델을 통해
//        SavedBottomSheetViewModel().addShape(newShape)
//        // 또는 PlaceShapeStore.shared.addShape(newShape) 직접 사용
//    }
    
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
    
    private func reloadOverlays() {
        // 기존 오버레이 모두 제거
        overlays.forEach { $0.mapView = nil }
        overlays.removeAll()
        
        // 샘플 도형 다시 그리기
//        let sampleShapes = SampleShapeLoader.loadSampleShapes()
//        for shape in sampleShapes {
//            addOverlay(for: shape)
//        }
        
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
}

