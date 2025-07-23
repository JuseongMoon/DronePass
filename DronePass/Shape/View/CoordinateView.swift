//
//  CoordinateView.swift
//  DronePass
//
//  Created by 문주성 on 6/18/25.
//

import SwiftUI


struct CoordinateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchCoordinateViewModel()
    @FocusState private var isFocused: Bool
    
    var onSelectCoordinate: ((CoordinateManager, String) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // 검색 바
                SearchBar(
                    text: $viewModel.coordinateText,
                    placeholder: "좌표를 입력해주세요",
                    onSubmit: {
                        Task {
                            await viewModel.validateAndSearch()
                        }
                    },
                    onClear: {
                        viewModel.coordinateText = ""
                        viewModel.coordinateValidation = ""
                        viewModel.isCoordinateValid = true
                        viewModel.address = nil
                        viewModel.parsedCoordinate = nil
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                if !viewModel.coordinateValidation.isEmpty {
                    Text(viewModel.coordinateValidation)
                        .font(.caption)
                        .foregroundColor(viewModel.isCoordinateValid ? .green : .red)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("드론원스탑에서 승인받은 좌표를 복사&붙여넣기 하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Text("지원하는 좌표 형식:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Group {
                        Text("• 도/분/초: 37° 38′ 55″ N 126° 41′ 12″ E")
                        Text("• 십진도: 37.648611°, 126.686667°")
                        Text("• 단순 십진수: 37.3855 126.4142")
                        Text("• Geo URI: geo:37.648611,126.686667")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxWidth: 500) // Adjust max width as desired
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage)
                } else if let address = viewModel.address, let coordinate = viewModel.parsedCoordinate {
                    AddressResultView(
                        address: address,
                        coordinate: coordinate,
                        originalText: viewModel.coordinateText,
                        onSelect: {
                            onSelectCoordinate?(coordinate, address)
                            dismiss()
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("좌표 입력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("확인") {
                        if let coordinate = viewModel.parsedCoordinate,
                           let address = viewModel.address {
                            onSelectCoordinate?(coordinate, address)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isCoordinateValid)
                }
            }
            .alert("주소 검색 실패", isPresented: $viewModel.showAddressNotFoundAlert) {
                Button("예") {
                    if let coordinate = viewModel.parsedCoordinate {
                        onSelectCoordinate?(coordinate, "주소를 찾을 수 없습니다")
                        dismiss()
                    }
                }
                Button("아니요", role: .cancel) {
                    // 검색창으로 돌아가기 (좌표는 그대로 유지)
                }
            } message: {
                Text("주소가 검색되지 않습니다. 이대로 좌표를 입력할까요? \n (길찾기는 좌표를 기반으로 진행됩니다)")
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddressResultView: View {
    let address: String
    let coordinate: CoordinateManager
    let originalText: String
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(address)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(originalText)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    CoordinateView(onSelectCoordinate: { coordinate, address in
        print("Selected coordinate: \(coordinate.formattedCoordinate)")
        print("Selected address: \(address)")
    })
}
