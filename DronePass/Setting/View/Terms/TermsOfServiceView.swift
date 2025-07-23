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
이용약관



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
