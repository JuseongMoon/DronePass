//
//  SavedTableListView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation

// MARK: - Notification Names Extension
extension Notification.Name {
    static let shapesDidChange = Notification.Name("shapesDidChange")
}

struct SavedTableListView: View {
    @StateObject private var placeShapeStore = ShapeFileStore.shared
    @StateObject private var repository = ShapeRepository.shared
    @Binding var selectedShapeID: UUID?
    @Binding var shapeIDToScrollTo: UUID?
    
    // 중복 loadShapes 호출 방지를 위한 디바운싱
    @State private var lastLoadTime: Date = Date.distantPast
    private let loadDebounceInterval: TimeInterval = 0.5 // 500ms
    
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
                    ShapeListContent(
                        shapes: placeShapeStore.shapes,
                        selectedShapeID: $selectedShapeID,
                        onDelete: deleteShape
                    )
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 10)
            .environment(\.defaultMinListHeaderHeight, 1)
            .padding(.top, -25)
            .onAppear(perform: onAppear)
            .onReceive(NotificationCenter.default.publisher(for: .shapesDidChange)) { _ in
                handleShapesDidChange()
            }
            .onChange(of: shapeIDToScrollTo) { newID in
                guard let id = newID else { return }

                // 뷰가 준비된 후 스크롤을 실행합니다.
                withAnimation {
                    proxy.scrollTo(id, anchor: .center)
                }

                // 트리거를 리셋하여 다음 스크롤을 준비합니다.
                DispatchQueue.main.async {
                    shapeIDToScrollTo = nil
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func onAppear() {
        print("📱 SavedTableListView appeared, shapes count: \(placeShapeStore.shapes.count)")
        loadShapesIfNeeded()
    }
    
    private func handleShapesDidChange() {
        print("🔄 Received shapesDidChange notification")
        loadShapesIfNeeded()
    }
    
    /// 중복 loadShapes 호출을 방지하는 디바운싱 로드
    private func loadShapesIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastLoadTime) >= loadDebounceInterval {
            DispatchQueue.main.async {
                placeShapeStore.loadShapes()
                lastLoadTime = now
            }
        } else {
            print("📝 loadShapes 디바운싱: 이전 로드로부터 \(String(format: "%.3f", now.timeIntervalSince(lastLoadTime)))초 경과")
        }
    }
    
    private func deleteShape(at indexSet: IndexSet) {
        let sortedShapes = placeShapeStore.shapes.sorted(by: { $0.title < $1.title })
        for index in indexSet {
            let shape = sortedShapes[index]
            Task {
                do {
                    try await repository.removeShape(id: shape.id)
                } catch {
                    print("❌ 도형 삭제 실패: \(error)")
                }
            }
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
    
    var body: some View {
        ForEach(shapes.sorted(by: { $0.title < $1.title })) { shape in
            ShapeListRow(shape: shape, selectedShapeID: $selectedShapeID)
                .id(shape.id)
        }
        .onDelete(perform: onDelete)
    }
}

// MARK: - ShapeListRow
private struct ShapeListRow: View {
    let shape: ShapeModel
    @Binding var selectedShapeID: UUID?
    @State private var showingDetailView = false
    
    private var isSelected: Bool {
        selectedShapeID == shape.id
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
                ShapeColorIndicator(color: shape.color)
                    .padding(.leading, 4)
                
                // 중앙: 도형 정보
                ShapeInfoContent(shape: shape)
                    .padding(.leading, 4)
                
                Spacer()
                
                // 오른쪽: 상세 정보 및 액션
                ShapeDetailContent(showingDetailView: $showingDetailView)
                    .padding(.trailing, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture { handleShapeTap() }
            .frame(minHeight: 55)
        }
        .sheet(isPresented: $showingDetailView) {
            ShapeDetailView(shape: shape)
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
    
    var body: some View {
        VStack(alignment: .trailing) {
            Rectangle()
                .fill(Color(UIColor(hex: color) ?? .systemBlue))
                .frame(width: 4, height: 35)
                .cornerRadius(15)
                .shadow(radius: 1)
        }
//        .padding(.bottom)
    }
}

private struct ShapeInfoContent: View {
    let shape: ShapeModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(shape.title)
                .font(.headline)
                .lineLimit(1)
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
            return "\(start) ~ \(SavedTableListView.Constants.dateFormatter.string(from: end))"
        }
        return start
    }
}

private struct ShapeDetailContent: View {
    @Binding var showingDetailView: Bool
    
    var body: some View {
        Button(action: {
            showingDetailView = true
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
                    expireDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                    color: "#FF6B6B"
                ),
                ShapeModel(
                    title: "헬기 착륙장",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 300.0,
                    address: "서울특별시 강남구 테헤란로 152",
                    expireDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                    color: "#4ECDC4"
                ),
                ShapeModel(
                    title: "공사 현장",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 800.0,
                    address: "서울특별시 마포구 와우산로 94",
                    expireDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()),
                    color: "#45B7D1"
                ),
                ShapeModel(
                    title: "이벤트 공간",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 200.0,
                    address: "서울특별시 종로구 종로 1---------------------",
                    expireDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    color: "#96CEB4"
                ),
                ShapeModel(
                    title: "보안 구역",
                    shapeType: .circle,
                    baseCoordinate: CoordinateManager(latitude: 37.5665, longitude: 126.9780),
                    radius: 100000.0,
                    address: "서울특별시 용산구 이태원로 27",
                    expireDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
                    color: "#FFEAA7"
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

