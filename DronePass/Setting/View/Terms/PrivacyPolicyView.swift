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
개인정보 취급방침



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
