import SwiftUI

struct PrivacyPolicyView: View {
    @StateObject private var fetcher = FetchWebDocuments()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 고정된 헤더
            HStack {
                Text("개인정보 취급방침")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("닫기") {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
            
            // 스크롤 가능한 콘텐츠
            ScrollView {
                if fetcher.isLoadingPrivacyPolicy {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView("불러오는 중...")
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(minHeight: 300)
                } else if fetcher.privacyPolicyElements.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("개인정보 취급방침을 불러올 수 없습니다.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("잠시 후 다시 시도해주세요.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button("다시 시도") {
                            Task {
                                await fetcher.fetchPrivacyPolicy()
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                        Spacer()
                    }
                    .frame(minHeight: 300)
                    .padding()
                } else {
                    MarkdownView(
                        elements: fetcher.privacyPolicyElements,
                        tables: fetcher.privacyPolicyTables
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if fetcher.privacyPolicyElements.isEmpty {
                Task {
                    await fetcher.fetchPrivacyPolicy()
                }
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
} 
