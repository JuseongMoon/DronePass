//
//  PlaceShapeStore.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

import Foundation

public final class PlaceShapeStore {
    public static let shared = PlaceShapeStore()
    @Published public private(set) var shapes: [PlaceShape] = []
    private let storage = JSONPlaceShapeStorage.shared

    private init() {
        self.shapes = storage.loadShapes()
    }

    public func addShape(_ shape: PlaceShape) {
        shapes.append(shape)
        save()
    }

    public func removeShape(id: UUID) {
        shapes.removeAll { $0.id == id }
        save()
    }

    private func save() {
        storage.saveShapes(shapes)
    }
}
