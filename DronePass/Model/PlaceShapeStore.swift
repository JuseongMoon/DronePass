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
    
    public func loadShapes() {
        do {
            if fileManager.fileExists(atPath: shapesFileURL.path) {
                let data = try Data(contentsOf: shapesFileURL)
                shapes = try decoder.decode([PlaceShape].self, from: data)
                print("✅ 도형 데이터 로드 성공: \(shapes.count)개")
            } else {
                // 파일이 없으면 빈 배열로 시작
                shapes = []
                print("📁 도형 데이터 파일이 없어 빈 배열로 시작")
                // 빈 배열을 파일로 저장
                saveShapes()
            }
        } catch {
            print("❌ 도형 데이터 로드 실패: \(error)")
            shapes = []
        }
    }
    
    public func saveShapes() {
        do {
            let data = try encoder.encode(shapes)
            try data.write(to: shapesFileURL)
            print("💾 도형 데이터 저장 성공: \(shapes.count)개")
        } catch {
            print("❌ 도형 데이터 저장 실패: \(error)")
        }
    }
    
    public func addShape(_ shape: PlaceShape) {
        shapes.append(shape)
        saveShapes()
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
    }
    
    public func removeShape(id: UUID) {
        shapes.removeAll { $0.id == id }
        saveShapes()
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
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
            saveShapes()
            NotificationCenter.default.post(name: .shapesDidChange, object: nil)
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
        saveShapes()
        // UI 갱신을 위해 Notification 전송
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
    }
    
    // MARK: - 샘플 데이터 추가 (테스트용)
    public func addSampleData() {
        let sampleShapes = [
            PlaceShape(
                title: "서울시청",
                shapeType: .circle,
                baseCoordinate: Coordinate(latitude: 37.5665, longitude: 126.9780),
                radius: 500,
                memo: "서울시청 주변 비행 금지 구역입니다. 드론 비행 시 주의하세요.",
                address: "서울특별시 중구 태평로1가 31",
                expireDate: Date().addingTimeInterval(86400 * 7),
                startedAt: Date(),
                color: "#FF0000"
            ),
            PlaceShape(
                title: "경복궁",
                shapeType: .circle,
                baseCoordinate: Coordinate(latitude: 37.5796, longitude: 126.9770),
                radius: 300,
                memo: "경복궁 보존 구역입니다. 문화재 보호를 위해 드론 비행이 제한됩니다.",
                address: "서울특별시 종로구 사직로 161",
                expireDate: Date().addingTimeInterval(86400 * 30),
                startedAt: Date(),
                color: "#00FF00"
            ),
            PlaceShape(
                title: "한강공원",
                shapeType: .circle,
                baseCoordinate: Coordinate(latitude: 37.5219, longitude: 126.9369),
                radius: 800,
                memo: "한강공원 드론 비행 허용 구역입니다. 안전한 비행을 위해 규정을 준수하세요.",
                address: "서울특별시 영등포구 여의도동",
                expireDate: Date().addingTimeInterval(86400 * 90),
                startedAt: Date(),
                color: "#007AFF"
            )
        ]
        
        for shape in sampleShapes {
            addShape(shape)
        }
        
        print("🎯 샘플 데이터 추가 완료: \(sampleShapes.count)개")
    }
    
    public func clearAllData() {
        shapes.removeAll()
        saveShapes()
        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
        print("🗑️ 모든 데이터 삭제 완료")
    }
}

extension PlaceShapeStore {
    /// 저장된 모든 도형의 색상을 새로운 색상(hex)으로 변경하고 저장/갱신

    /// 특정 id의 도형을 반환
    func getShape(id: UUID) -> PlaceShape? {
        return shapes.first(where: { $0.id == id })
    }
}

