//
//  SampleShapeLoader.swift
//  MapSketch
//
//  Created by 문주성 on 5/19/25.
//

import Foundation

final class SampleShapeLoader {
    static func loadSampleShapes() -> [PlaceShape] {
        guard let url = Bundle.main.url(forResource: "sample_shapes", withExtension: "json") else {
            print("❌ 샘플 JSON 파일을 찾을 수 없습니다.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // createdAt, expireDate
            let shapes = try decoder.decode([PlaceShape].self, from: data)
            return shapes
        } catch {
            print("❌ 샘플 도형 디코딩 실패:", error)
            return []
        }
    }
}
