//
//  JSONStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//



import Foundation

/// JSON 파일 기반 저장소 구현체
public final class JSONStorage: ShapeGroupStorage {
    public static let shared = JSONStorage()
    private let fileName = "shape_groups.json"
    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(fileName)
    }

    private init() {
        copySampleIfNeeded()
    }

    /// 번들에 있는 샘플 JSON을 도큐먼트로 한 번 복사
    private func copySampleIfNeeded() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: fileURL.path),
           let bundleURL = Bundle.main.url(forResource: "sample_shape_groups", withExtension: "json") {
            try? fm.copyItem(at: bundleURL, to: fileURL)
        }
    }

    /// 저장된 그룹 로드
    public func loadGroups() -> [ShapeGroup] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ShapeGroup].self, from: data)
        } catch {
            print("[JSONStorage] load error: \(error)")
            return []
        }
    }

    /// 그룹 저장
    public func saveGroups(_ groups: [ShapeGroup]) {
        do {
            let data = try JSONEncoder().encode(groups)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[JSONStorage] save error: \(error)")
        }
    }

    /// 샘플로 리셋 (모두 삭제 후 샘플 복사)
    public func resetToSample() {
        try? FileManager.default.removeItem(at: fileURL)
        copySampleIfNeeded()
    }
}
