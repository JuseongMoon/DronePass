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

    override init() {
        super.init()
        setupLocationManager()
        setupShapeStoreObserver()
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

    func addOverlay(for shape: PlaceShape, mapView: NMFMapView) {
        switch shape.shapeType {
        case .circle:
            guard let radius = shape.radius else { return }
            let center = NMGLatLng(lat: shape.baseCoordinate.latitude, lng: shape.baseCoordinate.longitude)
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = center
            circleOverlay.radius = radius

            let isExpired = shape.expireDate?.compare(Date()) == .orderedAscending
            let mainColor: UIColor = isExpired ? .systemGray : (UIColor(hex: shape.color) ?? .black)

            circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor
            circleOverlay.mapView = mapView
            overlays.append(circleOverlay)

            if shape.id == highlightedShapeID {
                let highlightOverlay = NMFCircleOverlay()
                highlightOverlay.center = center
                highlightOverlay.radius = radius + 2
                highlightOverlay.fillColor = UIColor.clear
                highlightOverlay.outlineWidth = 5
                highlightOverlay.outlineColor = .systemRed
                highlightOverlay.mapView = mapView
                overlays.append(highlightOverlay)
            }

            circleOverlay.touchHandler = { [weak self] _ in
                NotificationCenter.default.post(name: Notification.Name("ShapeOverlayTapped"), object: shape)
                return true
            }
        default:
            break
        }
    }

    func reloadOverlays() {
        // ⭐️ mapView 유효성 체크
        guard let mapView = currentMapView else {
            overlays.removeAll()
            return
        }
        // ⭐️ overlays 해제 시 nil-check
        overlays.forEach { overlay in
            if overlay.mapView != nil {
                overlay.mapView = nil
            }
        }
        overlays.removeAll()
        let savedShapes = PlaceShapeStore.shared.shapes
        for shape in savedShapes {
            addOverlay(for: shape, mapView: mapView)
        }
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
    
    func offsetLatLng(center: NMGLatLng, mapView: NMFMapView, offsetY: CGFloat) -> NMGLatLng {
        let point = mapView.projection.point(from: center)
        let offsetPoint = CGPoint(x: point.x, y: point.y + offsetY)
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
