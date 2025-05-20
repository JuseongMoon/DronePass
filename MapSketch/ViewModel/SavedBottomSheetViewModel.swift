import Foundation
import Combine

// ✅ 여기에서만 선언!
protocol SavedBottomSheetDelegate: AnyObject {
    func savedBottomSheetDidDismiss()
}

final class SavedBottomSheetViewModel {
    @Published private(set) var shapes: [PlaceShape] = []
    weak var delegate: SavedBottomSheetDelegate?
    
    func loadData() {
        shapes = SampleShapeLoader.loadSampleShapes()
    }
    
    func dismissSheet() {
        delegate?.savedBottomSheetDidDismiss()
    }
    
    func didSelectShape(at indexPath: IndexPath) {
        // TODO: 선택된 도형 처리 로직 구현
    }
}