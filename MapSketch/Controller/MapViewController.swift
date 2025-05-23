//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 네이버 지도를 표시하고 도형 오버레이를 관리하는 뷰 컨트롤러
// 연관기능: 위치 추적, 도형 표시, 하이라이트, 지도 이동

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
import NMapsMap // 네이버 지도 SDK를 가져옵니다. (지도 표시 기능)
import CoreLocation // CoreLocation 프레임워크를 가져옵니다. (위치 관련 기능)
import Combine

extension Notification.Name {
    static let clearShapeHighlight = Notification.Name("clearShapeHighlight") // 도형 하이라이트 해제 알림 이름 정의
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
    
    private func drawSampleShapes() {
        // 샘플 도형 표시
        let sampleShapes = SampleShapeLoader.loadSampleShapes()
        for shape in sampleShapes {
            addOverlay(for: shape)
        }
        
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
            let addVC = AddShapePopupViewController(coordinate: coordinate) { [weak self] newShape in
                PlaceShapeStore.shared.addShape(newShape)
                self?.addOverlay(for: newShape)
            }
            addVC.modalPresentationStyle = .fullScreen
            present(addVC, animated: true)
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
            // 기본 원
            let circleOverlay = NMFCircleOverlay()
            circleOverlay.center = center
            circleOverlay.radius = radius
            let mainColor = UIColor(hex: shape.color)
            circleOverlay.fillColor = mainColor.withAlphaComponent(0.3)
            circleOverlay.outlineWidth = 2
            circleOverlay.outlineColor = mainColor
            circleOverlay.mapView = naverMapView.mapView
            overlays.append(circleOverlay) // 배열에 추가
            
            // 하이라이트 대상이면 두 번째(더 진한) 원 추가
            if shape.id == highlightedShapeID {
                let highlightOverlay = NMFCircleOverlay()
                highlightOverlay.center = center
                highlightOverlay.radius = radius + 8
                highlightOverlay.fillColor = UIColor.clear
                highlightOverlay.outlineWidth = 6
                highlightOverlay.outlineColor = .systemBlue
                highlightOverlay.mapView = naverMapView.mapView
                overlays.append(highlightOverlay) // 배열에 추가
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
        let sampleShapes = SampleShapeLoader.loadSampleShapes()
        for shape in sampleShapes {
            addOverlay(for: shape)
        }
        
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
}


// MARK: - 도형생성

final class AddShapePopupViewController: UIViewController, UITextFieldDelegate {
    private let coordinate: Coordinate
    private let onAdd: (PlaceShape) -> Void
    
    private let titleField = UITextField()
    private let addressField = UITextField()
    private let memoField = UITextField()
    private let radiusField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    init(coordinate: Coordinate, onAdd: @escaping (PlaceShape) -> Void) {
        self.coordinate = coordinate
        self.onAdd = onAdd
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupTapToDismissKeyboard()
    }
    
    private func setupUI() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // 입력 필드별 가로 스택
        let titleRow = makeInputRow(title: "제목", field: titleField)
        let addressRow = makeInputRow(title: "주소", field: addressField)
        let memoRow = makeInputRow(title: "메모", field: memoField)
        let radiusRow = makeInputRow(title: "반경(m)", field: radiusField)
        
        // 필드별 설정
        titleField.placeholder = "제목을 입력하세요"
        titleField.borderStyle = .roundedRect
        titleField.delegate = self
        titleField.returnKeyType = .next
        
        addressField.placeholder = "해당 장소의 주소를 입력하세요"
        addressField.borderStyle = .roundedRect
        addressField.delegate = self
        addressField.returnKeyType = .next
        
        memoField.placeholder = "메모를 입력하세요"
        memoField.borderStyle = .roundedRect
        memoField.delegate = self
        memoField.returnKeyType = .next
        
        radiusField.placeholder = "미터 단위로 입력해주세요"
        radiusField.borderStyle = .roundedRect
        radiusField.keyboardType = .numberPad
        radiusField.delegate = self
        radiusField.returnKeyType = .done
        radiusField.inputAccessoryView = makeKeyboardToolbar()
        
        let stack = UIStackView(arrangedSubviews: [titleRow, addressRow, memoRow, radiusRow])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        let buttonStack = UIStackView(arrangedSubviews: [saveButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        saveButton.layer.cornerRadius = 12
        saveButton.layer.masksToBounds = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .systemGray
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.masksToBounds = true
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func makeInputRow(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let row = UIStackView(arrangedSubviews: [label, field])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }
    
    // 키보드 툴바: "완료" 버튼
    private func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.items = [UIBarButtonItem.flexibleSpace(), done]
        return toolbar
    }
    
    // 텍스트필드 delegate: Return 키로 다음 필드로 이동, 마지막 필드에서 닫기
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            addressField.becomeFirstResponder()
        } else if textField == addressField {
            memoField.becomeFirstResponder()
        } else if textField == memoField {
            radiusField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc private func doneButtonTapped() {
        view.endEditing(true)
    }
    
    // 배경 탭하면 키보드 내리기
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func saveTapped() {
        let title = titleField.text?.isEmpty == false ? titleField.text! : "새 도형"
        let address = addressField.text?.isEmpty == false ? addressField.text : nil
        let memo = memoField.text
        let radius = Double(radiusField.text ?? "") ?? 200
        let newShape = PlaceShape(
            title: title,
            shapeType: .circle,
            baseCoordinate: coordinate,
            radius: radius,
            memo: memo,
            address: address,
            color: "#FF3B30"
        )
        onAdd(newShape)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
