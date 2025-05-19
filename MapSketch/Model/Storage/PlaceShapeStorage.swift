//
//  PlaceShapeStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import Foundation

/// JSON 파일 기반 도형 저장소
public protocol PlaceShapeStorage {
    func loadShapes() -> [PlaceShape]
    func saveShapes(_ shapes: [PlaceShape])
}

public final class JSONPlaceShapeStorage: PlaceShapeStorage {
    public static let shared = JSONPlaceShapeStorage()
    private let fileName = "placeshapes.json"
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(fileName)
    }

    public func loadShapes() -> [PlaceShape] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([PlaceShape].self, from: data)
        } catch {
            print("[JSONPlaceShapeStorage] load error: \(error)")
            return []
        }
    }

    public func saveShapes(_ shapes: [PlaceShape]) {
        do {
            let data = try JSONEncoder().encode(shapes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[JSONPlaceShapeStorage] save error: \(error)")
        }
    }
}
