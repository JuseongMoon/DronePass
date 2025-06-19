//
//  PlaceShapeStore.swift
//  DronePass
//
//  Created by 문주성 on 5/19/25.
//

// 역할: 도형 데이터의 메모리 저장 및 관리
// 연관기능: 도형 추가, 삭제, 저장, 불러오기

import Foundation
import Combine
import SwiftUI

// PlaceShape 모델 직접 import
//import DronePass

final class PlaceShapeStore: ObservableObject {
    static let shared = PlaceShapeStore()
    @Published var shapes: [PlaceShape] = []
    @Published var selectedShapeID: UUID? = nil

    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let shapesFileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        // Document 디렉토리 설정
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        shapesFileURL = documentsDirectory.appendingPathComponent("shapes.json")
        
        // 초기 데이터 로드
        loadShapes()
    }
    
    func deleteShape(_ shape: PlaceShape) {
        if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes.remove(at: index)
        }
    }
    
    private func loadShapes() {
        do {
            if fileManager.fileExists(atPath: shapesFileURL.path) {
                let data = try Data(contentsOf: shapesFileURL)
                shapes = try decoder.decode([PlaceShape].self, from: data)
            } else {
                // 파일이 없으면 빈 배열로 시작
                shapes = []
                // 빈 배열을 파일로 저장
                try saveShapes()
            }
        } catch {
            print("도형 데이터 로드 실패: \(error)")
            shapes = []
        }
    }
    
    private func saveShapes() throws {
        let data = try encoder.encode(shapes)
        try data.write(to: shapesFileURL)
    }
    
    public func addShape(_ shape: PlaceShape) {
        shapes.append(shape)
        do {
            try saveShapes()
        } catch {
            print("도형 추가 실패: \(error)")
        }
    }
    
    public func removeShape(id: UUID) {
        shapes.removeAll { $0.id == id }
        do {
            try saveShapes()
        } catch {
            print("도형 삭제 실패: \(error)")
        }
    }

    
    public func updateAllShapesColor(to newColor: String) {

        
        do {
            // 1. 파일에서 도형 전체 불러오기
            let data = try Data(contentsOf: shapesFileURL)
            var loadedShapes = try decoder.decode([PlaceShape].self, from: data)
            // 2. 모든 도형의 color 필드 변경
            for i in 0..<loadedShapes.count {
                loadedShapes[i].color = newColor
            }
            // 3. 파일에 저장
            let newData = try encoder.encode(loadedShapes)
            try newData.write(to: shapesFileURL)
            // 4. 메모리의 shapes도 동기화 (여기서 @Published가 UI에 반영)
            self.shapes = loadedShapes
        } catch {
            print("모든 도형 색상 일괄 변경 실패: \(error)")
        }
    }
    
    public func updateShape(_ shape: PlaceShape) {
        if let idx = shapes.firstIndex(where: { $0.id == shape.id }) {
            var newShapes = shapes
            newShapes[idx] = shape
            shapes = newShapes // 배열 자체를 새로 할당해야 @Published가 동작
            do {
                try saveShapes()
            } catch {
                print("도형 수정 실패: \(error)")
            }
        }
    }
    
    public func deleteExpiredShapes() {
        let now = Date()
        let filtered = shapes.filter { shape in
            if let expire = shape.expireDate {
                return expire >= now
            }
            return true
        }
        self.shapes = filtered
        do {
            try saveShapes()
        } catch {
            print("만료 도형 삭제 실패: \(error)")
        }
        // UI 갱신을 위해 Notification 전송
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
    }
}

extension PlaceShapeStore {
    /// 저장된 모든 도형의 색상을 새로운 색상(hex)으로 변경하고 저장/갱신

    /// 특정 id의 도형을 반환
    func getShape(id: UUID) -> PlaceShape? {
        return shapes.first(where: { $0.id == id })
    }
}
