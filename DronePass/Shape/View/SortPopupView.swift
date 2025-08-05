//
//  SortPopupView.swift
//  DronePass
//
//  Created by 문주성 on 8/2/25.
//

import SwiftUI

struct SortPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sortingManager = ShapeSortingManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("정렬 방식 선택")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("완료") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // 정렬 옵션 목록
                List {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortingManager.setSortOption(option)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: option.icon)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text(option.rawValue)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if sortingManager.selectedSortOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SortPopupView()
}
