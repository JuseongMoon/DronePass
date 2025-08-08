//
//  SavedTableListView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Notification Names Extension
// shapesDidChange는 NotiName.swift에 정의되어 있음

struct SavedTableListView: View {
    @StateObject private var placeShapeStore = ShapeFileStore.shared
    @StateObject private var repository = ShapeRepository.shared
    @ObservedObject private var sortingManager = ShapeSortingManager.shared
    @ObservedObject private var settingManager = SettingManager.shared
    @Binding var selectedShapeID: UUID?
    @Binding var shapeIDToScrollTo: UUID?
    
    // 중복 loadShapes 호출 방지를 위한 디바운싱
    @State private var lastLoadTime: Date = Date.distantPast
    private let loadDebounceInterval: TimeInterval = 0.5 // 500ms
    
    // 강제 뷰 업데이트를 위한 트리거
    @State private var refreshTrigger: Bool = false
    
    // 정렬된 배열을 직접 관리
    @State private var sortedActiveShapes: [ShapeModel] = []
    @State private var sortedExpiredShapes: [ShapeModel] = []
    @State private var detailShape: ShapeModel? = nil
    
    // MARK: - Notification Names
    static let moveToShapeNotification = Notification.Name("MoveToShapeNotification")
    static let shapeOverlayTappedNotification = Notification.Name("ShapeOverlayTapped")
    
    // MARK: - Notification Data Structure
    struct MoveToShapeData {
        let coordinate: CoordinateManager
        let radius: Double
        let shapeID: UUID
        
        init(coordinate: CoordinateManager, radius: Double, shapeID: UUID) {
            self.coordinate = coordinate
            self.radius = radius
            self.shapeID = shapeID
        }
    }
    
    // MARK: - Constants
    enum Constants {
        static let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df
        }()
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                if placeShapeStore.shapes.isEmpty {
                    EmptyStateView()
                } else {
                    // 활성 도형들 (정렬 적용)
                    if !sortedActiveShapes.isEmpty {
                        ShapeListContent(
                            shapes: sortedActiveShapes,
                            selectedShapeID: $selectedShapeID,
                            onDelete: deleteShape,
                            onShowDetail: { shape in detailShape = shape },
                            sortingContext: "active-\(sortingManager.selectedSortOption.rawValue)-\(sortingManager.sortDirection.rawValue)"
                        )
                    }
                    
                    // 만료된 도형들 (정렬 적용) - 숨기기 설정이 비활성화된 경우에만 표시
                    if !sortedExpiredShapes.isEmpty && !settingManager.isHideExpiredShapesEnabled {
                        Section("만료됨") {
                            ShapeListContent(
                                shapes: sortedExpiredShapes,
                                selectedShapeID: $selectedShapeID,
                                onDelete: deleteShape,
                                onShowDetail: { shape in detailShape = shape },
                                sortingContext: "expired-\(sortingManager.selectedSortOption.rawValue)-\(sortingManager.sortDirection.rawValue)"
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .environment(\.defaultMinListHeaderHeight, 1)
            .padding(.top, -25)
            .id("\(sortingManager.selectedSortOption.rawValue)-\(sortingManager.sortDirection.rawValue)-\(refreshTrigger)")
            .onAppear(perform: onAppear)
            .onReceive(NotificationCenter.default.publisher(for: .shapesDidChange)) { _ in
                print("🔄 SavedTableListView: shapesDidChange 알림 수신")
                handleShapesDidChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ReloadMapOverlays"))) { _ in
                // 지도 오버레이 리로드 시 저장 목록도 업데이트
                DispatchQueue.main.async {
                    print("🔄 SavedTableListView: 지도 오버레이 리로드 알림 수신")
                    updateSortedShapes()
                }
            }
            .onReceive(sortingManager.objectWillChange) { _ in
                // 정렬 옵션이 변경되면 UI를 업데이트
                DispatchQueue.main.async {
                    print("🔄 SavedTableListView: 정렬 옵션 변경 감지")
                    updateSortedShapes()
                }
            }
            .onReceive(settingManager.objectWillChange) { _ in
                // 설정이 변경되면 UI를 업데이트
                DispatchQueue.main.async {
                    print("🔄 SavedTableListView: 설정 변경 감지")
                    refreshTrigger.toggle()
                }
            }
            .onChange(of: placeShapeStore.shapes) { _ in
                // shapes 배열이 변경되면 정렬 업데이트
                print("🔄 SavedTableListView: placeShapeStore.shapes 변경 감지")
                updateSortedShapes()
            }
            .onChange(of: shapeIDToScrollTo) { newID in
                guard let id = newID else { return }

                // 안전한 처리를 위해 지연 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.handleShapeSelection(to: id)
                    
                    // 스크롤을 위해 추가 지연 후 시도
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .sheet(item: $detailShape) { shape in
            ShapeDetailView(shape: shape)
        }
    }
    
    // MARK: - Private Methods
    private func onAppear() {
        loadShapesIfNeeded()
        updateSortedShapes()
    }
    
    private func updateSortedShapes() {
        print("🔄 SavedTableListView: 도형 정렬 업데이트 시작")
        
        // 비행종료일순 정렬일 때는 전체를 먼저 정렬한 후 분리
        if sortingManager.selectedSortOption == .flightEndDate {
            print("🔄 SavedTableListView: 비행종료일순 정렬 - 전체 정렬 후 분리 방식 사용")
            let allSortedShapes = sortingManager.sortShapes(placeShapeStore.shapes)
            
            // 정렬된 전체 목록을 활성/만료로 분리
            sortedActiveShapes = allSortedShapes.filter { shape in
                guard let endDate = shape.flightEndDate else { return true }
                return endDate > Date()
            }
            
            sortedExpiredShapes = allSortedShapes.filter { shape in
                guard let endDate = shape.flightEndDate else { return false }
                return endDate <= Date()
            }
        } else {
            // 다른 정렬 옵션들은 기존 방식 사용
            let activeShapes = sortingManager.getActiveShapes(placeShapeStore.shapes)
            let expiredShapes = sortingManager.getExpiredShapes(placeShapeStore.shapes)
            
            sortedActiveShapes = Array(activeShapes)
            sortedExpiredShapes = Array(expiredShapes)
        }
        
        print("🔄 SavedTableListView: 활성 도형 \(sortedActiveShapes.count)개, 만료 도형 \(sortedExpiredShapes.count)개")
        
        // 정렬된 데이터 검증 로그 추가
        print("🔄 SavedTableListView: 정렬된 활성 도형 목록:")
        for (index, shape) in sortedActiveShapes.enumerated() {
            print("  [\(index)] \(shape.title): flightStartDate=\(shape.flightStartDate), flightEndDate=\(String(describing: shape.flightEndDate))")
        }
        
        print("🔄 SavedTableListView: 정렬된 만료 도형 목록:")
        for (index, shape) in sortedExpiredShapes.enumerated() {
            print("  [\(index)] \(shape.title): flightStartDate=\(shape.flightStartDate), flightEndDate=\(String(describing: shape.flightEndDate))")
        }
        
        // 뷰 강제 업데이트
        DispatchQueue.main.async {
            self.refreshTrigger.toggle()
            print("🔄 SavedTableListView: 정렬 후 뷰 강제 업데이트")
        }
    }
    
    private func handleShapesDidChange() {
        print("🔄 SavedTableListView: 도형 변경 처리 시작")
        loadShapesIfNeeded()
        updateSortedShapes()
        
        // 강제 뷰 업데이트를 위한 트리거 토글
        DispatchQueue.main.async {
            self.refreshTrigger.toggle()
            print("🔄 SavedTableListView: 뷰 강제 업데이트 트리거")
        }
    }
    
    /// 중복 loadShapes 호출을 방지하는 디바운싱 로드
    private func loadShapesIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastLoadTime) >= loadDebounceInterval {
            DispatchQueue.main.async {
                placeShapeStore.loadShapes()
                lastLoadTime = now
            }
        }
    }
    
    private func deleteShape(at indexSet: IndexSet) {
        // 현재 표시된 도형 목록에서 삭제할 도형들을 찾습니다
        let allDisplayedShapes = sortedActiveShapes + sortedExpiredShapes
        
        for index in indexSet {
            let shape = allDisplayedShapes[index]
            Task {
                do {
                    try await repository.removeShape(id: shape.id)
                } catch {
                    print("❌ 도형 삭제 실패: \(error)")
                }
            }
        }
    }
    
    /// 안전한 도형 선택 처리
    private func handleShapeSelection(to shapeID: UUID) {
        // 해당 도형이 실제로 리스트에 존재하는지 확인
        let allShapes = sortedActiveShapes + sortedExpiredShapes
        let shapeExists = allShapes.contains { $0.id == shapeID }
        
        if shapeExists {
            // 도형이 존재하면 선택 상태로 설정
            selectedShapeID = shapeID
            print("🔄 SavedTableListView: 도형 선택 성공 - \(shapeID)")
        } else {
            print("⚠️ SavedTableListView: 도형이 리스트에 존재하지 않음 - \(shapeID)")
            
            // 만료된 도형이 필터링되어 제거된 경우 안내 메시지 표시
            if let shape = placeShapeStore.shapes.first(where: { $0.id == shapeID }) {
                if shape.isExpired && settingManager.isHideExpiredShapesEnabled {
                    print("ℹ️ SavedTableListView: 만료된 도형이 숨김 설정으로 인해 표시되지 않음")
                }
            }
        }

        // 트리거를 리셋하여 다음 요청을 준비합니다.
        DispatchQueue.main.async {
            shapeIDToScrollTo = nil
        }
    }
}

// MARK: - EmptyStateView
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("저장된 도형이 없습니다.")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("지도에서 + 버튼을 누르거나 지도를 길게 눌러서 새로운 도형을 추가해보세요.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

// MARK: - ShapeListContent
private struct ShapeListContent: View {
    let shapes: [ShapeModel]
    @Binding var selectedShapeID: UUID?
    let onDelete: (IndexSet) -> Void
    let onShowDetail: (ShapeModel) -> Void
    let sortingContext: String // 정렬 컨텍스트를 추가
    
    var body: some View {
        ForEach(shapes, id: \.id) { shape in
            ShapeListRow(shape: shape, selectedShapeID: $selectedShapeID, onShowDetail: onShowDetail)
                .id(shape.id) // 스크롤을 위해 단순한 ID 사용
        }
        .onDelete(perform: onDelete)
    }
}

// MARK: - ShapeListRow
private struct ShapeListRow: View {
    @Binding var selectedShapeID: UUID?
    let onShowDetail: (ShapeModel) -> Void
    
    let shape: ShapeModel
    
    init(shape: ShapeModel, selectedShapeID: Binding<UUID?>, onShowDetail: @escaping (ShapeModel) -> Void) {
        self.shape = shape
        _selectedShapeID = selectedShapeID
        self.onShowDetail = onShowDetail
    }
    
    private var isSelected: Bool {
        selectedShapeID == shape.id
    }
    
    private var isExpired: Bool {
        guard let endDate = shape.flightEndDate else { return false }
        return endDate <= Date()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isSelected {
                Color.accentColor.opacity(0.1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, -60)
                    .padding(.vertical, -40)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
            }
            
            HStack(spacing: 8) {
                // 왼쪽: 색상 인디케이터
                ShapeColorIndicator(color: shape.color, isExpired: isExpired)
                    .padding(.leading, 4)
                
                // 중앙: 도형 정보
                ShapeInfoContent(shape: shape, isExpired: isExpired)
                    .padding(.leading, 4)
                
                Spacer()
                
                // 오른쪽: 상세 정보 및 액션
                ShapeDetailContent(onShowDetail: { onShowDetail(shape) })
                    .padding(.trailing, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture { handleShapeTap() }
            .frame(minHeight: 55)
        }
    }
    
    private func handleShapeTap() {
        // 지도 이동 및 하이라이트를 위한 알림만 보냅니다.
        selectedShapeID = shape.id
        
        let moveData = SavedTableListView.MoveToShapeData(
            coordinate: shape.baseCoordinate,
            radius: shape.radius ?? 100.0,
            shapeID: shape.id
        )
        
        NotificationCenter.default.post(
            name: SavedTableListView.moveToShapeNotification,
            object: moveData
        )
    }
}

// MARK: - Row Components
private struct ShapeColorIndicator: View {
    let color: String
    let isExpired: Bool
    
    var body: some View {
        VStack(alignment: .trailing) {
            Rectangle()
                .fill(isExpired ? Color(.systemGray) : Color(UIColor(hex: color) ?? .systemBlue))
                .frame(width: 4, height: 35)
                .cornerRadius(15)
                .shadow(radius: 1)
        }
    }
}

private struct ShapeInfoContent: View {
    let shape: ShapeModel
    let isExpired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(shape.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)
            if let address = shape.address {
                Text(address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Text(dateRangeText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dateRangeText: String {
        let start = SavedTableListView.Constants.dateFormatter.string(from: shape.flightStartDate)
        if let end = shape.flightEndDate {
            let endText = SavedTableListView.Constants.dateFormatter.string(from: end)
            if isExpired {
                return "\(start) ~ \(endText)"
            } else {
                return "\(start) ~ \(endText)"
            }
        }
        return start
    }
}

private struct ShapeDetailContent: View {
    let onShowDetail: () -> Void
    
    var body: some View {
        Button(action: {
            onShowDetail()
        }) {
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 30, alignment: .trailing)
    }
}

// MARK: - Supporting Views
private struct ColorRectangle: View {
    let color: String
    
    var body: some View {
        Rectangle()
            .fill(Color(UIColor(hex: color) ?? .systemBlue))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(15)
    }
}

private struct ShapeInfo: View {
    let shape: ShapeModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(shape.title)
                .font(.headline)
                .lineLimit(1)
            if let address = shape.address {
                Text(address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Text("\(formattedDate(shape.flightStartDate)) ~ \(formattedDate(shape.flightEndDate ?? Date()))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        SavedTableListView.Constants.dateFormatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    SavedTableListView(
        selectedShapeID: .constant(nil),
        shapeIDToScrollTo: .constant(nil)
    )
        .onAppear {
            // Canvas에서 더미 데이터 추가
            let dummyShapes = [
                ShapeModel(
                    title: "드론 비행 구역 A",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 500.0,
                    address: "서울특별시 중구 세종대로 110",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                    color: "#FF6B6B"
                ),
                ShapeModel(
                    title: "헬기 착륙장",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 300.0,
                    address: "서울특별시 강남구 테헤란로 152",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                    color: "#4ECDC4"
                ),
                ShapeModel(
                    title: "공사 현장",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 800.0,
                    address: "서울특별시 마포구 와우산로 94",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()),
                    color: "#45B7D1"
                ),
                ShapeModel(
                    title: "이벤트 공간",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 200.0,
                    address: "서울특별시 종로구 종로 1---------------------",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    color: "#96CEB4"
                ),
                ShapeModel(
                    title: "보안 구역",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 100000.0,
                    address: "서울특별시 용산구 이태원로 27",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
                    color: "#FFEAA7"
                ),
                ShapeModel(
                    title: "만료된 도형",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 150.0,
                    address: "서울특별시 서초구 서초대로 396",
                    flightStartDate: Date(),
                    flightEndDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), // 5일 전 만료
                    color: "#8E8E93"
                )
            ]
            
            ShapeFileStore.shared.shapes = dummyShapes
        }
}

#Preview("Empty State") {
    SavedTableListView(
        selectedShapeID: .constant(nil),
        shapeIDToScrollTo: .constant(nil)
    )
        .onAppear {
            ShapeFileStore.shared.shapes = []
        }
}

