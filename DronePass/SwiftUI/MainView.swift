//
//  MainView.swift
//  DronePass
//
//  Created by 문주성 on 6/10/25.
//

import SwiftUI
import NMapsMap
import MapKit

class MainViewCoordinator: NSObject, ObservableObject {
    @Published var currentAddress: String = ""
    @Published var isSearchingAddress: Bool = false
    @Published var selectedAddress: String = ""
    @Published var selectedCoordinate: Coordinate?
    
    var onLongPress: ((Coordinate) -> Void)?
    
    init(onLongPress: ((Coordinate) -> Void)? = nil) {
        self.onLongPress = onLongPress
        super.init()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let naverMapView = gesture.view as? NMFNaverMapView else { return }
        let mapView = naverMapView.mapView
        
        let point = gesture.location(in: gesture.view)
        let latlng = mapView.projection.latlng(from: point)
        let coordinate = Coordinate(latitude: latlng.lat, longitude: latlng.lng)
        
        // 주소 조회
        Task {
            do {
                let address = try await NaverGeocodingService.shared.reverseGeocode(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                await MainActor.run {
                    self.currentAddress = address
                    self.onLongPress?(coordinate)
                }
            } catch {
                print("주소 변환 실패:", error)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        // 주소 조회
        Task {
            do {
                let address = try await NaverGeocodingService.shared.reverseGeocode(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                await MainActor.run {
                    self.currentAddress = address
                    let coord = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    self.onLongPress?(coord)
                }
            } catch {
                print("주소 변환 실패:", error)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let coordinate = annotation.coordinate
        let coord = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.selectedCoordinate = coord
    }
}

extension MainViewCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

struct MainView: View {
    @StateObject var viewModel = MapViewModel()
    @State var mapView: NMFMapView?
    @State var selectedCoordinate: Coordinate?
    @State private var coordinator: MainViewCoordinator?

    var body: some View {
        ZStack {
            NaverMapView(mapView: $mapView, onMapViewCreated: { mapView in
                setupMapView(mapView)
            })
            .edgesIgnoringSafeArea(.all)

            // 오른쪽 하단 플로팅 플러스 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // 플로팅 버튼을 누르면 ShapeEditView가 모달로 나타납니다 (selectedCoordinate로 제어)
                    Button(action: {
                        let center: NMGLatLng
                        if let mapView = mapView {
                            center = mapView.cameraPosition.target
                        } else {
                            // mapView가 아직 nil이면 서울 시청 좌표로 대체
                            center = NMGLatLng(lat: 37.5665, lng: 126.9780)
                        }
                        selectedCoordinate = Coordinate(latitude: center.lat, longitude: center.lng)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .none))
                            .foregroundColor(Color.accentColor)
                            .frame(width: 60, height: 60)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(radius: 6)
                            .accessibilityLabel("새 도형 추가")
                    }
                    .padding(.bottom, 90)
                    .padding(.trailing, 20)
                }
            }
        }
        
        
        .onAppear {
            coordinator = MainViewCoordinator { coordinate in
                // ⭐️ 상태변이 반드시 defer
                DispatchQueue.main.async {
                    selectedCoordinate = coordinate
                }
            }
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
            viewModel.currentMapView = nil
            viewModel.overlays.removeAll()
        }
        .sheet(item: $selectedCoordinate, onDismiss: {
            selectedCoordinate = nil
        }) { coordinate in
                ShapeEditView(
                    coordinate: coordinate,
                onAdd: { _ in
                        viewModel.reloadOverlays()
                        DispatchQueue.main.async {
                        selectedCoordinate = nil
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func setupMapView(_ mapView: NMFMapView) {
        viewModel.currentMapView = mapView
        viewModel.reloadOverlays()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: Notification.Name("CenterOnUserLocation"), object: nil, queue: .main) { notification in
            if let latlng = notification.object as? NMGLatLng {
                let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(latlng, zoom: 16))
                cameraUpdate.animation = .easeIn
                // ⭐️ mapView가 nil이 아닐 때만 접근
                mapView?.moveCamera(cameraUpdate)
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("ShapeOverlayTapped"), object: nil, queue: .main) { notification in
            if let shape = notification.object as? PlaceShape {
                // ⭐️ 상태변이 반드시 defer
                DispatchQueue.main.async {
                    viewModel.highlightedShapeID = shape.id
                    viewModel.reloadOverlays()
                }
            }
        }
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// AddShapeView는 더 이상 사용하지 않으므로 삭제함

#Preview {
    MainView()
}

