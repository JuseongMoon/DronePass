//
//  SavedTableListView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI

struct SavedTableListView: View {
    @ObservedObject var placeShapeStore = PlaceShapeStore.shared
    @State private var selectedShape: PlaceShape? = nil

    var body: some View {
        List {
            if placeShapeStore.shapes.isEmpty {
                Text("저장된 항목이 없습니다.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(placeShapeStore.shapes) { shape in
                    ZStack {
                        HStack(alignment: .top, spacing: 12) {
                            // 왼쪽 컬러 원
                            Circle()
                                .fill(Color(UIColor(hex: shape.color) ?? .systemBlue))
                                .frame(width: 18, height: 18)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(shape.title)
                                    .font(.headline)
                                if let address = shape.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("\(Self.dateFormatter.string(from: shape.startedAt)) ~ \(Self.dateFormatter.string(from: shape.expireDate ?? Date()))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                // info 버튼
                                Button(action: {
                                    selectedShape = shape
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                // 반경
                                if let radius = shape.radius {
                                    Text("반경: \(Int(radius)) m")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(height: 48)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: deleteShape)
            }
        }
        .listStyle(.plain)
        .sheet(item: $selectedShape) { shape in
            ShapeDetailView(shape: shape) {
                selectedShape = nil
            }
        }
    }
    
    private func deleteShape(at offsets: IndexSet) {
        for index in offsets {
            let shape = placeShapeStore.shapes[index]
            placeShapeStore.deleteShape(shape)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    private func dateText(for shape: PlaceShape) -> some View {
        let formatter = Self.dateFormatter
        if let end = shape.expireDate {
            return Text("\(formatter.string(from: shape.startedAt)) ~ \(formatter.string(from: end))")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            return Text("시작: \(formatter.string(from: shape.startedAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SavedTableListView()
}
