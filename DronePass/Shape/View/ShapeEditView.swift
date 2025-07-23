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
                .onChange(of: text) { recalculateHeight() }
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

// 기본 정보 섹션
struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var coordinateText: String
    @Binding var address: String
    @Binding var radius: String
    let onCoordinateTap: () -> Void
    let onAddressTap: () -> Void
    
    var body: some View {
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
            Button(action: onCoordinateTap) {
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
            Button(action: onAddressTap) {
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
    }
}

// 날짜 섹션
struct DateSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isDateOnly: Bool
    @Binding var showingStartDatePicker: Bool
    @Binding var showingEndDatePicker: Bool
    let isIPhone12: Bool
    let dateFormatterDateOnly: DateFormatter
    let dateFormatterDateTime: DateFormatter
    let dateOnlyKey: String
    let onDateOnlyChange: () -> Void
    
    var body: some View {
        Section {
            // 시작일
            Group {
                if isIPhone12 {
                    Button(action: { showingStartDatePicker = true }) {
                        HStack {
                            Text("시작일")
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Text(startDate, formatter: isDateOnly ? dateFormatterDateOnly : dateFormatterDateTime)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 30)
                    .sheet(isPresented: $showingStartDatePicker) {
                        DateTimeSelectionView(selectedDate: $startDate, isDateOnly: isDateOnly, title: "시작일 선택")
                    }
                    .onChange(of: startDate) { oldValue, newValue in
                        if endDate < newValue {
                            endDate = newValue
                        }
                    }
                } else {
                    DatePicker("시작일", selection: $startDate, displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                        .onChange(of: startDate) { oldValue, newValue in
                            if endDate < newValue {
                                endDate = newValue
                            }
                        }
                        .frame(height: 30)
                        .bold()
                }
            }

            
            // 종료일
            Group {
                if isIPhone12 {
                    Button(action: { showingEndDatePicker = true }) {
                        HStack {
                            Text("종료일")
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Text(endDate, formatter: isDateOnly ? dateFormatterDateOnly : dateFormatterDateTime)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: 30)
                    .sheet(isPresented: $showingEndDatePicker) {
                        DateTimeSelectionView(selectedDate: $endDate, isDateOnly: isDateOnly, title: "종료일 선택")
                    }
                } else {
                    DatePicker("종료일", selection: $endDate, in: startDate..., displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute])
                        .frame(height: 30)
                        .bold()
                }
            }

            
            // 날짜 설정
            Toggle("일단위 입력", isOn: $isDateOnly)
                .onChange(of: isDateOnly) { newValue in
                    UserDefaults.standard.set(newValue, forKey: dateOnlyKey)
                    onDateOnlyChange()
                }
                .frame(height: 30)
                .bold()
        }
    }
}

// 메모 섹션
struct MemoSection: View {
    @Binding var memo: String
    
    var body: some View {
        Section {
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
}

struct ShapeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ShapeEditViewModel
    @FocusState private var isFocused: Bool
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    @State private var showingCoordinateInput = false
    @State private var showingAddressSearch = false
    @State private var showingCancelAlert = false
    @State private var selectedDetent: PresentationDetent = .large

    init(coordinate: CoordinateManager?, onAdd: ((ShapeModel) -> Void)? = nil, originalShape: ShapeModel? = nil) {
        _viewModel = StateObject(wrappedValue: ShapeEditViewModel(coordinate: coordinate, onAdd: onAdd, originalShape: originalShape))
    }
    
    var body: some View {
        NavigationView {
            Form {
                BasicInfoSection(
                    title: $viewModel.title,
                    coordinateText: $viewModel.coordinateText,
                    address: $viewModel.address,
                    radius: $viewModel.radius,
                    onCoordinateTap: { showingCoordinateInput = true },
                    onAddressTap: { showingAddressSearch = true }
                )
                DateSection(
                    startDate: $viewModel.startDate,
                    endDate: $viewModel.endDate,
                    isDateOnly: $viewModel.isDateOnly,
                    showingStartDatePicker: $showingStartDatePicker,
                    showingEndDatePicker: $showingEndDatePicker,
                    isIPhone12: UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2532,
                    dateFormatterDateOnly: {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        return formatter
                    }(),
                    dateFormatterDateTime: {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        return formatter
                    }(),
                    dateOnlyKey: "isDateOnlyMode",
                    onDateOnlyChange: { viewModel.updateDates() }
                )
                MemoSection(memo: $viewModel.memo)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        if viewModel.hasChanges() {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.saveShape {
                            dismiss()
                        }
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .alert("수정 중인 정보가 있습니다", isPresented: $showingCancelAlert) {
                Button("취소", role: .cancel) { }
                Button("닫기", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("수정 중인 내용이 모두 사라집니다. 닫으시겠습니까?")
            }
            .alert("입력 오류", isPresented: $viewModel.showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showingAddressSearch) {
                SearchAddressView(
                    onSelectAddress: { address in
                        viewModel.address = address.roadAddress
                        if let coordinate = address.coordinate {
                            viewModel.coordinate = CoordinateManager(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            viewModel.coordinateText = viewModel.coordinate?.formattedCoordinate ?? ""
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
                        viewModel.coordinate = newCoordinate
                        viewModel.coordinateText = newCoordinate.formattedCoordinate
                        viewModel.address = newAddress
                    }
                )
                .interactiveDismissDisabled()
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.85)])
                .presentationContentInteraction(.scrolls)
            }
            .onAppear {
                viewModel.setupInitialValues()
            }
        }
    }
}

#Preview {
    ShapeEditView(
        coordinate: CoordinateManager(latitude: 0, longitude: 0),
        onAdd: { _ in }
    )
}

