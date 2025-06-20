import SwiftUI
import NMapsMap
import CoreLocation

struct NaverMapView: UIViewRepresentable {
    @Binding var mapView: NMFMapView?
    var onMapViewCreated: (NMFMapView) -> Void
    var onLongPress: ((CLLocationCoordinate2D) -> Void)?
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let naverMapView = NMFNaverMapView()
        naverMapView.showLocationButton = true
        naverMapView.mapView.touchDelegate = context.coordinator
        naverMapView.mapView.locationOverlay.hidden = false
        
        // 초기 카메라 위치 설정 (서울 중심)
        let position = NMFCameraPosition(NMGLatLng(lat: 37.575563, lng: 126.976793), zoom: 14)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
        
        mapView = naverMapView.mapView
        onMapViewCreated(naverMapView.mapView)
        
        return naverMapView
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // 필요한 경우 여기서 업데이트 로직 구현
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NMFMapViewTouchDelegate {
        var parent: NaverMapView
        
        init(_ parent: NaverMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            // 지도 탭 이벤트 (필요 시 구현)
        }
        
        func mapView(_ mapView: NMFMapView, didLongTapMap latlng: NMGLatLng, point: CGPoint) {
            parent.onLongPress?(CLLocationCoordinate2D(latitude: latlng.lat, longitude: latlng.lng))
        }
    }
} 
