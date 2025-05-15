//
//  ShapeGroupStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import Foundation

public protocol ShapeGroupStorage {
    func loadGroups() throws -> [ShapeGroup]
    func saveGroups(_ groups: [ShapeGroup]) throws
    func resetToSample() throws
}


public final class ShapeGroupStore: ObservableObject {
    public static let shared = ShapeGroupStore()

    @Published public private(set) var groups: [ShapeGroup]
    private let storage: ShapeGroupStorage

    private init(storage: ShapeGroupStorage = JSONStorage.shared) {
        self.storage = storage
        do {
            self.groups = try storage.loadGroups()
        } catch {
            print("[ShapeGroupStore] load error: \(error)")
            self.groups = []
        }
    }

    // MARK: - CRUD

    public func addGroup(_ group: ShapeGroup) {
        groups.append(group)
        save()
    }

    public func removeGroup(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    public func updateGroup(_ updated: ShapeGroup) {
        if let idx = groups.firstIndex(where: { $0.id == updated.id }) {
            groups[idx] = updated
            save()
        }
    }

    public func addShape(_ shape: PlaceShape, to groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].shapes.append(shape)
        save()
    }

    public func removeShape(shapeId: UUID, from groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].shapes.removeAll { $0.id == shapeId }
        save()
    }

    private func save() {
        do {
            try storage.saveGroups(groups)
        } catch {
            print("[ShapeGroupStore] save error: \(error)")
        }
    }

    public func resetToSample() {
        do {
            try (storage as? JSONStorage)?.resetToSample()
            groups = try storage.loadGroups()
        } catch {
            print("[ShapeGroupStore] reset error: \(error)")
        }
    }
}
