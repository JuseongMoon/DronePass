import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("개인정보 취급방침")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                Text("""
여기에 개인정보 취급방침 내용을 입력하세요.

제1조(수집하는 개인정보 항목)
...

제2조(개인정보의 수집 및 이용목적)
...

(이하 생략)
""")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("개인정보 취급방침")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    PrivacyPolicyView()
} 