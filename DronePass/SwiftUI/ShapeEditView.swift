//
//  ShapeEditView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
import Combine

struct ShapeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = PlaceShapeStore.shared
    
    let coordinate: Coordinate
    var onAdd: ((PlaceShape) -> Void)?
    var originalShape: PlaceShape?
    
    @State private var title: String = ""
    @State private var address: String = ""
    @State private var radius: String = "200"
    @State private var memo: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isDateOnly = false
    @State private var showingCancelAlert = false
    @State private var coordinateText: String = ""
    @State private var coordinateValidation: String = ""
    @State private var isCoordinateValid = true
    
    private let dateOnlyKey = "isDateOnlyMode"
    private let lastStartDateKey = "lastStartDate"
    private let lastEndDateKey = "lastEndDate"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 제목
                    makeRow(title: "제목") {
                        TextField("제목을 입력하세요", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 좌표
                    makeRow(title: "좌표") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("예시: 37° 38′ 55″ N 126° 41′ 12″ E", text: $coordinateText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: coordinateText) { newValue in
                                    validateCoordinate(newValue)
                                }
                            
                            Text("※드론원스탑에서 승인받은 좌표를 그대로 복사붙여넣기 하세요")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !coordinateValidation.isEmpty {
                                Text(coordinateValidation)
                                    .font(.caption)
                                    .foregroundColor(isCoordinateValid ? .green : .red)
                            }
                        }
                    }
                    
                    // 주소
                    makeRow(title: "주소") {
                        TextField("해당 장소의 주소를 입력하세요", text: $address)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // 반경
                    makeRow(title: "반경(m)") {
                        TextField("미터 단위로 입력해주세요", text: $radius)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    
                    
                    // 시작일
                    makeRow(title: "시작일") {
                        DatePicker("", selection: $startDate, displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                            .onChange(of: startDate) { _ in
                                if endDate < startDate {
                                    endDate = startDate
                                }
                            }
                    }
                    
                    // 종료일
                    makeRow(title: "종료일") {
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                    }
                    
                    // 날짜 설정
                    makeRow(title: "일단위 입력") {
                        Toggle("", isOn: $isDateOnly)
                            .onChange(of: isDateOnly) { newValue in
                                UserDefaults.standard.set(newValue, forKey: dateOnlyKey)
                                updateDates()
                            }
                    }
                    
                    // 메모
                    makeRow(title: "메모") {
                        TextEditor(text: $memo)
                            .frame(height: 300)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray5))
                            )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        if hasChanges() {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveShape()
                    }
                }
            }
            .alert("수정 중인 정보가 있습니다", isPresented: $showingCancelAlert) {
                Button("취소", role: .cancel) { }
                Button("닫기", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("수정 중인 내용이 모두 사라집니다. 닫으시겠습니까?")
            }
            .onAppear {
                setupInitialValues()
                fetchAddressIfNeeded()
            }
        }
    }
    
    private func makeRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: title == "메모" ? .top : .center, spacing: 12) {
            Text(title)
                .font(.body)
                .frame(width: 80, alignment: .leading)
                .padding(.top, title == "메모" ? 8 : 0)
            
            content()
        }
    }
    
    private func setupInitialValues() {
        if let shape = originalShape {
            title = shape.title
            address = shape.address ?? ""
            radius = String(format: "%.0f", shape.radius ?? 200)
            memo = shape.memo ?? ""
            startDate = shape.startedAt
            endDate = shape.expireDate ?? Date()
            coordinateText = shape.baseCoordinate.formattedCoordinate
        } else {
            coordinateText = coordinate.formattedCoordinate
            // 이전 설정값 불러오기
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
            if let lastStart = UserDefaults.standard.object(forKey: lastStartDateKey) as? Date {
                startDate = lastStart
            }
            if let lastEnd = UserDefaults.standard.object(forKey: lastEndDateKey) as? Date {
                endDate = lastEnd
            }
        }
        validateCoordinate(coordinateText)
    }
    
    private func validateCoordinate(_ input: String) {
        if let newCoordinate = Coordinate.parse(input) {
            coordinateValidation = "유효한 좌표 형식입니다"
            isCoordinateValid = true
            coordinateText = newCoordinate.formattedCoordinate
        } else {
            coordinateValidation = "잘못된 좌표 형식입니다"
            isCoordinateValid = false
        }
    }
    
    private func updateDates() {
        if isDateOnly {
            let calendar = Calendar.current
            var startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
            startComponents.hour = 0
            startComponents.minute = 0
            if let newStart = calendar.date(from: startComponents) {
                startDate = newStart
            }
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
            endComponents.hour = 23
            endComponents.minute = 59
            if let newEnd = calendar.date(from: endComponents) {
                endDate = newEnd
            }
        }
    }
    
    private func fetchAddressIfNeeded() {
        if address.isEmpty {
            NaverGeocodingService.shared.fetchAddress(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let fetchedAddress):
                        address = fetchedAddress
                    case .failure:
                        address = "주소를 찾을 수 없음"
                    }
                }
            }
        }
    }
    
    private func hasChanges() -> Bool {
        guard let original = originalShape else { return false }
        
        return title != original.title ||
               address != (original.address ?? "") ||
               memo != (original.memo ?? "") ||
               Double(radius) != original.radius ||
               startDate != original.startedAt ||
               endDate != (original.expireDate ?? Date())
    }
    
    private func saveShape() {
        let newShape = PlaceShape(
            id: originalShape?.id ?? UUID(),
            title: title.isEmpty ? "새 도형" : title,
            shapeType: .circle,
            baseCoordinate: coordinate,
            radius: Double(radius) ?? 200,
            memo: memo.isEmpty ? nil : memo,
            address: address.isEmpty ? nil : address,
            expireDate: endDate,
            startedAt: startDate,
            color: ColorManager.shared.defaultColor.rawValue
        )
        
        // 날짜 값 저장
        UserDefaults.standard.set(startDate, forKey: lastStartDateKey)
        UserDefaults.standard.set(endDate, forKey: lastEndDateKey)
        
        if originalShape != nil {
            // 기존 도형 수정
            store.updateShape(newShape)
        } else {
            // 새로운 도형 추가
            store.addShape(newShape)
        }
        
        onAdd?(newShape)
        
        // UI 갱신을 위한 Notification 발송
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
    }
}

#Preview {
    ShapeEditView(
        coordinate: Coordinate(latitude: 37.5331, longitude: 126.6342),
        onAdd: { _ in }
    )
}
