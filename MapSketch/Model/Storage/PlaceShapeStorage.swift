//
//  PlaceShapeStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 도형 데이터를 파일로 저장/불러오는 저장소 프로토콜 및 구현체
// 연관기능: 도형 저장, 불러오기, 파일 입출력

import Foundation // Foundation 프레임워크를 가져옵니다. (파일 입출력, 데이터 관리)

/// JSON 파일 기반 도형 저장소
public protocol PlaceShapeStorage { // 도형 저장소 프로토콜입니다.
    func loadShapes() -> [PlaceShape] // 도형 목록을 불러오는 메서드
    func saveShapes(_ shapes: [PlaceShape]) // 도형 목록을 저장하는 메서드
}

public final class JSONPlaceShapeStorage: PlaceShapeStorage { // JSON 파일로 도형을 저장/불러오는 구현체입니다.
    public static let shared = JSONPlaceShapeStorage() // 싱글턴 인스턴스
    private let fileName = "placeshapes.json" // 저장 파일명
    private var fileURL: URL { // 저장 파일의 경로
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(fileName)
    }

    public func loadShapes() -> [PlaceShape] { // 파일에서 도형 목록을 불러오는 메서드
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([PlaceShape].self, from: data)
        } catch {
            print("[JSONPlaceShapeStorage] load error: \(error)")
            return []
        }
    }

    public func saveShapes(_ shapes: [PlaceShape]) { // 도형 목록을 파일에 저장하는 메서드
        do {
            let data = try JSONEncoder().encode(shapes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[JSONPlaceShapeStorage] save error: \(error)")
        }
    }
}
