import SwiftUI

struct PatchNotesView: View {
    let patchNotes: [PatchNote]
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && patchNotes.isEmpty {
                    ProgressView("불러오는 중...")
                        .progressViewStyle(.circular)
                } else if patchNotes.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("패치노트를 불러올 수 없습니다.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("잠시 후 다시 시도해주세요.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(patchNotes) { note in
                            Section {
                                VStack(alignment: .leading, spacing: 16) {
                                    PatchNoteHeader(note: note)
                                    
                                    if !note.features.allSatisfy({ $0.title.isEmpty }) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(note.features) { feature in
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack(alignment: .center, spacing: 6) {
                                                        Image(systemName: "checkmark.circle")
                                                            .font(.subheadline)
                                                            .foregroundColor(.accentColor)
                                                        Text(feature.title)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                    }
                                                    
                                                    if let description = feature.description, !description.isEmpty {
                                                        let descriptionLines = description.components(separatedBy: "\n")
                                                        ForEach(descriptionLines, id: \.self) { line in
                                                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                                                Text("-")
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                                
                                                                Text(line)
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                        }
                                                        .padding(.leading, 20)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("패치노트")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

fileprivate struct PatchNoteHeader: View {
    let note: PatchNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.version)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(note.date)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 10)
                
            }
            
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            
        }
        .padding(.leading, 5)

    }
    
}

#Preview {
    PatchNotesView(patchNotes: [
        .init(version: "v2.0.0", date: "2025.06", title: "DronePass 2.0 업데이트", features: [
            .init(title: "새로운 UI/UX 디자인 적용", description: "앱 전반의 디자인을 더 직관적으로 개선했습니다."),
            .init(title: "성능 최적화 및 버그 수정", description: "앱 로딩 속도를 개선하고, 알려진 자잘한 버그들을 수정했습니다. 수정했습니다. 수정했습니다."),
            .init(title: "다크모드 지원 추가", description: nil)
        ]),
        .init(version: "v1.0.0", date: "2025.06", title: "DronePass 첫 출시", features: [
            .init(title: "드론 비행 허가지 시각화 기능", description: "지도 위에 드론 비행 허가 구역을 표시하여 쉽게 확인할 수 있습니다."),
            .init(title: "반경 기반 도형 생성", description: "원하는 위치를 중심으로 원형 비행 구역을 설정할 수 있습니다.")
        ])
    ], isLoading: false)
}

#Preview("Loading") {
    PatchNotesView(patchNotes: [], isLoading: true)
}

#Preview("Empty") {
    PatchNotesView(patchNotes: [], isLoading: false)
} 
