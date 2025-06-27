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
    @State private var showingCoordinateInput = false
    @State private var showingAddressSearch = false
    @State private var selectedDetent: PresentationDetent = .large
    
    @State var coordinate: Coordinate?
    var onAdd: ((PlaceShape) -> Void)?
    var originalShape: PlaceShape?
    
    @State private var title: String = ""
    @State private var address: String = ""
    @State private var radius: String = ""
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
    
    // 초기값 추적을 위한 변수들
    @State private var initialTitle: String = ""
    @State private var initialAddress: String = ""
    @State private var initialRadius: String = ""
    @State private var initialMemo: String = ""
    @State private var initialCoordinate: Coordinate?
    
    private let dateOnlyKey = "isDateOnlyMode"
    private let lastStartDateKey = "lastStartDate"
    private let lastEndDateKey = "lastEndDate"

    init(coordinate: Coordinate?, onAdd: ((PlaceShape) -> Void)? = nil, originalShape: PlaceShape? = nil) {
        self._coordinate = State(initialValue: coordinate)
        self.onAdd = onAdd
        self.originalShape = originalShape
        
        // 초기값 설정
        if let shape = originalShape {
            self._title = State(initialValue: shape.title)
            self._address = State(initialValue: shape.address ?? "")
            self._radius = State(initialValue: shape.radius != nil ? String(format: "%.0f", shape.radius!) : "")
            self._memo = State(initialValue: shape.memo ?? "")
            self._startDate = State(initialValue: shape.startedAt)
            self._endDate = State(initialValue: shape.expireDate ?? Date())
            
            // coordinate가 nil이면 빈 문자열로 설정, 아니면 shape의 좌표 사용
            if let coord = coordinate {
                self._coordinateText = State(initialValue: coord.formattedCoordinate)
            } else {
                self._coordinateText = State(initialValue: "")
            }
            
            // 초기값 추적 변수 설정
            self._initialTitle = State(initialValue: shape.title)
            self._initialAddress = State(initialValue: shape.address ?? "")
            self._initialRadius = State(initialValue: shape.radius != nil ? String(format: "%.0f", shape.radius!) : "")
            self._initialMemo = State(initialValue: shape.memo ?? "")
            self._initialCoordinate = State(initialValue: coordinate)
        } else {
            // originalShape이 nil인 경우 (새로운 생성)
            if let coord = coordinate {
                self._coordinateText = State(initialValue: coord.formattedCoordinate)
            } else {
                self._coordinateText = State(initialValue: "")
            }
            
            // 초기값 추적 변수 설정 (새로운 생성 시 모두 빈 값)
            self._initialTitle = State(initialValue: "")
            self._initialAddress = State(initialValue: "")
            self._initialRadius = State(initialValue: "")
            self._initialMemo = State(initialValue: "")
            self._initialCoordinate = State(initialValue: coordinate)
        }
        
        // long press로 진입 시 주소만 업데이트
        if originalShape?.title.isEmpty ?? false { // nil coalescing
            self._address = State(initialValue: originalShape?.address ?? "")
            self._initialAddress = State(initialValue: originalShape?.address ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // 제목
                    HStack {
                        Text("제목")
                            .bold()
                        TextField("제목을 입력하세요", text: $title)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(height: 30)
                    
                    // 좌표
                    Button(action: { showingCoordinateInput = true }) {
                        HStack {
                            Text("좌표")
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Text(coordinateText.isEmpty ? "좌표를 입력하세요" : coordinateText)
                                .foregroundColor(coordinateText.isEmpty ? .gray : .primary)
                                .multilineTextAlignment(.trailing)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 30)
                    
                    // 주소
                    Button(action: { showingAddressSearch = true }) {
                        HStack {
                            Text("주소")
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Text(address.isEmpty ? "주소를 검색하세요" : address)
                                .foregroundColor(address.isEmpty ? .gray : .primary)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 30)
                    
                    // 반경
                    HStack {
                        Text("반경(m)")
                            .bold()
                        TextField("반경을 입력하세요", text: $radius)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(height: 30)
                }
                
                Section {
                    // 시작일
                    DatePicker("시작일", selection: $startDate, displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                        .onChange(of: startDate) { oldValue, newValue in
                            if endDate < newValue {
                                endDate = newValue
                            }
                        }
                        .frame(height: 30)
                        .bold()

                    
                    // 종료일
                    DatePicker("종료일", selection: $endDate, in: startDate..., displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                        .frame(height: 30)
                        .bold()

                    
                    // 날짜 설정
                    Toggle("일단위 입력", isOn: $isDateOnly)
                        .onChange(of: isDateOnly) { newValue in
                            UserDefaults.standard.set(newValue, forKey: dateOnlyKey)
                            updateDates()
                        }
                        .frame(height: 30)
                        .bold()

                }
                
                Section {
                    // 메모
                    VStack(alignment: .leading) {
                        Text("메모")
                            .bold()
                        TextEditor(text: $memo)
                            .frame(minHeight: 170)
                            .overlay(
                                Group {
                                    if memo.isEmpty {
                                        Text("메모를 입력하세요")
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
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
            .onTapGesture {
                hideKeyboard()
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
            .sheet(isPresented: $showingAddressSearch) {
                SearchingAddressView(
                    onSelectAddress: { address in
                        self.address = address.roadAddress
                        if let coordinate = address.coordinate {
                            selectedLatitude = coordinate.latitude
                            selectedLongitude = coordinate.longitude
                            self.coordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            coordinateText = self.coordinate?.formattedCoordinate ?? ""
                        }
                    }
                )
                .interactiveDismissDisabled()
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.85)])
                .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $showingCoordinateInput) {
                CoordinateView(
                    onSelectCoordinate: { newCoordinate, newAddress in
                        self.coordinate = newCoordinate
                        self.coordinateText = newCoordinate.formattedCoordinate
                        self.address = newAddress
                    }
                )
                .interactiveDismissDisabled()
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.85)])
                .presentationContentInteraction(.scrolls)
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func setupInitialValues() {
        if let shape = originalShape, !shape.title.isEmpty {
            // 기존 도형 '수정' 시에만 날짜 등을 설정
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
        } else {
            // '새로운' 도형 생성 시 (long press 포함)
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
            // 새로운 도형 생성 시에는 현재 시간을 기본값으로 사용
            startDate = Date()
            endDate = Date()
        }
        
        // 공통 좌표 설정 - coordinate가 nil이면 빈 문자열 유지
        if let coord = coordinate {
            self.coordinateText = coord.formattedCoordinate
        }
        // coordinate가 nil이면 coordinateText는 빈 문자열로 유지 (이미 초기화에서 설정됨)
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
        // 초기값과 현재값을 비교하여 실제 변경사항이 있는지 확인
        return title != initialTitle ||
               address != initialAddress ||
               radius != initialRadius ||
               memo != initialMemo ||
               coordinate != initialCoordinate
    }
    
    private func saveShape() {
        // 좌표와 주소가 모두 비어있는지 확인
        if coordinate == nil && address.isEmpty {
            alertMessage = "좌표나 주소를 반드시 입력해주세요!"
            showingAlert = true
            return
        }
        
        // 반경이 비어있는지 확인
        if radius.isEmpty {
            alertMessage = "반경을 반드시 입력해주세요!"
            showingAlert = true
            return
        }
        
        // 주소가 비어있으면 nil로 처리, 아니면 그대로 저장 (실패 메시지도 포함)
        let addressToSave = address.isEmpty ? "해당 위치의 주소가 존재하지 않습니다" : address
        
        // 좌표가 nil이면 저장하지 않음 (이론상 위에서 걸러짐)
        guard let finalCoordinate = coordinate else {
            alertMessage = "좌표가 설정되지 않았습니다."
            showingAlert = true
            return
        }
        
        let newShape = PlaceShape(
            id: originalShape?.id ?? UUID(),
            title: title.isEmpty ? "새 도형" : title,
            shapeType: .circle,
            baseCoordinate: finalCoordinate,
            radius: Double(radius) ?? 0,
            memo: memo.isEmpty ? nil : memo,
            address: addressToSave,
            expireDate: endDate,
            startedAt: startDate,
            color: ColorManager.shared.defaultColor.rawValue
        )
        
        // 날짜 값 저장
        UserDefaults.standard.set(startDate, forKey: lastStartDateKey)
        UserDefaults.standard.set(endDate, forKey: lastEndDateKey)
        
        // originalShape의 title이 비어있으면 '새 도형 추가', 아니면 '기존 도형 수정'
        if originalShape?.title.isEmpty ?? true {
            store.addShape(newShape)
        } else {
            store.updateShape(newShape)
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

