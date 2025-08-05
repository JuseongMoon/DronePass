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
    
    // 중복 오버레이 리로드 방지를 위한 디바운싱
    private var lastReloadTime: Date = Date.distantPast
    private let reloadDebounceInterval: TimeInterval = 0.2 // 200ms
    
    // 하이라이트 오버레이 추적을 위한 변수
    private var currentHighlightOverlay: NMFCircleOverlay?
    
    // 이전 도형 상태 추적을 위한 변수
    private var lastShapeCount: Int = 0
    private var lastShapeIDs: Set<UUID> = []

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
    private static let clearMapHighlightNotification = Notification.Name("ClearMapHighlightNotification")

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
        ShapeFileStore.shared.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shapes in
                guard let self = self else { return }
                
                let currentShapeCount = shapes.count
                let currentShapeIDs = Set(shapes.map { $0.id })
                
                // 도형 개수나 ID가 변경된 경우에만 오버레이 리로드
                if currentShapeCount != self.lastShapeCount || currentShapeIDs != self.lastShapeIDs {
                    self.reloadOverlaysIfNeeded()
                    self.lastShapeCount = currentShapeCount
                    self.lastShapeIDs = currentShapeIDs
                    print("📊 도형 변경 감지: \(currentShapeCount)개 도형")
                }
                // 변경사항이 없는 경우 오버레이 리로드 스킵
            }
            .store(in: &cancellables)
    }
    
    /// 중복 오버레이 리로드를 방지하는 디바운싱 리로드
    private func reloadOverlaysIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastReloadTime) >= reloadDebounceInterval {
            reloadOverlays()
            lastReloadTime = now
        }
        // 디바운싱 로그 제거 (너무 자주 출력되는 문제 해결)
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearMapHighlight),
            name: Self.clearMapHighlightNotification,
            object: nil
        )
        
        // 로그아웃 시 맵 오버레이 정리 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearMapOverlays),
            name: Notification.Name("ClearMapOverlays"),
            object: nil
        )
        
        // 색상 변경 시 지도 오버레이 리로드 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReloadMapOverlays),
            name: Notification.Name("ReloadMapOverlays"),
            object: nil
        )
        
        // 도형 변경 시 지도 오버레이 리로드 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShapesDidChange),
            name: Notification.Name("shapesDidChange"),
            object: nil
        )
    }

    @objc private func handleShapeOverlayTapped(_ notification: Notification) {
        guard let shape = notification.object as? ShapeModel else { return }
        
        // 하이라이트 상태 업데이트 (전체 리로드 대신 하이라이트만 변경)
        updateHighlight(for: shape.id)
        
        // 저장 탭 열기 알림 전송
        NotificationCenter.default.post(
            name: Self.openSavedTabNotification,
            object: shape.id
        )
    }

    @objc private func handleClearMapHighlight() {
        if highlightedShapeID != nil {
            updateHighlight(for: nil)
        }
    }
    
    // MARK: - 하이라이트 최적화 메서드
    
    /// 하이라이트만 효율적으로 업데이트 (전체 오버레이 리로드 없이)
    private func updateHighlight(for shapeID: UUID?) {
        guard let mapView = currentMapView else { return }
        
        // 기존 하이라이트와 동일한 경우 스킵
        if highlightedShapeID == shapeID {
            return
        }
        
        // 기존 하이라이트 오버레이 제거
        if let currentHighlight = currentHighlightOverlay {
            currentHighlight.mapView = nil
            if let index = overlays.firstIndex(where: { $0 === currentHighlight }) {
                overlays.remove(at: index)
            }
            currentHighlightOverlay = nil
        }
        
        // 새로운 하이라이트 설정
        highlightedShapeID = shapeID
        
        // 새로운 하이라이트 오버레이 추가
        if let shapeID = shapeID,
           let shape = ShapeFileStore.shared.shapes.first(where: { $0.id == shapeID }),
           let radius = shape.radius {
            
            let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
            let highlightOverlay = createHighlightOverlay(center: center, radius: radius)
            highlightOverlay.mapView = mapView
            overlays.append(highlightOverlay)
            currentHighlightOverlay = highlightOverlay
            
            print("✨ 하이라이트 업데이트: \(shape.title)")
        } else {
            print("🚫 하이라이트 제거")
        }
    }
    
    @objc private func handleClearMapOverlays() {
        clearAllOverlays()
    }
    
    @objc private func handleReloadMapOverlays() {
        print("🎨 색상 변경 감지: 지도 오버레이 리로드")
        
        // 즉시 리로드
        reloadOverlays()
        
        // 강제 리페인트를 위한 추가 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🎨 색상 변경 강제 리페인트")
            self.forceOverlayRedraw()
        }
    }
    
    private func forceOverlayRedraw() {
        guard let mapView = currentMapView else { return }
        
        print("🎨 오버레이 완전 재생성 시작")
        
        // 기존 오버레이 완전 제거
        clearOverlays()
        
        // 새로운 오버레이 다시 생성
        let savedShapes = ShapeFileStore.shared.shapes
        
        // 중복 제거를 위해 ID 기반으로 필터링
        let uniqueShapes = Array(Set(savedShapes.map { $0.id })).compactMap { id in
            savedShapes.first { $0.id == id }
        }
        
        // 만료된 도형 숨기기 설정이 활성화되어 있으면 만료된 도형 필터링
        let filteredShapes: [ShapeModel]
        if SettingManager.shared.isHideExpiredShapesEnabled {
            filteredShapes = uniqueShapes.filter { !$0.isExpired }
        } else {
            filteredShapes = uniqueShapes
        }
        
        // 새로운 오버레이 생성
        for shape in filteredShapes {
            addOverlay(for: shape, mapView: mapView)
            print("🎨 새 오버레이 생성: \(shape.title) - \(shape.color)")
        }
        
        // 하이라이트 다시 적용
        if let highlightedID = highlightedShapeID,
           let highlightedShape = filteredShapes.first(where: { $0.id == highlightedID }),
           let radius = highlightedShape.radius {
            
            let center = NMGLatLng(lat: highlightedShape.baseCoordinate.latitude, lng: highlightedShape.baseCoordinate.longitude)
            let highlightOverlay = createHighlightOverlay(center: center, radius: radius)
            highlightOverlay.mapView = mapView
            overlays.append(highlightOverlay)
            currentHighlightOverlay = highlightOverlay
        }
        
        print("🎨 오버레이 완전 재생성 완료: \(filteredShapes.count)개")
    }
    

    
    @objc private func handleShapesDidChange() {
        print("🔄 MapViewModel: shapesDidChange 알림 수신 - 지도 오버레이 리로드")
        reloadOverlays()
    }

    // MARK: - 카메라 이동 처리
    @objc private func handleMoveWithoutZoom(_ notification: Notification) {
        guard let moveData = notification.object as? SavedTableListView.MoveToShapeData,
              let mapView = currentMapView else { return }
        
        if shouldSkipMove(for: moveData) { return }
        
        // 하이라이트 업데이트 (전체 오버레이 리로드 없이)
        updateHighlight(for: moveData.shapeID)

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
              let currentShape = ShapeFileStore.shared.shapes.first(where: { $0.id == shapeID }) else {
            return false
        }
        return currentShape.baseCoordinate == moveData.coordinate
    }
    
    private func moveCameraToShape(shapeID: UUID, coordinate: CoordinateManager, radius: Double, mapView: NMFMapView) {
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

            // 하이라이트 상태 업데이트 (전체 오버레이 리로드 없이)
            self.updateHighlight(for: shapeID)

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
            // X축: 화면 너비의 14%만큼 왼쪽으로 이동 (오른쪽으로 보이게)
            let offsetX = -screenSize.width * 0.14
            return (x: offsetX, y: 0)
        } else {
            // iPhone 세로 & iPad 세로 모드
            // Y축: 화면 높이의 23%만큼 위로 이동 (위에 27% 여백)
            // X축: 중앙 정렬 (오프셋 0)
            let offsetY = screenSize.height * 0.23
            return (x: 0, y: offsetY)
        }
    }

    func addOverlay(for shape: ShapeModel, mapView: NMFMapView) {
        switch shape.shapeType {
        case .circle:
            addCircleOverlay(for: shape, mapView: mapView)
        default:
            break
        }
    }
    
    private func addCircleOverlay(for shape: ShapeModel, mapView: NMFMapView) {
            guard let radius = shape.radius else { return }
        
            let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
        let circleOverlay = createCircleOverlay(center: center, radius: radius, shape: shape)
        circleOverlay.mapView = mapView
        overlays.append(circleOverlay)
        
        // 터치 핸들러 설정
        circleOverlay.touchHandler = { _ in
            // ShapeOverlayTapped 알림 전송 (MainView에서 처리)
            NotificationCenter.default.post(
                name: Self.shapeOverlayTappedNotification,
                object: shape
            )
            
            return true
        }
    }
    
    private func createCircleOverlay(center: NMGLatLng, radius: Double, shape: ShapeModel) -> NMFCircleOverlay {
        let circleOverlay = NMFCircleOverlay()
        circleOverlay.center = center
        circleOverlay.radius = radius

        let isExpired = shape.isExpired
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
        
        let savedShapes = ShapeFileStore.shared.shapes
        
        // 중복 제거를 위해 ID 기반으로 필터링
        let uniqueShapes = Array(Set(savedShapes.map { $0.id })).compactMap { id in
            savedShapes.first { $0.id == id }
        }
        
        // 만료된 도형 숨기기 설정이 활성화되어 있으면 만료된 도형 필터링
        let filteredShapes: [ShapeModel]
        if SettingManager.shared.isHideExpiredShapesEnabled {
            filteredShapes = uniqueShapes.filter { !$0.isExpired }
            print("🔄 오버레이 리로드 (만료된 도형 숨김): \(filteredShapes.count)개 도형 (전체: \(uniqueShapes.count)개)")
        } else {
            filteredShapes = uniqueShapes
            // 중복이 있을 때만 로그 출력
            let isDuplicate = uniqueShapes.count != savedShapes.count
            if isDuplicate {
                print("🔄 오버레이 리로드 (중복 제거): \(uniqueShapes.count)개 도형 (원본: \(savedShapes.count)개)")
            }
        }
        
        for shape in filteredShapes {
            addOverlay(for: shape, mapView: mapView)
        }
        
        // 하이라이트가 있는 경우 다시 적용 (필터링된 도형 중에서만)
        if let highlightedID = highlightedShapeID,
           let highlightedShape = filteredShapes.first(where: { $0.id == highlightedID }),
           let radius = highlightedShape.radius {
            
            let center = NMGLatLng(lat: highlightedShape.baseCoordinate.latitude, lng: highlightedShape.baseCoordinate.longitude)
            let highlightOverlay = createHighlightOverlay(center: center, radius: radius)
            highlightOverlay.mapView = mapView
            overlays.append(highlightOverlay)
            currentHighlightOverlay = highlightOverlay
        }
    }
    
    private func clearOverlays() {
        overlays.forEach { overlay in
            overlay.mapView = nil
        }
        overlays.removeAll()
        currentHighlightOverlay = nil
        // 로그 메시지 제거 (너무 자주 출력되는 문제 해결)
    }
    
    // 로그아웃 시 호출할 메서드
    func clearAllOverlays() {
        // 중복된 오버레이만 정리
        removeDuplicateOverlays()
        highlightedShapeID = nil
        currentHighlightOverlay = nil
        // 로그 메시지 간소화
        print("🚪 로그아웃: 오버레이 정리 완료")
    }
    
    // 중복된 오버레이 제거
    private func removeDuplicateOverlays() {
        guard let mapView = currentMapView else { return }
        
        let savedShapes = ShapeFileStore.shared.shapes
        
        // 중복 제거를 위해 ID 기반으로 필터링
        let uniqueShapes = Array(Set(savedShapes.map { $0.id })).compactMap { id in
            savedShapes.first { $0.id == id }
        }
        
        // 만료된 도형 숨기기 설정이 활성화되어 있으면 만료된 도형 필터링
        let filteredShapes: [ShapeModel]
        if SettingManager.shared.isHideExpiredShapesEnabled {
            filteredShapes = uniqueShapes.filter { !$0.isExpired }
        } else {
            filteredShapes = uniqueShapes
        }
        
        // 중복이 있는 경우에만 정리
        if uniqueShapes.count != savedShapes.count {
            print("🧹 중복 오버레이 발견: \(savedShapes.count)개 → \(filteredShapes.count)개")
            
            // 기존 오버레이 정리
            clearOverlays()
            
            // 필터링된 도형만 다시 추가
            for shape in filteredShapes {
                addOverlay(for: shape, mapView: mapView)
            }
            
            // 하이라이트 재적용 (필터링된 도형 중에서만)
            if let highlightedID = highlightedShapeID,
               let highlightedShape = filteredShapes.first(where: { $0.id == highlightedID }),
               let radius = highlightedShape.radius {
                
                let center = NMGLatLng(lat: highlightedShape.baseCoordinate.latitude, lng: highlightedShape.baseCoordinate.longitude)
                let highlightOverlay = createHighlightOverlay(center: center, radius: radius)
                highlightOverlay.mapView = mapView
                overlays.append(highlightOverlay)
                currentHighlightOverlay = highlightOverlay
            }
        }
        // 중복이 없는 경우 로그 제거 (불필요한 출력 방지)
    }
    
    func calculateZoomLevel(for radius: Double) -> Double {
        let minRadius: Double = 100
        let maxRadius: Double = 3000
        let minZoom: Double = 11
        let maxZoom: Double = 14
        
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
