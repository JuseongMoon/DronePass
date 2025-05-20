import Foundation
import Combine

// MARK: - Delegate Protocol
protocol SavedBottomSheetDelegate: AnyObject {
    func savedBottomSheetDidDismiss()
}

// MARK: - View Model
final class SavedBottomSheetViewModel {
    // MARK: - Published Properties
    @Published private(set) var shapes: [PlaceShape] = []
    
    // MARK: - Dependencies
    weak var delegate: SavedBottomSheetDelegate?
    
    // MARK: - Public Methods
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