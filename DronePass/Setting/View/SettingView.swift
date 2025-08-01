//
//  SettingView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
import Solar
import Combine // Added for Combine

struct SettingView: View {
    @ObservedObject var viewModel: SettingViewModel
    @Binding var showColorPicker: Bool
    
    @State private var showLoginSheet = false
    @State private var showTermsAndPolicies = false
    @State private var navigateToProfile = false
    
    var body: some View {
        List {
            /// 로그인/회원가입 Section
            Section {
                if viewModel.isLoggedIn {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Text("내 프로필")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                } else {
                    Button {
                        showLoginSheet = true
                    } label: {
                        HStack {
                            Text("로그인 / 회원가입")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
            }
            
            // 현 위치 기반 정보 Section
            Section {
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
            } header: {
                Text("현 위치 기반 정보")
            }
            
            // 알림 설정 Section
            Section {
                Toggle(isOn: $viewModel.isEndDateAlarmEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("도형 만료일 알림")
                        Text("도형 종료일 7일전 알림을 받습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.isEndDateAlarmEnabled) { newValue in
                    SettingManager.shared.isEndDateAlarmEnabled = newValue
                }
                
                Toggle(isOn: $viewModel.isSunriseSunsetAlarmEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("일출/일몰 알림")
                        Text("일출/일몰 30분전, 10분전 알림을 받습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.isSunriseSunsetAlarmEnabled) { newValue in
                    SettingManager.shared.isSunriseSunsetAlarmEnabled = newValue
                }
            } header: {
                Text("알림 설정")
            }
            
            // 일반 설정 Section
            Section {
                Button(action: {
                    showColorPicker = true
                }) {
                    Text("도형 색 바꾸기")
                }
                
                Button(role: .destructive) {
                    viewModel.showDeleteExpiredShapesAlert = true
                } label: {
                    Text("만료된 도형 전부 삭제")
                }
            } header: {
                Text("일반 설정")
            }
            
            // 기타 설정 Section
            Section {
                Button {
                    viewModel.showAppInfoSheet = true
                } label: {
                    Text("앱 정보")
                }

                Button {
                    viewModel.fetchAndShowPatchNotes()
                } label: {
                    Text("패치노트")
                }
            } header: {
                Text("기타")
            }
        }
        // 모든 기기에서 sheet로 LoginView 표시
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
        }
        .sheet(isPresented: $viewModel.showPatchNotesSheet) {
            PatchNotesView(
                patchNotes: viewModel.patchNotes,
                isLoading: viewModel.isLoadingPatchNotes
            )
        }
    }
}




// MARK: - ViewModel
final class SettingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var sunriseTime: String = "-"
    @Published var sunriseSuffix: String = ""
    @Published var sunriseSuffixColor: Color = .primary
    
    @Published var sunsetTime: String = "-"
    @Published var sunsetSuffix: String = ""
    @Published var sunsetSuffixColor: Color = .primary
    
    @Published var isEndDateAlarmEnabled: Bool = SettingManager.shared.isEndDateAlarmEnabled
    @Published var isSunriseSunsetAlarmEnabled: Bool = SettingManager.shared.isSunriseSunsetAlarmEnabled
    @Published var selectedColor: Color = .blue
    
    @Published var showDeleteExpiredShapesAlert = false
    @Published var showAppInfoSheet = false
    @Published var showPatchNotesSheet = false
    @Published var patchNotes: [FetchWebDocuments.PatchNote] = []
    @Published var isLoadingPatchNotes = false
    @Published var isLoggedIn: Bool = AppleLoginManager.shared.isLogin // 로그인 상태 관리

    private var loginCancellable: AnyCancellable?
    private var patchNotesCancellables: Set<AnyCancellable> = []
    var webDocuments = FetchWebDocuments()

    var appInfoText: String {
        let features = AppInfo.Description.features.map { "• \($0)" }.joined(separator: "\n")
        return """
        Ver. \(AppInfo.Version.current)

        \(AppInfo.Description.intro)

        [주요 기능]
        \(features)

        \(AppInfo.Description.contact)
        """
    }

    private let locationManager = CLLocationManager()
    private var timer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        // LoginManager의 isLogin을 구독하여 isLoggedIn과 동기화
        loginCancellable = AppleLoginManager.shared.$isLogin
            .receive(on: RunLoop.main)
            .assign(to: \Self.isLoggedIn, on: self)
        
        // FetchWebDocuments의 상태를 구독하여 동기화
        webDocuments.$showPatchNotesSheet
            .receive(on: RunLoop.main)
            .assign(to: \Self.showPatchNotesSheet, on: self)
            .store(in: &patchNotesCancellables)
        
        webDocuments.$patchNotes
            .receive(on: RunLoop.main)
            .assign(to: \Self.patchNotes, on: self)
            .store(in: &patchNotesCancellables)
        
        webDocuments.$isLoadingPatchNotes
            .receive(on: RunLoop.main)
            .assign(to: \Self.isLoadingPatchNotes, on: self)
            .store(in: &patchNotesCancellables)
    }

    func fetchAndShowPatchNotes() {
        webDocuments.fetchAndShowPatchNotes()
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateSunriseSunset(for: location)
        startTimer(location: location)
    }
    
    private func startTimer(location: CLLocation) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateSunriseSunset(for: location)
        }
    }
    
    private func updateSunriseSunset(for location: CLLocation) {
        let now = Date()
        let calendar = Calendar.current
        
        guard let solarToday = Solar(for: now, coordinate: location.coordinate),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let solarTomorrow = Solar(for: tomorrow, coordinate: location.coordinate)
        else {
            sunriseTime = "계산 불가"
            sunsetTime = "계산 불가"
            sunriseSuffix = ""
            sunsetSuffix = ""
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.amSymbol = "오전"
        dateFormatter.pmSymbol = "오후"
        dateFormatter.dateFormat = "a h시 m분"
        dateFormatter.timeZone = TimeZone.current
        
        // 일출/일몰 시간 계산
        let sunriseToday = solarToday.sunrise
        let sunsetToday = solarToday.sunset
        let sunriseTomorrow = solarTomorrow.sunrise
        
        // Helper
        func formatTimeString(hour: Int, minute: Int, suffix: String) -> String {
            if hour > 0 {
                return "\(hour)시간 \(minute)분 \(suffix)"
            } else {
                return "\(minute)분 \(suffix)"
            }
        }
        
        // 1. 자정 이후 ~ 일출 전
        if let sunriseToday = sunriseToday, let sunsetToday = sunsetToday, now < sunriseToday {
            // 일출까지 남은 시간
            let diff = Int(sunriseToday.timeIntervalSince(now))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "남았습니다"
            let redText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            sunriseTime = dateFormatter.string(from: sunriseToday)
            sunriseSuffix = redText
            sunriseSuffixColor = .red
            
            // 일몰까지 남은 시간
            let diffSunset = Int(sunsetToday.timeIntervalSince(now))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "남았습니다"
            let redTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            sunsetTime = dateFormatter.string(from: sunsetToday)
            sunsetSuffix = redTextSunset
            sunsetSuffixColor = .red
            
            // 2. 일출 이후 ~ 일몰 전
        } else if let sunriseToday = sunriseToday, let sunsetToday = sunsetToday, now < sunsetToday {
            // 일출 후 경과 시간
            let diff = Int(now.timeIntervalSince(sunriseToday))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "지났습니다"
            let blueText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            sunriseTime = dateFormatter.string(from: sunriseToday)
            sunriseSuffix = blueText
            sunriseSuffixColor = .blue
            
            // 일몰까지 남은 시간
            let diffSunset = Int(sunsetToday.timeIntervalSince(now))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "남았습니다"
            let redTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            sunsetTime = dateFormatter.string(from: sunsetToday)
            sunsetSuffix = redTextSunset
            sunsetSuffixColor = .red
            
            // 3. 일몰 이후 ~ 자정 전
        } else if let sunriseTomorrow = sunriseTomorrow, let sunsetToday = sunsetToday {
            // 내일 일출까지 남은 시간
            let diff = Int(sunriseTomorrow.timeIntervalSince(now))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "남았습니다"
            let redText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            sunriseTime = dateFormatter.string(from: sunriseTomorrow)
            sunriseSuffix = redText
            sunriseSuffixColor = .red
            
            // 오늘 일몰 후 경과 시간
            let diffSunset = Int(now.timeIntervalSince(sunsetToday))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "지났습니다"
            let blueTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            sunsetTime = dateFormatter.string(from: sunsetToday)
            sunsetSuffix = blueTextSunset
            sunsetSuffixColor = .blue
        }
    }
    
    func setEndDateAlarmEnabled(_ value: Bool) {
        SettingManager.shared.isEndDateAlarmEnabled = value
        isEndDateAlarmEnabled = value
    }
    
    func setSunriseSunsetAlarmEnabled(_ value: Bool) {
        SettingManager.shared.isSunriseSunsetAlarmEnabled = value
        isSunriseSunsetAlarmEnabled = value
    }
    
    func deleteExpiredShapes() {
        SettingManager.shared.deleteExpiredShapes()
    }
}

extension View {
    @ViewBuilder
    func applyNavigationViewStyle(_ horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        if horizontalSizeClass == .regular {
            self.navigationViewStyle(DoubleColumnNavigationViewStyle())
        } else {
            self.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// ViewModifier를 위한 if extension
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    SettingView(viewModel: SettingViewModel(), showColorPicker: .constant(false))
}

