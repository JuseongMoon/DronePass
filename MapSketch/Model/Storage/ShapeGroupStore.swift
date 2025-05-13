//
//  ShapeGroupStore.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//


import Foundation
import Combine

/// ShapeGroup 데이터를 관리하는 싱글톤 스토어
public final class ShapeGroupStore: ObservableObject {
    /// 기본 스토어 인스턴스 (JSONStorage 사용)
    public static let shared = ShapeGroupStore(storage: JSONStorage())

    /// 공개된 그룹 리스트
    @Published private(set) var groups: [ShapeGroup] = []
    private let storage: ShapeGroupStorage
    private var cancellables = Set<AnyCancellable>()

    /// DI 방식으로 저장소 구현체 주입
    public init(storage: ShapeGroupStorage) {
        self.storage = storage
        load()

        // groups가 변경되면 자동 저장 (디바운스 적용)
        $groups
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    // MARK: - 그룹 관리

    public func addGroup(_ group: ShapeGroup) {
        groups.append(group)
    }

    public func removeGroup(id: UUID) {
        groups.removeAll { $0.id == id }
    }

    public func updateGroup(_ updated: ShapeGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == updated.id }) else { return }
        groups[idx] = updated
    }

    // MARK: - 도형 관리

    public func addShape(_ shape: PlaceShape, to groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].shapes.append(shape)
    }

    public func removeShape(shapeId: UUID, from groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].shapes.removeAll { $0.id == shapeId }
    }

    // MARK: - 저장 & 불러오기

    private func save() {
        do {
            try storage.saveGroups(groups)
        } catch {
            print("⚠️ 저장 실패: \(error)")
        }
    }

    private func load() {
        do {
            groups = try storage.loadGroups()
        } catch {
            print("⚠️ 불러오기 실패 또는 최초 실행: \(error)")
            groups = []
        }
    }
}
