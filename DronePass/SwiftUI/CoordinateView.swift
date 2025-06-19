//
//  CoordinateView.swift
//  DronePass
//
//  Created by 문주성 on 6/18/25.
//

import SwiftUI

class CoordinateViewModel: ObservableObject {
    @Published var coordinateText: String = ""
    @Published var coordinateValidation: String = ""
    @Published var isCoordinateValid = true
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var address: String?
    @Published var parsedCoordinate: Coordinate?
    @Published var showAddressNotFoundAlert = false
    
    func validateAndSearch() async {
        if let coordinate = Coordinate.parse(coordinateText) {
            coordinateValidation = "유효한 좌표 형식입니다"
            isCoordinateValid = true
            parsedCoordinate = coordinate
            
            // Reverse Geocoding 수행
            await reverseGeocode(coordinate: coordinate)
        } else {
            coordinateValidation = "잘못된 좌표 형식입니다"
            isCoordinateValid = false
            address = nil
            parsedCoordinate = nil
        }
    }
    
    @MainActor
    private func reverseGeocode(coordinate: Coordinate) async {
        isSearching = true
        errorMessage = nil
        address = nil
        
        do {
            // Double 타입의 위도, 경도 값을 직접 전달
            let address = try await NaverGeocodingService.shared.reverseGeocode(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            self.address = address
        } catch {
            // 주소 검색 실패 시 알림창 표시
            self.showAddressNotFoundAlert = true
            print("[좌표검색] 에러 발생: \(error)")
        }
        
        isSearching = false
    }
}

struct CoordinateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CoordinateViewModel()
    @FocusState private var isFocused: Bool
    
    var onSelectCoordinate: ((Coordinate, String) -> Void)?
    
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
                
                VStack(spacing: 16) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("드론원스탑에서 승인받은 좌표를 그대로 복사&붙여넣기 하세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("지원하는 좌표 형식:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Group {
                            Text("• 도/분/초: 37° 38′ 55″ N 126° 41′ 12″ E")
                            Text("• 십진도: 37.648611°, 126.686667°")
                            Text("• 단순 십진수: 37.3855 126.4142")
                            Text("• Geo URI: geo:37.648611,126.686667")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
    let coordinate: Coordinate
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
