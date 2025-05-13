//
//  JSONStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import Foundation

/// JSON 파일 기반의 ShapeGroupStorage 구현체
public final class JSONStorage: ShapeGroupStorage {
    private let fileName = "shape_groups.json"

    /// 문서 디렉토리에 있는 JSON 파일 URL
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    public init() {}

    /// JSON 파일에서 그룹 데이터를 로드
    public func loadGroups() throws -> [ShapeGroup] {
        let fm = FileManager.default
        let dstURL = fileURL

        // (1) 도큐먼트 디렉토리에 파일이 없으면 번들 샘플 복사
        if !fm.fileExists(atPath: dstURL.path),
           let srcURL = Bundle.main.url(forResource: "sample_shape_groups", withExtension: "json") {
            try fm.copyItem(at: srcURL, to: dstURL)
        }

        // (2) 복사되었거나, 이미 존재하던 파일을 읽어서 디코딩
        let data = try Data(contentsOf: dstURL)
        return try JSONDecoder().decode([ShapeGroup].self, from: data)
    }

    /// 그룹 데이터를 JSON 파일로 저장
    public func saveGroups(_ groups: [ShapeGroup]) throws {
        let data = try JSONEncoder().encode(groups)
        try data.write(to: fileURL)
    }
}
