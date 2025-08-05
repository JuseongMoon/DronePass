//
//  ShapeSortingManager.swift
//  DronePass
//
//  Created by 문주성 on 7/29/25.
//

import Foundation
import SwiftUI

// ShapeModel을 사용하기 위한 import
import CoreLocation

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case title = "제목순"
    case dateCreated = "생성일순"
    case flightStartDate = "비행시작일순"
    case flightEndDate = "비행종료일순"
    
    var icon: String {
        switch self {
        case .title: return "textformat"
        case .dateCreated: return "calendar"
        case .flightStartDate: return "airplane.departure"
        case .flightEndDate: return "airplane.arrival"
        }
    }
}

// MARK: - Sort Direction
enum SortDirection: String, CaseIterable {
    case ascending = "오름차순"
    case descending = "내림차순"
    
    var icon: String {
        switch self {
        case .ascending: return "arrow.down"
        case .descending: return "arrow.up"
        }
    }
    
    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

// MARK: - Shape Sorting Manager
final class ShapeSortingManager: ObservableObject {
    static let shared = ShapeSortingManager()
    
    // 초기화 중 저장 방지를 위한 플래그
    private var isInitializing = false
    
    @Published var selectedSortOption: SortOption = .title {
        didSet {
            if !isInitializing {
                saveSortSettings()
            }
        }
    }
    @Published var sortDirection: SortDirection = .ascending {
        didSet {
            if !isInitializing {
                saveSortSettings()
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let selectedSortOption = "ShapeSortingManager.selectedSortOption"
        static let sortDirection = "ShapeSortingManager.sortDirection"
    }
    
    private init() {
        isInitializing = true
        loadSortSettings()
        isInitializing = false
    }
    
    // MARK: - UserDefaults Management
    private func saveSortSettings() {
        UserDefaults.standard.set(selectedSortOption.rawValue, forKey: UserDefaultsKeys.selectedSortOption)
        UserDefaults.standard.set(sortDirection.rawValue, forKey: UserDefaultsKeys.sortDirection)
        print("💾 ShapeSortingManager: 정렬 설정 저장 - \(selectedSortOption.rawValue), \(sortDirection.rawValue)")
    }
    
    private func loadSortSettings() {
        // 정렬 옵션 로드
        if let sortOptionString = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedSortOption),
           let sortOption = SortOption(rawValue: sortOptionString) {
            selectedSortOption = sortOption
        }
        
        // 정렬 방향 로드
        if let sortDirectionString = UserDefaults.standard.string(forKey: UserDefaultsKeys.sortDirection),
           let sortDirection = SortDirection(rawValue: sortDirectionString) {
            self.sortDirection = sortDirection
        }
        
        print("📱 ShapeSortingManager: 정렬 설정 로드 - \(selectedSortOption.rawValue), \(sortDirection.rawValue)")
    }
    
    // MARK: - Sorting Logic
    func sortShapes(_ shapes: [ShapeModel]) -> [ShapeModel] {
        // [디버그] flightEndDate 값 검증 로그
        print("[검증] 정렬 대상 도형 목록:")
        for shape in shapes {
            print("- \(shape.title): flightStartDate=\(shape.flightStartDate), flightEndDate=\(String(describing: shape.flightEndDate))")
        }
        let sortedShapes = shapes.sorted { first, second in
            // 주 정렬 기준에 따른 비교
            let primaryComparison: ComparisonResult
            
            switch selectedSortOption {
            case .title:
                primaryComparison = first.title.localizedCompare(second.title)
            case .dateCreated:
                primaryComparison = first.createdAt.compare(second.createdAt)
            case .flightStartDate:
                print("[정렬비교] \(first.title): \(first.flightStartDate) vs \(second.title): \(second.flightStartDate)")
                primaryComparison = first.flightStartDate.compare(second.flightStartDate)
                print("[정렬결과] 주정렬: \(first.title) vs \(second.title) = \(primaryComparison.rawValue), 방향=\(sortDirection.rawValue)")
            case .flightEndDate:
                let firstEndDate = first.flightEndDate ?? Date.distantFuture
                let secondEndDate = second.flightEndDate ?? Date.distantFuture
                print("[정렬비교] \(first.title): \(String(describing: first.flightEndDate)) vs \(second.title): \(String(describing: second.flightEndDate))")
                primaryComparison = firstEndDate.compare(secondEndDate)
                print("[정렬결과] 주정렬: \(first.title) vs \(second.title) = \(primaryComparison.rawValue), 방향=\(sortDirection.rawValue)")
            }
            
            // 주 정렬 기준이 같지 않으면 그 결과를 반환
            if primaryComparison != .orderedSame {
                let result = sortDirection == .ascending ? 
                    (primaryComparison == .orderedAscending) : 
                    (primaryComparison == .orderedDescending)
                print("[최종결과] 주정렬로 결정: \(first.title) vs \(second.title) = \(result)")
                return result
            }
            
            print("[보조정렬] 주정렬이 같음, 보조정렬 적용: \(first.title) vs \(second.title)")
            // 보조 정렬 기준 적용
            let secondaryComparison: ComparisonResult
            
            switch selectedSortOption {
            case .title:
                // 제목순의 경우: 비행시작일순 → 주소순
                secondaryComparison = first.flightStartDate.compare(second.flightStartDate)
                if secondaryComparison != .orderedSame {
                    let result = sortDirection == .ascending ? 
                        (secondaryComparison == .orderedAscending) : 
                        (secondaryComparison == .orderedDescending)
                    print("[보조결과] 비행시작일순: \(first.title) vs \(second.title) = \(result)")
                    return result
                }
                // 마지막: 주소순
                let firstAddress = first.address ?? ""
                let secondAddress = second.address ?? ""
                let addressComparison = firstAddress.localizedCompare(secondAddress)
                let result = sortDirection == .ascending ? 
                    (addressComparison == .orderedAscending) : 
                    (addressComparison == .orderedDescending)
                print("[보조결과] 주소순: \(first.title) vs \(second.title) = \(result)")
                return result
            case .dateCreated, .flightStartDate, .flightEndDate:
                // 생성일순, 비행시작일순, 비행종료일순의 경우: 제목순 → 주소순
                let titleComparison = first.title.localizedCompare(second.title)
                if titleComparison != .orderedSame {
                    let result = sortDirection == .ascending ? 
                        (titleComparison == .orderedAscending) : 
                        (titleComparison == .orderedDescending)
                    print("[보조결과] 제목순: \(first.title) vs \(second.title) = \(result)")
                    return result
                }
                // 마지막: 주소순
                let firstAddress = first.address ?? ""
                let secondAddress = second.address ?? ""
                let addressComparison = firstAddress.localizedCompare(secondAddress)
                let result = sortDirection == .ascending ? 
                    (addressComparison == .orderedAscending) : 
                    (addressComparison == .orderedDescending)
                print("[보조결과] 주소순: \(first.title) vs \(second.title) = \(result)")
                return result
            }
        }
        
        // [디버그] 정렬 결과 로그
        print("[검증] 정렬 결과:")
        for shape in sortedShapes {
            print("- \(shape.title): flightStartDate=\(shape.flightStartDate), flightEndDate=\(String(describing: shape.flightEndDate))")
        }
        return sortedShapes
    }
    
    // MARK: - Active and Expired Shapes with Sorting
    func getActiveShapes(_ allShapes: [ShapeModel]) -> [ShapeModel] {
        let activeShapes = allShapes.filter { shape in
            guard let endDate = shape.flightEndDate else { return true }
            return endDate > Date()
        }
        return sortShapes(activeShapes)
    }
    
    func getExpiredShapes(_ allShapes: [ShapeModel]) -> [ShapeModel] {
        let expiredShapes = allShapes.filter { shape in
            guard let endDate = shape.flightEndDate else { return false }
            return endDate <= Date()
        }
        return sortShapes(expiredShapes)
    }
    
    // MARK: - Sort Option Management
    func setSortOption(_ option: SortOption) {
        selectedSortOption = option
    }
    
    func toggleSortDirection() {
        sortDirection = sortDirection == .ascending ? .descending : .ascending
    }
    
    func resetToDefault() {
        selectedSortOption = .title
        sortDirection = .ascending
    }
    
    // MARK: - Current Sort Option Display
    var currentSortOptionDisplay: String {
        return "\(selectedSortOption.rawValue) \(sortDirection.rawValue)"
    }
}
