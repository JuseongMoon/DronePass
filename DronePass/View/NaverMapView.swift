//
//  NaverMapView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//


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
        
        // 현재 위치 오버레이 활성화
        naverMapView.mapView.locationOverlay.hidden = false
        
        // 현재 위치를 초기 카메라 위치로 설정
        let initialPosition: NMFCameraPosition
        
        if let currentLocation = LocationManager.shared.currentLocation {
            // 현재 위치가 있으면 현재 위치로 설정
            let latLng = NMGLatLng(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude)
            initialPosition = NMFCameraPosition(latLng, zoom: 12)
            
            // 현재 위치 오버레이 위치 설정
            naverMapView.mapView.locationOverlay.location = latLng
        } else {
            // 현재 위치가 없으면 서울 중심을 기본값으로 사용
            let seoulPosition = NMGLatLng(lat: 37.575563, lng: 126.976793)
            initialPosition = NMFCameraPosition(seoulPosition, zoom: 12)
            
            // 위치 업데이트를 시작하고 위치가 업데이트되면 카메라 이동
            LocationManager.shared.startUpdatingLocation()
            
            // 위치 업데이트 알림을 받아서 카메라 이동 및 현재 위치 표시
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("LocationDidUpdate"),
                object: nil,
                queue: .main
            ) { notification in
                if let location = notification.userInfo?["location"] as? CLLocation {
                    let currentLatLng = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
                    let currentPosition = NMFCameraPosition(currentLatLng, zoom: 12)
                    
                    // 카메라 이동
                    naverMapView.mapView.moveCamera(NMFCameraUpdate(position: currentPosition))
                    
                    // 현재 위치 오버레이 위치 설정
                    naverMapView.mapView.locationOverlay.location = currentLatLng
                }
            }
        }
        
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: initialPosition))
        
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
