//
//  SearchingAddressView.swift
//  DronePass
//
//  Created by 문주성 on 6/18/25.
//

import SwiftUI
import Combine
import Foundation
import MapKit





struct SearchAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchAddressViewModel()
    @State private var searchText = ""
    
    var onSelectAddress: ((NaverDetailAddress) -> Void)?
    
    init(onSelectAddress: ((NaverDetailAddress) -> Void)? = nil) {
        self.onSelectAddress = onSelectAddress
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // 검색 바
                SearchBar(
                    text: $searchText,
                    placeholder: "도로명 주소로 검색해주세요",
                    onSubmit: {
                        Task {
                            await viewModel.searchAddress(query: searchText)
                        }
                    },
                    onClear: {
                        searchText = ""
                        viewModel.searchText = ""
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage)
                } else if viewModel.addresses.isEmpty {
                    // 검색 결과가 없을 때 안내 메시지 표시
                    VStack(alignment: .leading, spacing: 8) {
                        Text("지번 주소나 건물명으로는 검색이 어렵습니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("올바른 검색 예시:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Group {
                            Text("• 서초대로78길 24")
                            Text("• 테헤란로 322")
                            Text("• 종로 1")
                            Text("• 세종대로 110")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxWidth: 500) // Adjust max width as desired
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    
                    Spacer()
                } else {
                    AddressListView(
                        addresses: viewModel.addresses,
                        onSelect: { address in
                            onSelectAddress?(address)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("주소 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                
                if !text.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button(action: onSubmit) {
                Text("검색")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(text.isEmpty)
        }
    }
}

struct AddressListView: View {
    let addresses: [NaverDetailAddress]
    let onSelect: (NaverDetailAddress) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(addresses, id: \.roadAddress) { address in
                    AddressCardView(address: address)
                        .onTapGesture {
                            onSelect(address)
                        }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AddressCardView: View {
    let address: NaverDetailAddress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(address.roadAddress)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(address.jibunAddress)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            if let buildingName = address.buildingName {
                Text(buildingName)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if let postalCode = address.postalCode {
                Text("우편번호: \(postalCode)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchAddressView(
        onSelectAddress: { address in
            print("Selected address: \(address.roadAddress)")
        }
    )
}
