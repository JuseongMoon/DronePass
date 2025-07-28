//
//  ShapeEditViewModel.swift
//  DronePass
//
//  Created by 문주성 on 7/22/25.
//

import Foundation
import Combine

final class ShapeEditViewModel: ObservableObject {
    // 입력값 상태
    @Published var title: String = ""
    @Published var address: String = ""
    @Published var radius: String = ""
    @Published var memo: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var isDateOnly: Bool = false
    @Published var coordinateText: String = ""
    @Published var coordinate: CoordinateManager?
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""

    // 초기값 추적
    private var initialTitle: String = ""
    private var initialAddress: String = ""
    private var initialRadius: String = ""
    private var initialMemo: String = ""
    private var initialCoordinate: CoordinateManager?

    // 외부 의존성
    private let store = ShapeFileStore.shared
    var onAdd: ((ShapeModel) -> Void)?
    var originalShape: ShapeModel?

    // UserDefaults 키
    private let dateOnlyKey = "isDateOnlyMode"
    private let lastStartDateKey = "lastStartDate"
    private let lastEndDateKey = "lastEndDate"

    // MARK: - 초기화
    init(coordinate: CoordinateManager?, onAdd: ((ShapeModel) -> Void)? = nil, originalShape: ShapeModel? = nil) {
        self.coordinate = coordinate
        self.onAdd = onAdd
        self.originalShape = originalShape
        if let shape = originalShape {
            self.title = shape.title
            self.address = shape.address ?? ""
            self.radius = shape.radius != nil ? String(format: "%.0f", shape.radius!) : ""
            self.memo = shape.memo ?? ""
            self.startDate = shape.flightStartDate
            self.endDate = shape.flightEndDate ?? Date()
            self.coordinateText = coordinate?.formattedCoordinate ?? ""
            self.initialTitle = shape.title
            self.initialAddress = shape.address ?? ""
            self.initialRadius = shape.radius != nil ? String(format: "%.0f", shape.radius!) : ""
            self.initialMemo = shape.memo ?? ""
            self.initialCoordinate = coordinate
        } else {
            self.coordinateText = coordinate?.formattedCoordinate ?? ""
            self.initialCoordinate = coordinate
        }
        let isOriginalShapeTitleEmpty: Bool = (originalShape?.title.isEmpty ?? false)
        if isOriginalShapeTitleEmpty {
            self.address = originalShape?.address ?? ""
            self.initialAddress = originalShape?.address ?? ""
        }
    }

    // MARK: - 비즈니스 로직
    func setupInitialValues() {
        if let shape = originalShape, !shape.title.isEmpty {
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
        } else {
            isDateOnly = UserDefaults.standard.bool(forKey: dateOnlyKey)
            startDate = Date()
            endDate = Date()
        }
        if let coord = coordinate {
            self.coordinateText = coord.formattedCoordinate
        }
    }

    func updateDates() {
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

    func hasChanges() -> Bool {
        return title != initialTitle ||
               address != initialAddress ||
               radius != initialRadius ||
               memo != initialMemo ||
               coordinate != initialCoordinate
    }

    func saveShape(onComplete: @escaping () -> Void) {
        if coordinate == nil && address.isEmpty {
            alertMessage = "좌표나 주소를 반드시 입력해주세요!"
            showingAlert = true
            return
        }
        if radius.isEmpty {
            alertMessage = "반경을 반드시 입력해주세요!"
            showingAlert = true
            return
        }
        let addressToSave = address.isEmpty ? "해당 위치의 주소가 존재하지 않습니다" : address
        guard let finalCoordinate = coordinate else {
            alertMessage = "좌표가 설정되지 않았습니다."
            showingAlert = true
            return
        }
        let newShape = ShapeModel(
            id: originalShape?.id ?? UUID(),
            title: title.isEmpty ? "새 도형" : title,
            shapeType: .circle,
            baseCoordinate: finalCoordinate,
            radius: Double(radius) ?? 0,
            memo: memo.isEmpty ? nil : memo,
            address: addressToSave,
            createdAt: originalShape?.createdAt ?? Date(),
            deletedAt: originalShape?.deletedAt,
            flightStartDate: startDate,
            flightEndDate: endDate,
            color: ColorManager.shared.defaultColor.rawValue
        )
        UserDefaults.standard.set(startDate, forKey: lastStartDateKey)
        UserDefaults.standard.set(endDate, forKey: lastEndDateKey)
        if originalShape?.title.isEmpty ?? true {
            store.addShape(newShape)
        } else {
            store.updateShape(newShape)
        }
        onAdd?(newShape)
        // 알림은 ShapeRepository에서만 전송하도록 제거
        onComplete()
    }
}

