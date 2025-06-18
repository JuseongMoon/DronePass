////
////  SavedBottomSheetViewModel.swift
////  DronePass
////
////  Created by 문주성 on 5/13/25.
////
//
//// 역할: 저장된 도형 목록 바텀시트의 뷰모델
//// 연관기능: 도형 데이터 관리, 바텀시트 닫기, 데이터 로드
//
//import Foundation // Foundation 프레임워크를 가져옵니다. (기본적인 데이터 타입과 기능을 사용하기 위함)
//import Combine // Combine 프레임워크를 가져옵니다. (반응형 프로그래밍을 위한 프레임워크)
//
//// MARK: - Delegate Protocol
//protocol SavedBottomSheetDelegate: AnyObject { // 저장된 도형 목록을 보여주는 바텀 시트의 델리게이트 프로토콜입니다.
//    func savedBottomSheetDidDismiss() // 바텀 시트가 닫힐 때 호출되는 메서드입니다.
//}
//
//// MARK: - View Model
//final class SavedBottomSheetViewModel { // 저장된 도형 목록을 관리하는 뷰 모델 클래스입니다.
//    // MARK: - Published Properties
//    @Published private(set) var shapes: [PlaceShape] = [] // 저장된 도형들의 배열입니다. @Published로 선언되어 변경 시 자동으로 UI가 업데이트됩니다.
//    
//    // MARK: - Dependencies
//    weak var delegate: SavedBottomSheetDelegate? // 델리게이트 참조를 저장하는 프로퍼티입니다. weak로 선언하여 순환 참조를 방지합니다.
//    
//    // MARK: - Public Methods
//    func loadData() { // 저장된 도형 데이터를 로드하는 메서드입니다.
//        shapes = SampleShapeLoader.loadSampleShapes() // 샘플 도형 데이터를 로드합니다.
//    }
//    
//    func dismissSheet() { // 바텀 시트를 닫는 메서드입니다.
//        delegate?.savedBottomSheetDidDismiss() // 델리게이트를 통해 바텀 시트가 닫혔음을 알립니다.
//    }
//    
//    func didSelectShape(at indexPath: IndexPath) { // 도형이 선택되었을 때 호출되는 메서드입니다.
//        // TODO: 선택된 도형 처리 로직 구현
//    }
//} 
