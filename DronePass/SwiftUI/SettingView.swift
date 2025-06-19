//
//  SettingView.swift
//  DronePass
//
//  Created by 문주성 on 6/11/25.
//

import SwiftUI
import CoreLocation
import Solar

struct SettingView: View {
    @StateObject private var viewModel = SettingViewModel()
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
            NavigationView {
                List {
                    // 현 위치 기반 정보 Section
                    Section(header: Text("현 위치 기반 정보")) {
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
                    }
                    
                    // 알림 설정 Section
                    Section(header: Text("알림 설정")) {
                        Toggle(isOn: $viewModel.isEndDateAlarmEnabled) {
                            VStack(alignment: .leading) {
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
                            VStack(alignment: .leading) {
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

                    // 일반 설정 Section
                    Section(header: Text("일반 설정")) {
                        NavigationLink {
                            ColorPickerView(
                                selected: ColorManager.shared.defaultColor,
                                onColorSelected: { color in
                                    // 선택된 색상 처리
                                }
                            )
                        } label: {
                            Text("도형 색 바꾸기")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.showDeleteExpiredShapesAlert = true
                        } label: {
                            Text("만료된 도형 전부 삭제")
                        }
                    }

                    // 기타 설정 Section
                    Section(header: Text("기타 설정")) {
                        Button {
                            viewModel.showAppInfoAlert = true
                        } label: {
                            Text("앱 정보")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitleDisplayMode(.inline)
                .padding(.top, 20)
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
            .navigationViewStyle(StackNavigationViewStyle())
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
    @Published var showAppInfoAlert = false

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

#Preview {
    SettingView()
}
