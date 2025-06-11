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

struct ShapeDetailView: View {
    let shape: PlaceShape
    var onClose: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var showMapSheet = false
    @State private var showDeleteAlert = false
    @State private var showActionSheet = false
    
    var body: some View {
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { onClose?() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button(action: { onEdit?() }) {
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
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("도형 삭제"),
                    message: Text("'\(shape.title)' 도형을 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제하기")) { onDelete?() },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - 데이터 행 뷰
    @ViewBuilder
    private func dataRow(title: String, value: String, isLink: Bool = false, linkURL: URL? = nil) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(width: 60, alignment: .leading)
                .foregroundColor(.primary)
            if isLink, let url = linkURL {
                Link(value, destination: url)
                    .font(.body)
                    .frame(width: 260, alignment: .leading) // ← 이 줄 추가
                    .foregroundColor(.blue)
                    .lineLimit(.max)
                    .truncationMode(.tail)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            } else {
                Text(value)
                    .font(.body)
                    .frame(width: 260, alignment: .leading) // ← 이 줄 추가
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
    
    // 주소 링크 URL 생성
    private var addressURL: URL? {
        guard let address = shape.address else { return nil }
        let encoded = address.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }
    
    // MARK: - 지도앱 연동 액션시트 버튼
    private func mapAppButtons() -> [ActionSheet.Button] {
        let coordinate = shape.baseCoordinate
        let name = shape.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "목적지"
        let address = (shape.address ?? "목적지").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "목적지"
        var buttons: [ActionSheet.Button] = []
        // 네이버지도
        buttons.append(.default(Text("네이버지도")) {
            let urlStr = "nmap://route/public?dlat=\(coordinate.latitude)&dlng=\(coordinate.longitude)&dname=\(name)"
            openMapApp(urlScheme: urlStr, appStoreURL: "itms-apps://itunes.apple.com/app/id311867728")
        })
        // 카카오맵
        buttons.append(.default(Text("카카오맵")) {
            let urlStr = "kakaomap://route?ep=\(coordinate.latitude),\(coordinate.longitude)&by=CAR"
            openMapApp(urlScheme: urlStr, appStoreURL: "itms-apps://itunes.apple.com/app/id304608425")
        })
        // 티맵
        buttons.append(.default(Text("티맵")) {
            let urlStr = "tmap://route?goalname=\(name)&goalx=\(coordinate.longitude)&goaly=\(coordinate.latitude)"
            openMapApp(urlScheme: urlStr, appStoreURL: "itms-apps://itunes.apple.com/app/id431589174")
        })
        // 취소
        buttons.append(.cancel())
        return buttons
    }
    
    // MARK: - 지도앱 실행
    private func openMapApp(urlScheme: String, appStoreURL: String) {
        guard let url = URL(string: urlScheme) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let appStore = URL(string: appStoreURL) {
            UIApplication.shared.open(appStore, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - 프리뷰
#Preview {
    let dummy = PlaceShape(
        id: UUID(),
        title: "드론 비행연습 및 테스트촬영",
        baseCoordinate: Coordinate(latitude: 37.5331, longitude: 126.6342),
        radius: 999,
        memo: "군 담당자 [☎️ 032-510-9226]", address: "인천광역시 서구 청라동 1-791",
        expireDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()), startedAt: Date(),
        color: PaletteColor.blue.hex
    )
    ShapeDetailView(shape: dummy)
}
