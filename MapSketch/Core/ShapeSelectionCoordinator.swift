import Foundation
import CoreLocation

final class ShapeSelectionCoordinator {
    static let shared = ShapeSelectionCoordinator()
    private init() {}

    static let shapeSelectedOnList = Notification.Name("shapeSelectedOnList")
    static let shapeSelectedOnMap = Notification.Name("shapeSelectedOnMap")

    func selectShapeOnList(_ shape: PlaceShape) {
        NotificationCenter.default.post(name: Self.shapeSelectedOnList, object: shape)
    }

    func selectShapeOnMap(_ shape: PlaceShape) {
        NotificationCenter.default.post(name: Self.shapeSelectedOnMap, object: shape)
    }
} 