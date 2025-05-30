//
//  SettingViewController.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 앱의 설정 화면을 담당하는 뷰 컨트롤러
// 연관기능: 설정 UI, 사용자 환경설정

import UIKit         // iOS의 화면(UI) 관련 기능을 사용하기 위한 프레임워크
import CoreLocation  // 위치(GPS) 관련 기능을 사용하기 위한 프레임워크
import Solar         // 일출/일몰 계산 라이브러리
import WeatherKit    // 날씨 라이브러리






// UIViewController: 화면의 한 페이지(뷰 컨트롤러) 역할을 하는 클래스
// CLLocationManagerDelegate: 위치 정보 업데이트 이벤트를 받을 수 있게 해주는 프로토콜
// UITableViewDelegate, UITableViewDataSource: 테이블뷰(목록) 구성에 필요한 프로토콜
class SettingViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    // MARK: - Properties(속성)
    private let locationManager = CLLocationManager()   // 위치(GPS) 정보를 얻기 위한 객체
    private var currentLocation: CLLocation?            // 현재 위치 정보 저장용 (옵셔널: 값이 없을 수 있음)
    private let weatherService = WeatherService()
    
    // 타이머 생성
    private var timer: Timer?

    
    // infoContainerView에 들어갈 섹션 헤더 라벨 선언
    private let infoContainerHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "현 위치 기반 정보"             // 섹션 제목
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel        // 연한 회색(시스템 스타일)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let windSpeedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let windDirectionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // MARK: - 전역 타이머
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else {
                print("currentLocation이 없음")
                return
            }
            self.updateSunriseSunsetInfo(for: location)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formatTimeString(hour: Int, minute: Int, suffix: String) -> String {
        if hour > 0 {
            return "\(hour)시간 \(minute)분 \(suffix)"
        } else {
            return "\(minute)분 \(suffix)"
        }
    }
    
    
    // MARK: - 일출/일몰 함수

    func colorForSuffix(_ suffix: String) -> UIColor {
        if suffix.contains("남았습니다") {
            return UIColor.systemRed
        } else if suffix.contains("지났습니다") {
            return UIColor.systemBlue
        }
        return UIColor.label
    }
    
    // MARK: - UI Components(화면 구성 요소)
    // 일출/일몰 정보를 담는 박스(UIView)
    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground     // 시스템 기본 배경색(라이트/다크모드 지원)
        view.layer.cornerRadius = 12                 // 둥근 테두리
        view.layer.shadowColor = UIColor.black.cgColor      // 그림자 색
        view.layer.shadowOffset = CGSize(width: 0, height: 2) // 그림자 위치
        view.layer.shadowOpacity = 0.1               // 그림자 투명도
        view.layer.shadowRadius = 4                  // 그림자 번짐 정도
        view.translatesAutoresizingMaskIntoConstraints = false // 오토레이아웃을 직접 제어
        return view
    }()
    
    // 일출 시간 표시 라벨
    private let sunriseLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium) // 글씨 크기/굵기
        label.textColor = .label                              // 시스템 기본 텍스트 색
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 일몰 시간 표시 라벨
    private let sunsetLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 설정 항목 리스트(테이블뷰)
    private let settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped) // 그룹 스타일
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Lifecycle(생명주기 메서드)
  override func viewDidLoad() {
    super.viewDidLoad()
        setupUI()                // UI(화면 요소) 구성
        setupLocationManager()   // 위치 매니저 설정
        setupTableView()         // 테이블뷰 설정
        // ✅ 만료 도형 삭제 등 데이터 변경 시 테이블뷰 갱신
        NotificationCenter.default.addObserver(self, selector: #selector(handleShapesDidChange), name: .shapesDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimer()
        LocationManager.shared.startUpdatingLocation()
        // 위치 업데이트를 받으면 일출/일몰 정보 업데이트
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(handleLocationUpdate(_:)), 
                                             name: NSNotification.Name("LocationDidUpdate"), 
                                             object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let location = self.currentLocation {
            self.updateSunriseSunsetInfo(for: location)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
        LocationManager.shared.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup(설정)
    private func setupUI() {
        // 화면 배경색 지정
        view.backgroundColor = .systemGroupedBackground
        title = "설정"   // 네비게이션 타이틀
        
        // 화면에 각 UI 요소 추가
        view.addSubview(infoContainerView)
        infoContainerView.addSubview(infoContainerHeaderLabel)
        infoContainerView.addSubview(temperatureLabel)
        infoContainerView.addSubview(windSpeedLabel)
        infoContainerView.addSubview(windDirectionLabel)
        infoContainerView.addSubview(sunriseLabel)
        infoContainerView.addSubview(sunsetLabel)
        view.addSubview(settingsTableView)
        
        // 오토레이아웃(위치 및 크기 제약 조건) 설정
        NSLayoutConstraint.activate([
            // infoContainerView(일출/일몰 정보 박스) 위치 및 크기
            infoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            infoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.11), // 인포박스 상하크기
            
            // 헤더라벨은 infoContainerView의 top에 붙임
            infoContainerHeaderLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 11),
            infoContainerHeaderLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            infoContainerHeaderLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
//            temperatureLabel.topAnchor.constraint(equalTo: infoContainerHeaderLabel.bottomAnchor, constant: 10),
//            temperatureLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
//            temperatureLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
//            
//            windSpeedLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 6),
//            windSpeedLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
//            windSpeedLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
//            
//            windDirectionLabel.topAnchor.constraint(equalTo: windSpeedLabel.bottomAnchor, constant: 6),
//            windDirectionLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
//            windDirectionLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // sunriseLabel(일출 라벨) 위치
            sunriseLabel.topAnchor.constraint(equalTo: windDirectionLabel.bottomAnchor, constant: 42), // 높이. 날씨 살리고 여기 줄일것
            sunriseLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            sunriseLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // sunsetLabel(일몰 라벨) 위치
            sunsetLabel.topAnchor.constraint(equalTo: sunriseLabel.bottomAnchor, constant: 8),
            sunsetLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            sunsetLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // settingsTableView(설정 테이블) 위치 및 크기
            settingsTableView.topAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: 16),
            settingsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // 위치(GPS) 관련 매니저 설정
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // 설정 목록(테이블뷰) 관련 설정
    private func setupTableView() {
        settingsTableView.delegate = self        // 테이블뷰 이벤트 처리 위임
        settingsTableView.dataSource = self      // 테이블뷰 데이터 제공 위임
        settingsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell") // 셀 등록
        
    }

    
    // MARK: - Location Update Handler
    @objc private func handleLocationUpdate(_ notification: Notification) {
        if let location = notification.userInfo?["location"] as? CLLocation {
            updateSunriseSunsetInfo(for: location)
            
            // 일출/일몰 알림이 활성화되어 있다면 알림 스케줄링
            if SettingManager.shared.isSunriseSunsetAlarmEnabled {
                SettingManager.shared.scheduleSunriseSunsetAlarms(for: location.coordinate)
            }
        }
    }
    
    // 현재 위치 기반으로 일출/일몰 시간 계산 및 UI 업데이트
    private func updateSunriseSunsetInfo(for location: CLLocation) {
        let now = Date()
        let calendar = Calendar.current

        guard let solarToday = Solar(for: now, coordinate: location.coordinate),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let solarTomorrow = Solar(for: tomorrow, coordinate: location.coordinate)
        else {
            sunriseLabel.text = "일출 시간: 계산 불가"
            sunsetLabel.text = "일몰 시간: 계산 불가"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.amSymbol = "오전"
        dateFormatter.pmSymbol = "오후"
        dateFormatter.dateFormat = "a h시 m분"
        dateFormatter.timeZone = TimeZone.current

        guard let sunriseToday = solarToday.sunrise,
              let sunsetToday = solarToday.sunset,
              let sunriseTomorrow = solarTomorrow.sunrise else {
            sunriseLabel.text = "일출 시간: 계산 불가"
            sunsetLabel.text = "일몰 시간: 계산 불가"
            return
        }

        // Helper: 색상 선택
        func colorForSuffix(_ suffix: String) -> UIColor {
            if suffix.contains("남았습니다") {
                return UIColor.systemRed
            } else if suffix.contains("지났습니다") {
                return UIColor.systemBlue
            }
            return UIColor.label
        }

        // 1. 자정 이후 ~ 일출 전
        if now < sunriseToday {
            // 일출
            let diff = Int(sunriseToday.timeIntervalSince(now))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "남았습니다"
            let redText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            let sunriseText = "일출 시간: \(dateFormatter.string(from: sunriseToday)) - \(redText)"
            let sunriseAttr = NSMutableAttributedString(string: sunriseText)
            if let range = sunriseText.range(of: redText) {
                sunriseAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffix), range: NSRange(range, in: sunriseText))
            }
            sunriseLabel.attributedText = sunriseAttr

            // 일몰
            let diffSunset = Int(sunsetToday.timeIntervalSince(now))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "남았습니다"
            let redTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            let sunsetText = "일몰 시간: \(dateFormatter.string(from: sunsetToday)) - \(redTextSunset)"
            let sunsetAttr = NSMutableAttributedString(string: sunsetText)
            if let range = sunsetText.range(of: redTextSunset) {
                sunsetAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffixSunset), range: NSRange(range, in: sunsetText))
            }
            sunsetLabel.attributedText = sunsetAttr

        // 2. 일출 이후 ~ 일몰 전
        } else if now < sunsetToday {
            // 일출
            let diff = Int(now.timeIntervalSince(sunriseToday))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "지났습니다"
            let blueText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            let sunriseText = "일출 시간: \(dateFormatter.string(from: sunriseToday)) - \(blueText)"
            let sunriseAttr = NSMutableAttributedString(string: sunriseText)
            if let range = sunriseText.range(of: blueText) {
                sunriseAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffix), range: NSRange(range, in: sunriseText))
            }
            sunriseLabel.attributedText = sunriseAttr

            // 일몰
            let diffSunset = Int(sunsetToday.timeIntervalSince(now))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "남았습니다"
            let redTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            let sunsetText = "일몰 시간: \(dateFormatter.string(from: sunsetToday)) - \(redTextSunset)"
            let sunsetAttr = NSMutableAttributedString(string: sunsetText)
            if let range = sunsetText.range(of: redTextSunset) {
                sunsetAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffixSunset), range: NSRange(range, in: sunsetText))
            }
            sunsetLabel.attributedText = sunsetAttr

        // 3. 일몰 이후 ~ 자정 전
        } else {
            // 일출 (내일)
            let diff = Int(sunriseTomorrow.timeIntervalSince(now))
            let hour = diff / 3600
            let minute = (diff % 3600) / 60
            let suffix = "남았습니다"
            let redText = formatTimeString(hour: hour, minute: minute, suffix: suffix)
            let sunriseText = "일출 시간: \(dateFormatter.string(from: sunriseTomorrow)) - \(redText)"
            let sunriseAttr = NSMutableAttributedString(string: sunriseText)
            if let range = sunriseText.range(of: redText) {
                sunriseAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffix), range: NSRange(range, in: sunriseText))
            }
            sunriseLabel.attributedText = sunriseAttr

            // 일몰 (오늘)
            let diffSunset = Int(now.timeIntervalSince(sunsetToday))
            let hourSunset = diffSunset / 3600
            let minuteSunset = (diffSunset % 3600) / 60
            let suffixSunset = "지났습니다"
            let blueTextSunset = formatTimeString(hour: hourSunset, minute: minuteSunset, suffix: suffixSunset)
            let sunsetText = "일몰 시간: \(dateFormatter.string(from: sunsetToday)) - \(blueTextSunset)"
            let sunsetAttr = NSMutableAttributedString(string: sunsetText)
            if let range = sunsetText.range(of: blueTextSunset) {
                sunsetAttr.addAttribute(.foregroundColor, value: colorForSuffix(suffixSunset), range: NSRange(range, in: sunsetText))
            }
            sunsetLabel.attributedText = sunsetAttr
        }
    }
    
    // MARK: - 기상관련 구현 코드 (일단 비활성화중)

//    private func updateWeatherInfo(for coordinate: CLLocationCoordinate2D) {
//        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//        Task {
//            do {
//                let weather = try await weatherService.weather(for: location)
//                let current = weather.currentWeather
//                DispatchQueue.main.async {
//                    self.temperatureLabel.text = "기온: \(current.temperature.value)\(current.temperature.unit.symbol)"
//                    self.windSpeedLabel.text = "풍속: \(current.wind.speed.value)\(current.wind.speed.unit.symbol)"
//                    self.windDirectionLabel.text = "풍향: \(Int(current.wind.direction.value))°"
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.temperatureLabel.text = "기온: -"
//                    self.windSpeedLabel.text = "풍속: -"
//                    self.windDirectionLabel.text = "풍향: -"
//                }
//            }
//        }
//    }
    
    // MARK: - UITableViewDataSource(테이블뷰 데이터 관련)
    // 섹션 개수 (지도/알림/기타)
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    // 각 섹션별 셀 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // 알림 설정
        case 1: return 2 // 일반 설정
        case 2: return 1 // 기타 설정
        default: return 0
        }
    }
    
    // 각 섹션 헤더 타이틀(상단 제목)
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "알림 설정"
        case 1: return "일반 설정"
        case 2: return "기타 설정"
        default: return nil
        }
    }
    
    // 각 셀(행) 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellStyle: UITableViewCell.CellStyle = .subtitle
        let cell = UITableViewCell(style: cellStyle, reuseIdentifier: "SettingCell")
        
        switch indexPath.section {
        case 0: // 알림 설정
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "종료일 알림"
                cell.detailTextLabel?.text = "도형 종료일 7일전 알림을 받습니다."
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.font = .systemFont(ofSize: 13)
                let endDateSwitch = UISwitch()
                endDateSwitch.isOn = SettingManager.shared.isEndDateAlarmEnabled
                endDateSwitch.tag = 0
                endDateSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
                cell.accessoryView = endDateSwitch
            case 1:
                cell.textLabel?.text = "일출/일몰 알림"
                cell.detailTextLabel?.text = "일출/일몰 30분전, 10분전 알림을 받습니다."
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.font = .systemFont(ofSize: 13)
                let sunriseSwitch = UISwitch()
                sunriseSwitch.isOn = SettingManager.shared.isSunriseSunsetAlarmEnabled
                sunriseSwitch.tag = 1
                sunriseSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
                cell.accessoryView = sunriseSwitch
            default: break
            }
        case 1: // 일반 설정
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "도형 색 바꾸기"
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = "만료된 도형 전부 삭제"
                cell.accessoryType = .disclosureIndicator
      
            default: break
            }
        case 2: // 기타 설정
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "앱 정보"
                cell.accessoryType = .disclosureIndicator
            default: break
            }
        default: break
        }
        return cell
    }
    
    // 셀 클릭 이벤트 처리 (예: 상세 설정 화면 이동)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1: // 일반 설정
            switch indexPath.row {
            case 0:
                showColorPicker()
            case 1:
                let alert = UIAlertController(
                    title: "확인",
                    message: "종료일이 지난 도형을 모두 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                    SettingManager.shared.deleteExpiredShapes()
                    PlaceShapeStore.shared.deleteExpiredShapes()
                    self.settingsTableView.reloadData()
                })
                present(alert, animated: true)
            default: break
            }
        case 2: // 기타 설정
            switch indexPath.row {
            case 0: // 앱 정보
                showAppInfo()
            default: break
            }
        default: break
        }
    }

            
    
    // MARK: - Switch Action
    @objc private func switchValueChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            SettingManager.shared.isEndDateAlarmEnabled = sender.isOn
            if sender.isOn {
                // ShapeManager를 통해 저장된 도형 데이터를 가져와서 알림 스케줄링
                let shapes = ShapeManager.shared.getAllShapes()
                SettingManager.shared.scheduleEndDateAlarms(for: shapes)
            }
        case 1:
            SettingManager.shared.isSunriseSunsetAlarmEnabled = sender.isOn
            if sender.isOn, let location = LocationManager.shared.currentLocation {
                // 현재 위치 기반으로 일출/일몰 알림 스케줄링
                SettingManager.shared.scheduleSunriseSunsetAlarms(for: location.coordinate)
            }
        default:
            break
        }
        settingsTableView.reloadData()
    }
    
    // MARK: - App Info
    private func showAppInfo() {
        // 앱 소개 문구와 기능 목록을 하나의 문자열로 만듭니다
        let features = AppInfo.Description.features.map { "• \($0)" }.joined(separator: "\n")
        let message = """
        Ver. \(AppInfo.Version.current)

        \(AppInfo.Description.intro)
        
        [주요 기능]
        \(features)
        
        \(AppInfo.Description.contact)
        """
        
        let alert = UIAlertController(
            title: "DronePass",
            message: message,
            preferredStyle: .alert
        )
        
        // 확인 버튼 추가
        alert.addAction(UIAlertAction(
            title: "확인",
            style: .default
        ))
        
        // 알림창 표시
        present(alert, animated: true)
    }
    
    // MARK: - Color Picker
    private func showColorPicker() {
        let colorPicker = ColorPickerViewController()
        colorPicker.onColorSelected = { [weak self] selectedColor in
            // 선택된 색상 처리
            self?.handleColorSelection(selectedColor)
        }
        
        // 모달로 표시
        let navController = UINavigationController(rootViewController: colorPicker)
        navController.modalPresentationStyle = .pageSheet
        
        // 닫기 버튼 추가
        let closeButton = UIBarButtonItem(
            title: "닫기",
            style: .plain,
            target: self,
            action: #selector(dismissColorPicker)
        )
        colorPicker.navigationItem.leftBarButtonItem = closeButton
        
        present(navController, animated: true)
    }
    
    @objc private func dismissColorPicker() {
        dismiss(animated: true)
    }
    
    private func handleColorSelection(_ color: PaletteColor) {
        // ColorManager를 통해 기본 색상 변경
        ColorManager.shared.defaultColor = color
        
        // 변경 알림
        let alert = UIAlertController(
            title: "색상 변경",
            message: "새로 생성되는 도형의 기본 색상이 변경되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - CLLocationManagerDelegate(위치정보 콜백)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("didUpdateLocations: location 없음")
            return
        }
        currentLocation = location
        updateSunriseSunsetInfo(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 업데이트 실패: \(error.localizedDescription)")
        sunriseLabel.text = "일출 시간: 위치 정보 없음"
        sunsetLabel.text = "일몰 시간: 위치 정보 없음"
  }

    @objc private func handleShapesDidChange() {
        settingsTableView.reloadData()
  }
}
