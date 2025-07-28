//
//  ColorPickerView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI

struct ColorPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedColor: PaletteColor
    @State private var lastColorChangeTime: Date = Date.distantPast
    private let colorChangeDebounceInterval: TimeInterval = 0.5 // 500ms
    
    let onColorSelected: (PaletteColor) -> Void
    
    init(selected: PaletteColor, onColorSelected: @escaping (PaletteColor) -> Void) {
        self._selectedColor = State(initialValue: selected)
        self.onColorSelected = onColorSelected
    }
    
    private var availableColors: [PaletteColor] {
        PaletteColor.allCases
    }
    
    // 색상명 한글 표기
    private func colorName(for color: PaletteColor) -> String {
        switch color {
        case .red:    return "빨강"
        case .orange: return "오렌지"
        case .yellow: return "노랑"
        case .green:  return "초록"
        case .teal:   return "청록"
        case .blue:   return "파랑"
        case .indigo: return "남색"
        case .purple: return "보라"
        case .pink:   return "분홍"
        case .gray:   return "회색"
        }
    }
    
    var body: some View {
        List {
            ForEach(Array(availableColors.enumerated()), id: \.element) { idx, color in
                HStack {
                    Circle()
                        .fill(Color(color.uiColor))
                        .frame(width: 24, height: 24)
                    Text(colorName(for: color))
                        .font(idx == selectedColorIndex ? .headline : .body)
                    Spacer()
                    if color == selectedColor {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedColor = color
                    updateAllShapesColorIfNeeded(to: color)
                }
            }
        }
        .navigationTitle("색상 선택")
    }
    
    /// 중복 색상 변경 작업을 방지하는 디바운싱 업데이트
    private func updateAllShapesColorIfNeeded(to color: PaletteColor) {
        let now = Date()
        if now.timeIntervalSince(lastColorChangeTime) >= colorChangeDebounceInterval {
            // 전체 도형 색상 변경
            ShapeFileStore.shared.updateAllShapesColor(to: color.hex)
            
            // 로컬 변경 사항 추적
            UserDefaults.standard.set(Date(), forKey: "lastLocalModificationTime")
            print("✅ 도형 색상 변경 및 로컬 변경 추적 기록")
            
            ColorManager.shared.defaultColor = color
            onColorSelected(color)
            presentationMode.wrappedValue.dismiss()
            
            lastColorChangeTime = now
        } else {
            print("📝 색상 변경 디바운싱: 이전 변경으로부터 \(String(format: "%.3f", now.timeIntervalSince(lastColorChangeTime)))초 경과")
        }
    }

    private var selectedColorIndex: Int {
        availableColors.firstIndex(of: selectedColor) ?? 0
    }
}

#Preview {
    ColorPickerView(selected: .blue) { _ in }
}
