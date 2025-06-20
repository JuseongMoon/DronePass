import SwiftUI

struct AppInfoView: View {
    var body: some View {
        NavigationView {
            List {
                // 버전 정보 섹션
                Section(header: Text("버전 정보").font(.headline)) {
                    HStack {
                        Text("앱 버전")
                        Spacer()
                        Text(AppInfo.Version.current)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 앱 소개 섹션
                Section(header: Text("앱 소개").font(.headline)) {
                    Text(AppInfo.Description.intro)
                        .padding(.vertical, 8)
                }
                
                // 주요 기능 섹션
                Section(header: Text("주요 기능").font(.headline)) {
                    ForEach(AppInfo.Description.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .padding(.top, 3)
                            Text(feature)
                        }
                    }
                }
                
                // 연락처 정보 섹션
                Section(header: Text("연락처").font(.headline)) {
                    let contactInfo = AppInfo.Description.contact.components(separatedBy: "\n")
                    let companyName = contactInfo.first ?? ""
                    let email = contactInfo.count > 1 ? contactInfo[1] : ""
                    
                    if !companyName.isEmpty {
                        Label(companyName, systemImage: "building.2")
                    }
                    
                    if !email.isEmpty, let emailURL = URL(string: "mailto:\(email)") {
                        Link(destination: emailURL) {
                            Label(email, systemImage: "envelope")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("앱 정보")
            .navigationBarItems(trailing: Button("닫기") {
                // 이 뷰를 닫는 로직이 필요합니다.
                // presentationMode를 사용하여 닫을 수 있습니다.
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
}

struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
    }
} 