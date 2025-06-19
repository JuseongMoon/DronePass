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

struct ShapeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var store = PlaceShapeStore.shared
    
    @State private var shape: PlaceShape
    private let originalShape: PlaceShape
    
    var onClose: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var showMapSheet = false
    @State private var showDeleteAlert = false
    @State private var showActionSheet = false
    @State private var showSafari = false
    @State private var safariURL: URL? = nil
    @State private var showEditSheet = false
    
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
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("제목")
                        Spacer()
                        Text(shape.title)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("좌표")
                        Spacer()
                        Text(shape.baseCoordinate.formattedCoordinate)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("주소")
                        Spacer()
                        Button(shape.address ?? "-") {
                            showActionSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if let radius = shape.radius {
                        HStack {
                            Text("반경")
                            Spacer()
                            Text("\(Int(radius)) m")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("시작일")
                        Spacer()
                        Text(DateFormatter.koreanDateTime.string(from: shape.startedAt))
                            .foregroundColor(.secondary)
                    }
                    
                    if let expire = shape.expireDate {
                        HStack {
                            Text("종료일")
                            Spacer()
                            Text(DateFormatter.koreanDateTime.string(from: expire))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("메모") {
                    VStack {
                        HyperlinkTextView(
                            text: shape.memo ?? "-",
                            font: .systemFont(ofSize: 16),
                            textColor: UIColor.secondaryLabel,
                            showSafari: $showSafari,
                            safariURL: $safariURL
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 44)
            .environment(\.defaultMinListHeaderHeight, 8)
            .padding(.top, -20)
            .navigationTitle("상세 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("수정하기") {
                            showEditSheet = true
                        }
                        Button("삭제하기", role: .destructive) {
                            showDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
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
            .onReceive(NotificationCenter.default.publisher(for: .shapesDidChange)) { _ in
                if let updatedShape = store.getShape(id: shape.id) {
                    shape = updatedShape
                }
            }
        }
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
        .presentationCompactAdaptation(.popover)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
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
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = true
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

// MARK: - Preview
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
hisnote@me.com
https://www.naver.com
· 인근 촬영금지시설이 촬영될 가능성이 명백한 경우 (업무일 기준)촬영 2일 전까지 연락 후 안내받으시기 바랍니다.
· 현장통제 보안담당자 : 031-290-9041(연락 가능시간 : 평일 09:00 ~ 17:00 / 그 외 연락불가)
hisnote@me.com
https://www.naver.com
· 인근 촬영금지시설이 촬영될 가능성이 명백한 경우 (업무일 기준)촬영 2일 전까지 연락 후 안내받으시기 바랍니다.
· 현장통제 보안담당자 : 031-290-9041(연락 가능시간 : 평일 09:00 ~ 17:00 / 그 외 연락불가)
hisnote@me.com
https://www.naver.com
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

