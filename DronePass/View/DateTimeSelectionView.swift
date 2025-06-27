
//
//  DateTimeSelectionView.swift
//  DronePass
//
//  Created by 문주성 on 6/27/25.
//

import SwiftUI

struct DateTimeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    var isDateOnly: Bool
    var title: String

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    displayedComponents: isDateOnly ? .date : [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical) // 그래픽 스타일 유지
                .labelsHidden() // 레이블 숨기기

                Spacer()

                Button("선택 완료") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DateTimeSelectionView(selectedDate: .constant(Date()), isDateOnly: false, title: "날짜/시간 선택")
}
