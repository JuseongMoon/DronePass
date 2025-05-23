//
//  PlaceShapeStore.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

// 역할: 도형 데이터의 메모리 저장 및 관리
// 연관기능: 도형 추가, 삭제, 저장, 불러오기

import Foundation
import Combine

// PlaceShape 모델 직접 import
import MapSketch

public final class PlaceShapeStore {
    public static let shared = PlaceShapeStore()
    @Published public private(set) var shapes: [PlaceShape] = []
    
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
    
    public func updateShape(_ shape: PlaceShape) {
        if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes[index] = shape
            do {
                try saveShapes()
            } catch {
                print("도형 업데이트 실패: \(error)")
            }
        }
    }
}
