import SwiftUI
import NMapsMap

struct NaverMapView: UIViewRepresentable {
    @Binding var mapView: NMFMapView?
    var onMapViewCreated: (NMFMapView) -> Void
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let naverMapView = NMFNaverMapView()
        naverMapView.showLocationButton = true
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
} 
