//
//  ShapeGroup.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import Foundation

public struct ShapeGroup: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var alpha: Double
    public var shapes: [PlaceShape]
    public let createdAt: Date
    
    public init(
      id: UUID = UUID(),
      name: String,
      colorHex: String,
      alpha: Double,
      shapes: [PlaceShape] = [],
      createdAt: Date = Date()
    ) {
      self.id = id
      self.name = name
      self.colorHex = colorHex
      self.alpha = alpha
      self.shapes = shapes
      self.createdAt = createdAt
    }
}
