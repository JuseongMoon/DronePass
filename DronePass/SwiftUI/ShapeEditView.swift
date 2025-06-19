//
//  ShapeEditView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
import Combine


// 동적으로 높이가 변하는 TextEditor
struct GrowingTextEditor: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var minHeight: CGFloat = 40
    var maxHeight: CGFloat = 300

    @State private var dynamicHeight: CGFloat = 40

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
//                .frame(height: dynamicHeight)
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(UIColor.systemGray3))
                )
                .onChange(of: text) { _ in
                    recalculateHeight()
                }
                .onAppear {
                    recalculateHeight()
                }

            if text.isEmpty {
                Text("메모를 입력하세요")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
    }

    private func recalculateHeight() {
        let size = CGSize(width: UIScreen.main.bounds.width - 140, height: .infinity) // 타이틀 뷰 폭 고려
        let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]
        let estimatedHeight = NSString(string: text.isEmpty ? " " : text)
            .boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).height
        dynamicHeight = min(max(estimatedHeight + 28, minHeight), maxHeight)
    }
}

// 동적으로 높이가 변하는 AddressField
struct AddressField: View {
    let text: String
    let placeholder: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    Text(text)
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .background(Color(UIColor.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(UIColor.systemGray3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ShapeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = PlaceShapeStore.shared
    @FocusState private var isFocused: Bool
    @State private var showingAddressSearch = false
    @State private var showingCoordinateInput = false
    
    @State var coordinate: Coordinate
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
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                            .focused($isFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(UIColor.systemGray3))
                            )
                    }
                    
                    // 좌표
                    makeRow(title: "좌표") {
                        AddressField(
                            text: coordinateText,
                            placeholder: "터치해서 좌표를 입력하세요",
                            action: { showingCoordinateInput = true }
                        )
                    }
                    
                    // 주소
                    makeRow(title: "주소") {
                        AddressField(
                            text: address,
                            placeholder: "터치해서 주소를 검색하세요",
                            action: { showingAddressSearch = true }
                        )
                    }
                    
                    // 반경
                    makeRow(title: "반경(m)") {
                        TextField("미터 단위로 입력해주세요", text: $radius)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(UIColor.systemGray3))
                            )
                    }
                    
                    
                    // 시작일
                    makeRow(title: "시작일") {
                        DatePicker("", selection: $startDate, displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: startDate) { _ in
                                if endDate < startDate {
                                    endDate = startDate
                                }
                            }
                    }
                    
                    // 종료일
                    makeRow(title: "종료일") {
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                        GrowingTextEditor(text: $memo, isFocused: $isFocused, minHeight: 40, maxHeight: 300)
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
            .alert("입력 오류", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onTapGesture {
                isFocused = false
            }
            .onAppear {
                setupInitialValues()
            }
            .sheet(isPresented: $showingAddressSearch) {
                SearchingAddressView(
                    onSelectAddress: { address in
                        self.address = address.roadAddress
                        if let coordinate = address.coordinate {
                            selectedLatitude = coordinate.latitude
                            selectedLongitude = coordinate.longitude
                            
                            // 선택된 좌표로 coordinate 업데이트
                            self.coordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            coordinateText = self.coordinate.formattedCoordinate
                        }
                    }
                )
            }
            .sheet(isPresented: $showingCoordinateInput) {
                CoordinateView(
                    onSelectCoordinate: { newCoordinate, newAddress in
                        self.coordinate = newCoordinate
                        self.coordinateText = newCoordinate.formattedCoordinate
                        self.address = newAddress
                    }
                )
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
            // 이전 설정값 불러오기
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
            if let lastStart = UserDefaults.standard.object(forKey: lastStartDateKey) as? Date {
                startDate = lastStart
            }
            if let lastEnd = UserDefaults.standard.object(forKey: lastEndDateKey) as? Date {
                endDate = lastEnd
            }
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
        // 좌표와 주소가 모두 비어있는지 확인
        if coordinateText.isEmpty && address.isEmpty {
            alertMessage = "좌표나 주소를 반드시 입력해주세요!"
            showingAlert = true
            return
        }
        
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
        
        // 수정 완료 후 화면 닫기
        dismiss()
    }
}

#Preview {
    ShapeEditView(
        coordinate: Coordinate(latitude: 0, longitude: 0),
        onAdd: { _ in }
    )
}

