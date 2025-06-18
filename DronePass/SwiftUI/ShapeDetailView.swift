//
//  ShapeDetailView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif
import SafariServices

// 환경값 정의
private struct MemoBoxMaxHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 400
}
extension EnvironmentValues {
    var memoBoxMaxHeight: CGFloat {
        get { self[MemoBoxMaxHeightKey.self] }
        set { self[MemoBoxMaxHeightKey.self] = newValue }
    }
}

struct ShapeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var store = PlaceShapeStore.shared
    
    @State private var shape: PlaceShape
    private let originalShape: PlaceShape
    
    // onClose: Called when the close button is tapped
    var onClose: (() -> Void)? = nil
    
    // onEdit: Called when the edit button is tapped
    var onEdit: (() -> Void)? = nil
    
    // onDelete: Called when the delete button is confirmed
    var onDelete: (() -> Void)?
    
    @State private var showMapSheet = false
    @State private var showDeleteAlert = false
    @State private var showActionSheet = false
    @State private var showSafari = false
    @State private var safariURL: URL? = nil
    @State private var showEditSheet = false
    
    @Environment(\.memoBoxMaxHeight) private var memoBoxMaxHeight
    
    init(shape: PlaceShape, onClose: (() -> Void)? = nil, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        _shape = State(initialValue: shape)
        self.originalShape = shape
        self.onClose = onClose
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    private var addressURL: URL? {
        guard let address = shape.address else { return nil }
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }
    
    // MARK: - 지도앱 연동 버튼
    private var mapButtons: [(title: String, action: () -> Void)] {
        let coordinate = shape.baseCoordinate
        let name = shape.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "목적지"
        
        return [
            ("네이버지도", {
                let urlStr = "nmap://route/public?dlat=\(coordinate.latitude)&dlng=\(coordinate.longitude)&dname=\(name)"
                openMapApp(urlScheme: urlStr, appStoreId: "311867728")
            }),
            ("카카오맵", {
                let urlStr = "kakaomap://route?ep=\(coordinate.latitude),\(coordinate.longitude)&by=CAR"
                openMapApp(urlScheme: urlStr, appStoreId: "304608425")
            }),
            ("티맵", {
                let urlStr = "tmap://route?goalname=\(name)&goalx=\(coordinate.longitude)&goaly=\(coordinate.latitude)"
                openMapApp(urlScheme: urlStr, appStoreId: "431589174")
            }),
            ("구글맵", {
                let urlStr = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
                openMapApp(urlScheme: urlStr, appStoreId: "585027354")
            })
        ]
    }
    
    // MARK: - 지도앱 실행
    private func openMapApp(urlScheme: String, appStoreId: String) {
        guard let url = URL(string: urlScheme) else { return }
        
        Task {
            await openURL(url)
            // 앱이 설치되어 있지 않은 경우 앱스토어로 이동
            if let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appStoreId)") {
                await openURL(appStoreURL)
            }
        }
    }
    
    // MARK: - Body

    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // 제목
                        dataRow(title: "제목", value: shape.title)
                        // 좌표
                        dataRow(title: "좌표", value: shape.baseCoordinate.formattedCoordinate)
                        // 주소 (텍스트만 링크)
                        dataRow(title: "주소", value: shape.address ?? "-", isLink: true, linkURL: addressURL)
                        // 반경
                        if let radius = shape.radius {
                            dataRow(title: "반경", value: "\(Int(radius)) m")
                        }
                        // 시작일
                        dataRow(title: "시작일", value: DateFormatter.koreanDateTime.string(from: shape.startedAt))
                        // 종료일
                        if let expire = shape.expireDate {
                            dataRow(title: "종료일", value: DateFormatter.koreanDateTime.string(from: expire))
                        }
                        // 메모
                        dataRow(title: "메모", value: shape.memo ?? "-")
                    }
                    .padding()
                    .padding(.trailing, -10)
                    .padding(.leading, 5)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") {
                            dismiss()
                            onClose?()
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 16) {
                        Button(action: { showEditSheet = true }) {
                            Text("수정하기")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button(action: { showDeleteAlert = true }) {
                            Text("삭제하기")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .frame(height: 56)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .alert("도형 삭제", isPresented: $showDeleteAlert) {
                    Button("취소", role: .cancel) {}
                    Button("삭제하기", role: .destructive) {
                        store.removeShape(id: shape.id)
                        onDelete?()
                        dismiss()
                        NotificationCenter.default.post(name: .shapesDidChange, object: nil)
                    }
                } message: {
                    Text("'\(shape.title)' 도형을 삭제하시겠습니까?")
                }
                .onReceive(NotificationCenter.default.publisher(for: .shapesDidChange)) { _ in
                    if let updatedShape = store.getShape(id: shape.id) {
                        shape = updatedShape
                    }
                }
                .confirmationDialog("길찾기 앱 선택", isPresented: $showActionSheet, titleVisibility: .visible) {
                    ForEach(mapButtons, id: \.title) { button in
                        Button(button.title) { button.action() }
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("아래 앱으로 길찾기를 시작합니다.")
                }
                .sheet(isPresented: $showSafari) {
                    if let url = safariURL {
                        SafariView(url: url)
                    }
                }
                .sheet(isPresented: $showEditSheet) {
                    ShapeEditView(
                        coordinate: shape.baseCoordinate,
                        onAdd: { updatedShape in
                            shape = updatedShape
                            showEditSheet = false
                        },
                        originalShape: shape
                    )
                }
            }
            .environment(\.memoBoxMaxHeight, geometry.size.height - 56 - 8 - 10)
        }
    }
    
    // MARK: - 데이터 행 뷰
    @ViewBuilder
    private func dataRow(title: String, value: String, isLink: Bool = false, linkURL: URL? = nil) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(width: 60, alignment: .leading)
                .foregroundColor(.primary)
                .padding(.top, 8)
            if title == "메모" {
                TextEditor(text: .constant(value))
                    .font(.system(size: 17))
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                    .disabled(true)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            } else if title == "주소" {
                Button(action: { showActionSheet = true }) {
                    Text(value)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.blue)
                        .lineLimit(.max)
                        .truncationMode(.tail)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(value)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
                    .lineLimit(.max)
                    .truncationMode(.tail)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            Spacer()
        }
    }
}

struct HyperlinkTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    @Binding var showSafari: Bool
    @Binding var safariURL: URL?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = context.coordinator
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let attrStr = NSMutableAttributedString(string: text)
        attrStr.addAttribute(.font, value: font, range: NSRange(location: 0, length: text.count))
        attrStr.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: text.count))
        uiView.attributedText = attrStr
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: HyperlinkTextView
        
        init(parent: HyperlinkTextView) { self.parent = parent }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if URL.scheme == "http" || URL.scheme == "https" {
                parent.safariURL = URL
                parent.showSafari = true
                return false
            }
            // 전화, 메일 등은 시스템이 처리
            return true
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

// MARK: - 프리뷰
#Preview {
    let dummy = PlaceShape(
        id: UUID(),
        title: "드론 비행연습 및 테스트촬영",
        baseCoordinate: Coordinate(latitude: 37.5331, longitude: 126.6342),
        radius: 999,
        memo: """
군 담당자  [ ☎ 031-290-9221 ]

 · 인근 촬영금지시설이 촬영될 가능성이 명백한 경우 (업무일 기준)촬영 2일 전까지 연락 후 안내받으시기 바랍니다.
 · 현장통제 보안담당자 : 031-290-9041(연락 가능시간 : 평일 09:00 ~ 17:00 / 그 외 연락불가)
 · 인근 촬영금지시설이 촬영될 가능성이 명백한 경우 (업무일 기준)촬영 2일 전까지 연락 후 안내받으시기 바랍니다.
 · 현장통제 보안담당자 : 031-290-9041(연락 가능시간 : 평일 09:00 ~ 17:00 / 그 외 연락불가)
 · 인근 촬영금지시설이 촬영될 가능성이 명백한 경우 (업무일 기준)촬영 2일 전까지 연락 후 안내받으시기 바랍니다.
 · 현장통제 보안담당자 : 031-290-9041(연락 가능시간 : 평일 09:00 ~ 17:00 / 그 외 연락불가)

""",
        address: "인천광역시 서구 청라동 1-791",
        expireDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
        startedAt: Date(),
        color: PaletteColor.blue.hex
    )
    
    return ShapeDetailView(
        shape: dummy,
        onDelete: {
            print("프리뷰: '\(dummy.title)' 도형이 삭제되었습니다.")
        }
    )
}
