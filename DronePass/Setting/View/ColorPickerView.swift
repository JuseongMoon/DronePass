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
    let onColorSelected: (PaletteColor) -> Void

    // 회색을 제외한 9가지 색상만 사용
    private var availableColors: [PaletteColor] {
        PaletteColor.allCases.filter { $0 != .gray }
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

    init(selected: PaletteColor = ColorManager.shared.defaultColor, onColorSelected: @escaping (PaletteColor) -> Void) {
        self._selectedColor = State(initialValue: selected)
        self.onColorSelected = onColorSelected
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
                    // 전체 도형 색상 변경
                    ShapeLocalManager.shared.updateAllShapesColor(to: color.hex)
                    ColorManager.shared.defaultColor = color
                    onColorSelected(color)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("색상 선택")
    }

    private var selectedColorIndex: Int {
        availableColors.firstIndex(of: selectedColor) ?? 0
    }
}

#Preview {
    ColorPickerView(selected: .blue) { _ in }
}
