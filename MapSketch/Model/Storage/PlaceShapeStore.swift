//
//  PlaceShapeStore.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

// 역할: 도형 데이터의 메모리 저장 및 관리
// 연관기능: 도형 추가, 삭제, 저장, 불러오기

import Foundation // Foundation 프레임워크를 가져옵니다. (데이터 관리)

public final class PlaceShapeStore { // 도형 데이터를 메모리에 저장하고 관리하는 클래스입니다.
    public static let shared = PlaceShapeStore() // 싱글턴 인스턴스
    @Published public private(set) var shapes: [PlaceShape] = [] // 도형 목록을 저장하는 프로퍼티입니다.
    private let storage = JSONPlaceShapeStorage.shared // 파일 저장소 인스턴스

    private init() {
        self.shapes = storage.loadShapes() // 초기화 시 파일에서 도형 목록을 불러옵니다.
    }

    public func addShape(_ shape: PlaceShape) { // 도형을 추가하는 메서드입니다.
        shapes.append(shape)
        save()
    }

    public func removeShape(id: UUID) { // 도형을 삭제하는 메서드입니다.
        shapes.removeAll { $0.id == id }
        save()
    }

    private func save() { // 도형 목록을 파일에 저장하는 메서드입니다.
        storage.saveShapes(shapes)
    }
}
