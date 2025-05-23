import Foundation
import Combine

final class SavedBottomSheetViewModel {
    @Published private(set) var shapes: [PlaceShape] = []
    private let store = PlaceShapeStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        store.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shapes in
                self?.shapes = shapes
            }
            .store(in: &cancellables)
    }
    
    func removeShape(at index: Int) {
        guard index < shapes.count else { return }
        let shape = shapes[index]
        store.removeShape(id: shape.id)
    }
} 