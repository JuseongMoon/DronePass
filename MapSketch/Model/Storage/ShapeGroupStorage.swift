//
//  ShapeGroupStorage.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import Foundation

/// 저장소 인터페이스 정의
public protocol ShapeGroupStorage {
    /// 저장된 ShapeGroup 배열을 불러옵니다.
    func loadGroups() throws -> [ShapeGroup]
    /// ShapeGroup 배열을 저장합니다.
    func saveGroups(_ groups: [ShapeGroup]) throws
}
