//
//  MainTabView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    enum Tab {
        case map, saved, settings
    }
    @State private var selectedTab: Tab = .map
    @State private var isSavedSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var selectedShapeID: UUID? = nil
    
    // NotificationCenter 상수 정의
    private static let openSavedTabNotification = Notification.Name("OpenSavedTabNotification")

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // ⭐️ 지도는 항상 맨 아래, 절대 재생성 안 함!
                MainView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemBackground))
                    .ignoresSafeArea()
                    .zIndex(0)

                // 저장 sheet 오버레이
                if isSavedSheetPresented {
                    SavedOverlayView(
                        isPresented: $isSavedSheetPresented,
                        selectedShapeID: $selectedShapeID
                    )
                        .frame(width: min(geometry.size.width, 500),
                           height: geometry.size.height * 0.6 - 40)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(radius: 20)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                        .position(x: geometry.size.width / 2,
                              y: geometry.size.height - (geometry.size.height * 0.25) - 40)
                }

                // 설정 sheet 오버레이 (탭바 위에 항상 보이게)
                if isSettingsSheetPresented {
                    VStack(spacing: 0) {
                        HStack {
                            Text("설정")
                                .font(.headline)
                            Spacer()
                            Button(action: { isSettingsSheetPresented = false }) {
                                Image(systemName: "xmark")
                                    .padding(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        Divider()
                        SettingView()
                        Spacer()
                    }
                    .frame(width: min(geometry.size.width, 500),
                           height: geometry.size.height * 1.5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .shadow(radius: 20)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height / 3 + 250) // 탭바 위에 자연스럽게
                }

                // 탭바
                HStack(spacing: 0) {
                    TabButton(icon: "map", title: "지도", isSelected: selectedTab == .map) {
                        selectedTab = .map
                        isSavedSheetPresented = false
                        isSettingsSheetPresented = false
                    }
                    TabButton(icon: "tray.full", title: "저장", isSelected: selectedTab == .saved) {
                        if selectedTab == .saved && isSavedSheetPresented {
                            isSavedSheetPresented = false
                            selectedTab = .map
                        } else {
                            selectedTab = .saved
                            isSavedSheetPresented = true
                            isSettingsSheetPresented = false
                        }
                    }
                    TabButton(icon: "gearshape", title: "설정", isSelected: selectedTab == .settings) {
                        if selectedTab == .settings && isSettingsSheetPresented {
                            isSettingsSheetPresented = false
                            selectedTab = .map
                        } else {
                            selectedTab = .settings
                            isSettingsSheetPresented = true
                            isSavedSheetPresented = false
                        }
                    }
                }
                .frame(
                    width: UIDevice.current.userInterfaceIdiom == .pad ? 320 : geometry.size.width,
                    height: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 70
                )
                .background(.ultraThinMaterial)
                .cornerRadius(UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
                .shadow(radius: 8)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.all, edges: .bottom)
                .zIndex(2) // 항상 최상단
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: Self.openSavedTabNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let shapeID = notification.object as? UUID {
                selectedShapeID = shapeID
                isSavedSheetPresented = true
            }
        }
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// 탭 버튼 컴포넌트
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .accentColor : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.bottom, 10)
        }
    }
}

// 지도 메인 뷰 (기존 MapViewController 참고)
struct MapMainView: View {
    var body: some View {
        MainView()
    }
}

// 저장 오버레이 뷰 (기존 SavedBottomSheetViewController 참고)
struct SavedOverlayView: View {
    @Binding var isPresented: Bool
    @Binding var selectedShapeID: UUID?

    var body: some View {
        VStack {
            HStack {
                Text("저장 목록")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 5)
//            Divider()
            // 저장 목록 내용
            SavedTableListView(selectedShapeID: $selectedShapeID)
            Spacer()
        }
    }
}

#Preview {
    MainTabView()
}
