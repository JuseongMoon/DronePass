////
////  SavedBottomSheetViewModel.swift
////  DronePass
////
////  Created by 문주성 on 5/13/25.
////
//
//
//import Foundation
//import Combine
//import UIKit
//
//// ✅ 여기에서만 선언!
//protocol SavedBottomSheetDelegate: AnyObject {
//    func savedBottomSheetDidDismiss()
//}
//
//final class SavedBottomSheetViewModel {
//    @Published private(set) var shapes: [PlaceShape] = []
//    private var cancellables = Set<AnyCancellable>()
//
//    init() {
//        PlaceShapeStore.shared.$shapes
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] shapes in
//                // 제목 기준으로 정렬
//                self?.shapes = shapes.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
//            ㅁ}
//            .store(in: &cancellables)
//    }
//
//    func loadData() {
//        // 최초 실행 시 데이터를 PlaceShapeStore에서 불러옴
//        self.shapes = PlaceShapeStore.shared.shapes.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
//    }
//
//    func addShape(_ shape: PlaceShape) {
//        PlaceShapeStore.shared.addShape(shape)
//    }
//
//    func removeShape(at indexPath: IndexPath) {
//        let shape = shapes[indexPath.row]
//        PlaceShapeStore.shared.removeShape(id: shape.id)
//    }
//}
