import SwiftUI

struct SavedShapeViewCell: View {
    let shape: PlaceShape
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(shape.title)
                    .font(.headline)
                Text(shape.shapeType.koreanName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(Self.dateFormatter.string(from: shape.startedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SavedShapeViewCell(shape: PlaceShape(
        title: "테스트 구역",
        baseCoordinate: Coordinate(latitude: 37.56, longitude: 126.97),
        radius: 300,
        memo: "메모 예시",
        address: "서울특별시 어딘가",
        expireDate: Date(),
        startedAt: Date(),
        color: "#007AFF"
    ))
}
