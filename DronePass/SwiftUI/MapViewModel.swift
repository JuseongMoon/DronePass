import SwiftUI
import NMapsMap
import CoreLocation
import Combine

class MapViewModel: NSObject, ObservableObject {
    @Published var hasCenteredOnUser = false
    @Published var highlightedShapeID: UUID?
    @Published var overlays: [NMFOverlay] = []
    @Published var currentMapView: NMFMapView?

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private enum CameraConstants {
        static let defaultRadius: Double = 100.0
    }
    
    private enum AnimationType {
        case none
        case smooth
        case immediate
    }

    // NotificationCenter 상수 정의
    private static let moveToShapeNotification = Notification.Name("MoveToShapeNotification")
    private static let moveWithoutZoomNotification = Notification.Name("MoveWithoutZoomNotification")
    private static let shapeOverlayTappedNotification = Notification.Name("ShapeOverlayTapped")
    private static let openSavedTabNotification = Notification.Name("OpenSavedTabNotification")

    override init() {
        super.init()
        setupLocationManager()
        setupShapeStoreObserver()
        setupNotifications()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10

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

    private func setupShapeStoreObserver() {
        PlaceShapeStore.shared.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // ⭐️ 상태변이 defer 필요 없음 (이미 MainQueue) – but 코어 함수만 사용
                self?.reloadOverlays()
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoveToShape(_:)),
            name: Self.moveToShapeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoveWithoutZoom(_:)),
            name: Self.moveWithoutZoomNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShapeOverlayTapped(_:)),
            name: Self.shapeOverlayTappedNotification,
            object: nil
        )
    }

    @objc private func handleShapeOverlayTapped(_ notification: Notification) {
        guard let shape = notification.object as? PlaceShape else { return }
        
        // 하이라이트 상태 업데이트
        highlightedShapeID = shape.id
        reloadOverlays()
        
        // 저장 탭 열기 알림 전송
        NotificationCenter.default.post(
            name: Self.openSavedTabNotification,
            object: shape.id
        )
    }

    // MARK: - 카메라 이동 처리
    @objc private func handleMoveWithoutZoom(_ notification: Notification) {
        guard let moveData = notification.object as? SavedTableListView.MoveToShapeData,
              let mapView = currentMapView else { return }
        
        if shouldSkipMove(for: moveData) { return }
        
        // 하이라이트 업데이트 및 오버레이 리로드
        highlightedShapeID = moveData.shapeID
        reloadOverlays()

        // 저장 탭 열기 알림 전송
        NotificationCenter.default.post(
            name: Self.openSavedTabNotification,
            object: moveData.shapeID
        )
        
        // 줌 변경 없이 좌표만 이동
        let center = NMGLatLng(lat: moveData.coordinate.latitude, lng: moveData.coordinate.longitude)
        let (offsetX, offsetY) = calculateDynamicOffsets()
        let offsetCenter = offsetLatLng(center: center, mapView: mapView, offsetX: offsetX, offsetY: offsetY)
        let cameraPosition = NMFCameraPosition(offsetCenter, zoom: mapView.cameraPosition.zoom)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
        
    @objc private func handleMoveToShape(_ notification: Notification) {
        guard let moveData = notification.object as? SavedTableListView.MoveToShapeData,
              let mapView = currentMapView else { return }
        
        // 이미 하이라이트된 도형이면 리턴
        if shouldSkipMove(for: moveData) { return }
        
        moveCameraToShape(
            shapeID: moveData.shapeID,
            coordinate: moveData.coordinate,
            radius: moveData.radius,
            mapView: mapView
        )
    }
    
    private func shouldSkipMove(for moveData: SavedTableListView.MoveToShapeData) -> Bool {
        guard let shapeID = highlightedShapeID,
              let currentShape = PlaceShapeStore.shared.shapes.first(where: { $0.id == shapeID }) else {
            return false
        }
        return currentShape.baseCoordinate == moveData.coordinate
    }
    
    private func moveCameraToShape(shapeID: UUID, coordinate: Coordinate, radius: Double, mapView: NMFMapView) {
        let center = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let targetZoom = calculateZoomLevel(for: radius)
        
        // 1단계: 먼저 현재 위치에서 목표 줌 레벨로 조정
        let currentCameraPosition = mapView.cameraPosition
        let cameraPosition1 = NMFCameraPosition(currentCameraPosition.target, zoom: targetZoom)
        let cameraUpdate1 = NMFCameraUpdate(position: cameraPosition1)
        cameraUpdate1.animation = .easeIn
        mapView.moveCamera(cameraUpdate1)
        
        // 2단계: 목표 좌표로 이동하면서 하이라이트 적용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // 하이라이트 상태 업데이트 및 오버레이 리로드
            self.highlightedShapeID = shapeID
            self.reloadOverlays()

            // 줌 레벨이 변경된 후, 올바른 projection으로 오프셋을 계산합니다.
            let (offsetX, offsetY) = self.calculateDynamicOffsets()
            let offsetCenter = self.offsetLatLng(center: center, mapView: mapView, offsetX: offsetX, offsetY: offsetY)

            let cameraPosition2 = NMFCameraPosition(offsetCenter, zoom: targetZoom)
            let cameraUpdate2 = NMFCameraUpdate(position: cameraPosition2)
            cameraUpdate2.animation = .easeIn
            mapView.moveCamera(cameraUpdate2)
        }
    }
    
    private func calculateDynamicOffsets() -> (x: CGFloat, y: CGFloat) {
        let screenSize = UIScreen.main.bounds.size
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = screenSize.width > screenSize.height

        if isPad && isLandscape {
            // iPad 가로 모드
            // Y축: 중앙 정렬 (오프셋 0)
            // X축: 화면 너비의 15%만큼 왼쪽으로 이동 (오른쪽으로 보이게)
            let offsetX = -screenSize.width * 0.15
            return (x: offsetX, y: 0)
        } else {
            // iPhone 세로 & iPad 세로 모드
            // Y축: 화면 높이의 23%만큼 위로 이동 (위에 27% 여백)
            // X축: 중앙 정렬 (오프셋 0)
            let offsetY = screenSize.height * 0.23
            return (x: 0, y: offsetY)
        }
    }

    func addOverlay(for shape: PlaceShape, mapView: NMFMapView) {
        switch shape.shapeType {
        case .circle:
            addCircleOverlay(for: shape, mapView: mapView)
        default:
            break
        }
    }
    
    private func addCircleOverlay(for shape: PlaceShape, mapView: NMFMapView) {
        guard let radius = shape.radius else { return }
        
        let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
        let circleOverlay = createCircleOverlay(center: center, radius: radius, shape: shape)
        circleOverlay.mapView = mapView
        overlays.append(circleOverlay)
        
        // 하이라이트 오버레이 추가
        if shape.id == highlightedShapeID {
            let highlightOverlay = createHighlightOverlay(center: center, radius: radius)
            highlightOverlay.mapView = mapView
            overlays.append(highlightOverlay)
        }
        
        // 터치 핸들러 설정
        circleOverlay.touchHandler = { _ in
            let moveData = SavedTableListView.MoveToShapeData(
                coordinate: shape.baseCoordinate,
                radius: shape.radius ?? CameraConstants.defaultRadius,
                shapeID: shape.id
            )
            NotificationCenter.default.post(
                name: Self.moveWithoutZoomNotification,
                object: moveData
            )
            return true
        }
    }
    
    private func createCircleOverlay(center: NMGLatLng, radius: Double, shape: PlaceShape) -> NMFCircleOverlay {
        let circleOverlay = NMFCircleOverlay()
        circleOverlay.center = center
        circleOverlay.radius = radius
        
        let isExpired = shape.expireDate?.compare(Date()) == .orderedAscending
        let mainColor: UIColor = isExpired ? .systemGray : (UIColor(hex: shape.color) ?? .black)
        
        circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
        circleOverlay.outlineWidth = 2
        circleOverlay.outlineColor = mainColor
        
        return circleOverlay
    }
    
    private func createHighlightOverlay(center: NMGLatLng, radius: Double) -> NMFCircleOverlay {
        let highlightOverlay = NMFCircleOverlay()
        highlightOverlay.center = center
        highlightOverlay.radius = radius + 2
        highlightOverlay.fillColor = UIColor.clear
        highlightOverlay.outlineWidth = 5
        highlightOverlay.outlineColor = .systemRed
        
        return highlightOverlay
    }

    func reloadOverlays() {
        // 기존 오버레이 정리
        clearOverlays()
        
        // 새로운 오버레이 추가
        guard let mapView = currentMapView else { return }
        
        let savedShapes = PlaceShapeStore.shared.shapes
        for shape in savedShapes {
            addOverlay(for: shape, mapView: mapView)
        }
    }
    
    private func clearOverlays() {
        overlays.forEach { overlay in
            overlay.mapView = nil
        }
        overlays.removeAll()
    }
    
    func calculateZoomLevel(for radius: Double) -> Double {
        let minRadius: Double = 100
        let maxRadius: Double = 2000
        let minZoom: Double = 11
        let maxZoom: Double = 15
        
        if radius <= minRadius { return maxZoom }
        if radius >= maxRadius { return minZoom }
        
        let zoomRange = maxZoom - minZoom
        let radiusRange = maxRadius - minRadius
        let normalizedRadius = radius - minRadius
        
        return maxZoom - (normalizedRadius * zoomRange / radiusRange)
    }
    
    func offsetLatLng(center: NMGLatLng, mapView: NMFMapView, offsetX: CGFloat, offsetY: CGFloat) -> NMGLatLng {
        let point = mapView.projection.point(from: center)
        let offsetPoint = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
        return mapView.projection.latlng(from: offsetPoint)
    }
}

extension MapViewModel: CLLocationManagerDelegate {
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
        
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            NotificationCenter.default.post(name: Notification.Name("CenterOnUserLocation"), object: latlng)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
} 
