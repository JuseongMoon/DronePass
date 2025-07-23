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
    @Published var selectedCoordinate: CoordinateManager?
    
    var onLongPress: ((CoordinateManager) -> Void)?
    
    init(onLongPress: ((CoordinateManager) -> Void)? = nil) {
        self.onLongPress = onLongPress
        super.init()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let naverMapView = gesture.view as? NMFNaverMapView else { return }
        let mapView = naverMapView.mapView
        
        let point = gesture.location(in: gesture.view)
        let latlng = mapView.projection.latlng(from: point)
        let coordinate = CoordinateManager(latitude: latlng.lat, longitude: latlng.lng)
        
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
                    let coord = CoordinateManager(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    self.onLongPress?(coord)
                }
            } catch {
                print("주소 변환 실패:", error)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let coordinate = annotation.coordinate
        let coord = CoordinateManager(latitude: coordinate.latitude, longitude: coordinate.longitude)
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
    
    // 새 도형 만들기 관련 상태
    @State private var newShapeCoordinate: CoordinateManager?
    @State private var newShapeAddress: String?
    @State private var showShapeEditView = false
    
    // 알림 관련 상태
    @State private var showNewShapeConfirmAlert = false
    @State private var showGeocodingFailedAlert = false

    var body: some View {
        ZStack {
            NaverMapView(
                mapView: $mapView,
                onMapViewCreated: { mapView in
                    setupMapView(mapView)
                },
                onLongPress: { coordinate in
                    handleLongPress(at: coordinate)
                }
            )
            .edgesIgnoringSafeArea(.all)

            // 오른쪽 하단 플로팅 플러스 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // 플로팅 버튼을 누르면 ShapeEditView가 모달로 나타납니다.
                    Button(action: {
                        let center: NMGLatLng
                        if let mapView = mapView {
                            center = mapView.cameraPosition.target
                        } else {
                            center = NMGLatLng(lat: 37.5665, lng: 126.9780)
                        }
                        self.newShapeCoordinate = nil
                        self.newShapeAddress = nil // 주소는 nil로 설정
                        self.showShapeEditView = true
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
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
            viewModel.currentMapView = nil
            viewModel.overlays.removeAll()
        }
        .sheet(isPresented: $showShapeEditView) {
            ShapeEditView(
                coordinate: newShapeCoordinate,
                onAdd: { _ in
                    viewModel.reloadOverlays()
                    showShapeEditView = false
                    clearNewShapeData()
                },
                originalShape: ShapeModel(
                    id: UUID(),
                    title: "",
                    shapeType: .circle,
                    baseCoordinate: newShapeCoordinate ?? CoordinateManager(latitude: 0, longitude: 0), // 임시 좌표
                    radius: nil,
                    memo: nil,
                    address: newShapeAddress,
                    expireDate: nil,
                    startedAt: Date(),
                    color: ColorManager.shared.defaultColor.rawValue
                )
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert("새 도형 만들기", isPresented: $showNewShapeConfirmAlert) {
            Button("아니오", role: .cancel) { clearNewShapeData() }
            Button("예") {
                showShapeEditView = true
            }
        } message: {
            Text("해당 위치에 새 도형을 만드시겠습니까?")
        }
        .alert("주소 검색 실패", isPresented: $showGeocodingFailedAlert) {
            Button("아니오", role: .cancel) { clearNewShapeData() }
            Button("예") {
                showShapeEditView = true
            }
        } message: {
            Text("선택한 위치의 주소를 가져올 수 없습니다. 좌표로만 도형을 만드시겠습니까?")
        }
    }
    
    private func handleLongPress(at location: CLLocationCoordinate2D) {
        Task {
            do {
                let address = try await NaverGeocodingService.shared.reverseGeocode(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                // 성공 시, 좌표와 주소를 저장하고 확인창을 띄웁니다.
                self.newShapeCoordinate = CoordinateManager(latitude: location.latitude, longitude: location.longitude)
                self.newShapeAddress = address
                self.showNewShapeConfirmAlert = true
            } catch {
                // 실패 시, 안내 문구를 주소로 설정하고 실패 알림을 띄웁니다.
                self.newShapeCoordinate = CoordinateManager(latitude: location.latitude, longitude: location.longitude)
                self.newShapeAddress = "해당 위치의 주소가 존재하지 않습니다"
                self.showGeocodingFailedAlert = true
            }
        }
    }
    
    private func clearNewShapeData() {
        newShapeCoordinate = nil
        newShapeAddress = nil
        showNewShapeConfirmAlert = false
        showGeocodingFailedAlert = false
        showShapeEditView = false
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
            if let shape = notification.object as? ShapeModel {
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
