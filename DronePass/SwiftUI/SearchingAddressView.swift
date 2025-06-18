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

class AddressSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var addresses: [NaverDetailAddress] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("[주소검색] ViewModel 초기화")
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] searchText in
                print("[주소검색] 검색어 변경 감지: \(searchText)")
                Task { @MainActor in
                    await self?.searchAddress(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func searchAddress(query: String) async {
        print("[주소검색] searchAddress 호출: \(query)")
        isSearching = true
        errorMessage = nil
        
        do {
            let addresses = try await NaverGeocodingService.shared.geocode(address: query)
            self.addresses = addresses
            self.isSearching = false
        } catch {
            self.errorMessage = "검색 중 오류가 발생했습니다: \(error.localizedDescription)"
            self.isSearching = false
            print("[주소검색] 에러 발생: \(error)")
        }
    }
}

struct SearchingAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddressSearchViewModel()
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
                    placeholder: "주소를 입력하세요",
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
    SearchingAddressView(
        onSelectAddress: { address in
            print("Selected address: \(address.roadAddress)")
        }
    )
}
