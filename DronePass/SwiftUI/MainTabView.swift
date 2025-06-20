//
//  MainTabView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab: Tab = .map
    @State private var selectedShapeID: UUID? = nil
    @State private var isSavedSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var shapeIDToScrollTo: UUID? = nil
    
    private static let openSavedTabNotification = Notification.Name("OpenSavedTabNotification")
    private static let openSavedTabFromSettingsNotification = Notification.Name("OpenSavedTabFromSettings")
    private static let openSettingsFromSavedNotification = Notification.Name("OpenSettingsFromSaved")

    var body: some View {
        ZStack(alignment: .bottom) {
            // 메인 콘텐츠
            Group {
                switch selectedTab {
                case .map:
                    MainView()
                case .saved:
                    SavedTabPlaceholderView()
                case .settings:
                    // 설정 탭은 오버레이로 표시하므로 placeholder만 표시
                    SettingsTabPlaceholderView()
                }
            }
            
            // 커스텀 탭바 (기기별 다른 위치)
            VStack {
                Spacer()
                
                // 아이패드에서는 좌측 하단, 아이폰에서는 중앙
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // 아이패드: 상단 중앙
                    HStack(spacing: 0) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            CustomTabButton(
                                tab: tab,
                                isSelected: getSelectedTabState(for: tab),
                                action: {
                                    handleTabSelection(tab)
                                }
                            )
                            .frame(width: 60)
                        }
                    }
                    .frame(width: 210, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(radius: 10, x: 0, y: 5)
                    .padding(.top, 20)
                } else {
                    // 아이폰: 하단 중앙
                    HStack(spacing: 0) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            CustomTabButton(
                                tab: tab,
                                isSelected: getSelectedTabState(for: tab),
                                action: {
                                    handleTabSelection(tab)
                                }
                            )
                            .frame(width: 60) // 각 버튼의 너비를 고정
                        }
                    }
                    .frame(width: 210, height: 60) // 전체 너비를 210으로 줄임 (70 * 3)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(radius: 10, x: 0, y: 5)
                    .padding(.bottom, 15)
                }
            }
        }
        .overlay(
            // 저장 목록 오버레이
            Group {
                if isSavedSheetPresented {
                    SavedListOverlayView(
                        selectedShapeID: $selectedShapeID,
                        isPresented: $isSavedSheetPresented,
                        shapeIDToScrollTo: $shapeIDToScrollTo
                    )
                    .transition(.move(edge: getOverlayEdge()).combined(with: .opacity))
                }
            }
        )
        .overlay(
            // 설정 오버레이
            Group {
                if isSettingsSheetPresented {
                    SettingsOverlayView(
                        isPresented: $isSettingsSheetPresented
                    )
                    .transition(.move(edge: getOverlayEdge()).combined(with: .opacity))
                }
            }
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSavedSheetPresented)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSettingsSheetPresented)
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
        }
    }
    
    // 탭 선택 상태 계산 함수
    private func getSelectedTabState(for tab: Tab) -> Bool {
        switch tab {
        case .map:
            return selectedTab == .map && !isSavedSheetPresented && !isSettingsSheetPresented
        case .saved:
            return isSavedSheetPresented
        case .settings:
            return isSettingsSheetPresented
        }
    }
    
    // 탭 선택 처리 함수
    private func handleTabSelection(_ tab: Tab) {
        switch tab {
        case .map:
            // 지도 탭: 저장뷰와 설정창 모두 닫기
            isSavedSheetPresented = false
            isSettingsSheetPresented = false
            selectedTab = .map
        case .saved:
            // 저장 탭: 이미 열려있으면 닫고 지도로 돌아가기
            if isSavedSheetPresented {
                isSavedSheetPresented = false
                selectedTab = .map
            } else {
                // 설정창이 열려있으면 닫고 저장뷰 열기
                isSettingsSheetPresented = false
                isSavedSheetPresented = true
            }
        case .settings:
            // 설정 탭: 이미 열려있으면 닫고 지도로 돌아가기
            if isSettingsSheetPresented {
                isSettingsSheetPresented = false
                selectedTab = .map
            } else {
                // 저장뷰가 열려있으면 닫고 설정창 열기
                isSavedSheetPresented = false
                isSettingsSheetPresented = true
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: Self.openSavedTabNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let shapeID = notification.object as? UUID {
                // 1. 하이라이트를 위해 selectedShapeID는 즉시 업데이트합니다.
                self.selectedShapeID = shapeID

                // 2. 시트가 닫혀있었다면, 애니메이션 시간을 고려하여 스크롤을 지연 실행합니다.
                if !self.isSavedSheetPresented {
                    self.isSavedSheetPresented = true
                    // 애니메이션 시간(response: 0.5)보다 약간 긴 딜레이를 줍니다.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.shapeIDToScrollTo = shapeID
                    }
                } else {
                    // 시트가 이미 열려있었다면, 바로 스크롤을 실행합니다.
                    self.shapeIDToScrollTo = shapeID
                }
            }
        }
        
        // 설정창에서 저장 탭 열기 알림 처리
        NotificationCenter.default.addObserver(
            forName: Self.openSavedTabFromSettingsNotification,
            object: nil,
            queue: .main
        ) { _ in
            // 설정창을 닫고 저장뷰 열기
            isSettingsSheetPresented = false
            isSavedSheetPresented = true
        }
        
        // 저장뷰에서 설정 탭 열기 알림 처리
        NotificationCenter.default.addObserver(
            forName: Self.openSettingsFromSavedNotification,
            object: nil,
            queue: .main
        ) { _ in
            // 저장뷰를 닫고 설정창 열기
            isSavedSheetPresented = false
            isSettingsSheetPresented = true
        }
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func getOverlayEdge() -> Edge {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // 아이패드 미니에서만 세로 모드일 때 하단에 표시
            if UIDevice.current.model == "iPad" && UIScreen.main.bounds.width < 768 {
                return .bottom
            } else {
                // 다른 아이패드들은 좌측에 표시
                return .leading
            }
        } else {
            return .bottom
        }
    }
}

// MARK: - Supporting Types
extension MainTabView {
    enum Tab: CaseIterable {
        case map, saved, settings
        
        var title: String {
            switch self {
            case .map: return "지도"
            case .saved: return "저장"
            case .settings: return "설정"
            }
        }
        
        var icon: String {
            switch self {
            case .map: return "map"
            case .saved: return "tray.full"
            case .settings: return "gearshape"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .map: return "map.fill"
            case .saved: return "tray.full.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Saved Tab Placeholder View
struct SavedTabPlaceholderView: View {
    var body: some View {
        // 투명한 뷰이지만 실제 뷰로 존재
        Color.clear
            .contentShape(Rectangle()) // 터치 영역 확보
    }
}

// MARK: - Settings Tab Placeholder View
struct SettingsTabPlaceholderView: View {
    var body: some View {
        // 투명한 뷰이지만 실제 뷰로 존재
        Color.clear
            .contentShape(Rectangle()) // 터치 영역 확보
    }
}

// MARK: - Saved List Overlay View
struct SavedListOverlayView: View {
    @Binding var selectedShapeID: UUID?
    @Binding var isPresented: Bool
    @Binding var shapeIDToScrollTo: UUID?
    @StateObject private var placeShapeStore = PlaceShapeStore.shared
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let dismissThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isLandscape {
                // 아이패드 가로 모드: 좌측에 표시
                HStack {
                    VStack(spacing: 0) {
                        // 드래그 핸들과 헤더를 포함하는 상단 영역
                        VStack(spacing: 0) {
                            // 드래그 핸들
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(UIColor.systemGray3))
                                .frame(width: 40, height: 5)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            
                            // 헤더
                            HStack {
                                Text("저장 목록")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if !placeShapeStore.shapes.isEmpty {
                                    Text("\(placeShapeStore.shapes.count)개")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                        .background(Color(UIColor.systemBackground))
                        .zIndex(1)
                        
                        // 저장된 항목 목록
                        SavedTableListView(
                            selectedShapeID: $selectedShapeID,
                            shapeIDToScrollTo: $shapeIDToScrollTo
                        )
                            .padding(.top, 8)
                            .zIndex(0)
                    }
                    .frame(width: min(geometry.size.width * 0.4, 400))
                    .frame(maxHeight: geometry.size.height * 0.75)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = max(0, gesture.translation.width)
                            }
                            .onEnded { gesture in
                                isDragging = false
                                if gesture.translation.width > dismissThreshold {
                                    withAnimation(.spring()) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .padding(.leading, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 0)
                    
                    Spacer()
                }
            } else {
                // 아이폰 또는 아이패드 세로 모드: 하단에 표시
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // 드래그 핸들과 헤더를 포함하는 상단 영역
                        VStack(spacing: 0) {
                            // 드래그 핸들
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(UIColor.systemGray3))
                                .frame(width: 40, height: 5)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            
                            // 헤더
                            HStack {
                                Text("저장 목록")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if !placeShapeStore.shapes.isEmpty {
                                    Text("\(placeShapeStore.shapes.count)개")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                        .background(Color(UIColor.systemBackground))
                        .zIndex(1)
                        
                        // 저장된 항목 목록
                        SavedTableListView(
                            selectedShapeID: $selectedShapeID,
                            shapeIDToScrollTo: $shapeIDToScrollTo
                        )
                            .padding(.top, 8)
                            .zIndex(0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: min(geometry.size.height * 0.5, 500))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .phone ? 40 : 16))
                    .shadow(radius: 10)
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = max(0, gesture.translation.height)
                            }
                            .onEnded { gesture in
                                isDragging = false
                                if gesture.translation.height > dismissThreshold {
                                    withAnimation(.spring()) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Settings Overlay View
struct SettingsOverlayView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SettingViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showColorPicker = false
    
    private let dismissThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isLandscape {
                // 아이패드 가로 모드: 좌측에 표시
                HStack {
                    VStack(spacing: 0) {
                        // 드래그 핸들과 헤더를 포함하는 상단 영역
                        VStack(spacing: 0) {
                            // 드래그 핸들
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(UIColor.systemGray3))
                                .frame(width: 40, height: 5)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            
                            // 헤더
                            HStack {
                                Text("설정")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                        .background(Color(UIColor.systemBackground))
                        .zIndex(1)
                        
                        // 설정 내용
                        SettingsContentView(
                            viewModel: viewModel,
                            showColorPicker: $showColorPicker
                        )
                            .padding(.top, 8)
                            .zIndex(0)
                    }
                    .frame(width: min(geometry.size.width * 0.4, 400))
                    .frame(maxHeight: geometry.size.height * 0.75)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = max(0, gesture.translation.width)
                            }
                            .onEnded { gesture in
                                isDragging = false
                                if gesture.translation.width > dismissThreshold {
                                    withAnimation(.spring()) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            } else {
                // 아이폰 또는 아이패드 세로 모드: 하단에 표시
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // 드래그 핸들과 헤더를 포함하는 상단 영역
                        VStack(spacing: 0) {
                            // 드래그 핸들
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(UIColor.systemGray3))
                                .frame(width: 40, height: 5)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            
                            // 헤더
                            HStack {
                                Text("설정")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                        .background(Color(UIColor.systemBackground))
                        .zIndex(1)
                        
                        // 설정 내용
                        SettingsContentView(
                            viewModel: viewModel,
                            showColorPicker: $showColorPicker
                        )
                            .padding(.top, 8)
                            .zIndex(0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: min(geometry.size.height * 0.5, 500))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .phone ? 40 : 16))
                    .shadow(radius: 10)
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = max(0, gesture.translation.height)
                            }
                            .onEnded { gesture in
                                isDragging = false
                                if gesture.translation.height > dismissThreshold {
                                    withAnimation(.spring()) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(
                selected: ColorManager.shared.defaultColor,
                onColorSelected: { color in
                    // 선택된 색상 처리
                    ColorManager.shared.defaultColor = color
                    showColorPicker = false
                }
            )
            .presentationDetents(
                UIDevice.current.userInterfaceIdiom == .pad 
                ? [.fraction(0.87)] // 0.7 * 1.2 = 0.84
                : [.fraction(0.6)]
            )
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Settings Content View
struct SettingsContentView: View {
    @ObservedObject var viewModel: SettingViewModel
    @Binding var showColorPicker: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 현 위치 기반 정보 Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("현 위치 기반 정보")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("일출: \(viewModel.sunriseTime)")
                            Spacer()
                            Text(viewModel.sunriseSuffix)
                                .foregroundColor(viewModel.sunriseSuffixColor)
                                .font(.caption)
                        }
                        HStack {
                            Text("일몰: \(viewModel.sunsetTime)")
                            Spacer()
                            Text(viewModel.sunsetSuffix)
                                .foregroundColor(viewModel.sunsetSuffixColor)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 알림 설정 Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("알림 설정")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        Toggle(isOn: $viewModel.isEndDateAlarmEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("종료일 알림")
                                Text("도형 종료일 7일전 알림을 받습니다.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.isEndDateAlarmEnabled) { value in
                            viewModel.setEndDateAlarmEnabled(value)
                        }

                        Toggle(isOn: $viewModel.isSunriseSunsetAlarmEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("일출/일몰 알림")
                                Text("일출/일몰 30분전, 10분전 알림을 받습니다.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.isSunriseSunsetAlarmEnabled) { value in
                            viewModel.setSunriseSunsetAlarmEnabled(value)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 일반 설정 Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("일반 설정")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showColorPicker = true
                        }) {
                            HStack {
                                Text("도형 색 바꾸기")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(role: .destructive) {
                            viewModel.showDeleteExpiredShapesAlert = true
                        } label: {
                            HStack {
                                Text("만료된 도형 전부 삭제")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 기타 설정 Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("기타 설정")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Button {
                        viewModel.showAppInfoAlert = true
                    } label: {
                        HStack {
                            Text("앱 정보")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .alert("만료된 도형을 모두 삭제할까요?", isPresented: $viewModel.showDeleteExpiredShapesAlert) {
            Button("삭제", role: .destructive) {
                viewModel.deleteExpiredShapes()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("종료일이 지난 도형을 모두 삭제합니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .alert("앱 정보", isPresented: $viewModel.showAppInfoAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.appInfoText)
        }
        .onAppear {
            viewModel.requestLocation()
        }
    }
}

#Preview {
    MainTabView()
}
