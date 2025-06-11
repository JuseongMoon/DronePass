//
//  MainView.swift
//  DronePass
//
//  Created by 문주성 on 6/10/25.
//

import SwiftUI
import NMapsMap

class MainViewCoordinator: NSObject {
    var parent: MainView
    
    init(_ parent: MainView) {
        self.parent = parent
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: gesture.view)
            if let latlng = parent.mapView?.projection.latlng(from: point) {
                let coordinate = Coordinate(latitude: latlng.lat, longitude: latlng.lng)
                parent.selectedCoordinate = coordinate
                parent.isAddShapeSheetPresented = true
            }
        }
    }
}

struct MainView: View {
    @StateObject var viewModel = MapViewModel()
    @State var mapView: NMFMapView?
    @State var isAddShapeSheetPresented = false
    @State var selectedCoordinate: Coordinate?
    @State var coordinator: MainViewCoordinator?
    
    var body: some View {
        ZStack {
            NaverMapView(mapView: $mapView) { mapView in
                setupMapView(mapView)
            }
            .edgesIgnoringSafeArea(.all)
            
            // 오버레이화살표 버튼
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        // 현위치로 이동
//                        if let location = mapView?.locationOverlay.location {
//                            let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(location, zoom: 16))
//                            cameraUpdate.animation = .easeIn
//                            mapView?.moveCamera(cameraUpdate)
//                        }
//                    }) {
//                        Image(systemName: "location.fill")
//                            .font(.title2)
//                            .foregroundColor(.red)
//                            .padding()
//                            .background(Color.white)
//                            .clipShape(Circle())
//                            .shadow(radius: 2)
//                    }
//                    .padding()
//                }
//            }
        }
        .onAppear {
            setupNotifications()
            coordinator = MainViewCoordinator(self)
        }
        .onDisappear {
            removeNotifications()
        }
        .sheet(isPresented: $isAddShapeSheetPresented) {
            if let coordinate = selectedCoordinate {
                AddShapeView(coordinate: coordinate) { newShape in
                    PlaceShapeStore.shared.addShape(newShape)
                    viewModel.reloadOverlays()
                }
            }
        }
    }
    
    private func setupMapView(_ mapView: NMFMapView) {
        // MapViewModel에 mapView 설정
        viewModel.currentMapView = mapView
        
        // 롱프레스 제스처 추가
        let longPressGesture = UILongPressGestureRecognizer(target: coordinator, action: #selector(MainViewCoordinator.handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        // 초기 도형 그리기
        viewModel.reloadOverlays()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: Notification.Name("CenterOnUserLocation"), object: nil, queue: .main) { notification in
            if let latlng = notification.object as? NMGLatLng {
                let cameraUpdate = NMFCameraUpdate(position: NMFCameraPosition(latlng, zoom: 16))
                cameraUpdate.animation = .easeIn
                mapView?.moveCamera(cameraUpdate)
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("ShapeOverlayTapped"), object: nil, queue: .main) { notification in
            if let shape = notification.object as? PlaceShape {
                viewModel.highlightedShapeID = shape.id
                viewModel.reloadOverlays()
            }
        }
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

struct AddShapeView: View {
    let coordinate: Coordinate
    let onShapeAdded: (PlaceShape) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var radius: Double = 500
    @State private var color: String = "#FF0000"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("도형 정보")) {
                    Text("위도: \(coordinate.latitude)")
                    Text("경도: \(coordinate.longitude)")
                    VStack {
                        Text("반경: \(Int(radius))m")
                        Slider(value: $radius, in: 100...2000, step: 100) {
                            Text("반경")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        let shape = PlaceShape(
                            id: UUID(),
                            title: "새 도형",
                            shapeType: .circle,
                            baseCoordinate: coordinate,
                            radius: radius,
                            expireDate: nil,
                            color: color
                        )
                        onShapeAdded(shape)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("저장")
                    }
                }
            }
            .navigationTitle("새 도형 추가")
            .navigationBarItems(trailing: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    MainView()
}
