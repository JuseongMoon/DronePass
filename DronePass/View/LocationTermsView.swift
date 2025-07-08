import SwiftUI

struct LocationTermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("위치기반 서비스 이용약관")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                Text("""
여기에 위치기반 서비스 이용약관 내용을 입력하세요.

제1조(목적)
이 약관은 ...

제2조(정의)
...

(이하 생략)
""")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("위치기반 서비스 이용약관")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LocationTermsView()
} 