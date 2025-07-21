import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("이용약관")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                Text("""
여기에 서비스 이용약관 내용을 입력하세요.

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
        .navigationTitle("이용약관")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    TermsOfServiceView()
} 