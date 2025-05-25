//
//  SettingViewController.swift
//  MapSketch
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
    }
    
    // MARK: - 날씨데이터 데모

    class WeatherInfo: NSObject {
        let weatherService = WeatherService()
        
        func fetchWeather(for coordinate: CLLocationCoordinate2D) {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            Task {
                do {
                    let weather = try await weatherService.weather(for: location)
                    let current = weather.currentWeather
                    print("기온:", current.temperature.value, current.temperature.unit.symbol)
                    print("풍속:", current.wind.speed.value, current.wind.speed.unit.symbol)
                    print("풍향:", current.wind.direction.value)
                } catch {
                    print("날씨 데이터 오류:", error.localizedDescription)
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation() // 화면이 보일 때 위치 정보 받기 시작
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation() // 화면이 사라질 때 위치 정보 받기 중지
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
            infoContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.23),
            
            // 헤더라벨은 infoContainerView의 top에 붙임
            infoContainerHeaderLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 12),
            infoContainerHeaderLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            infoContainerHeaderLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            temperatureLabel.topAnchor.constraint(equalTo: infoContainerHeaderLabel.bottomAnchor, constant: 10),
            temperatureLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            temperatureLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            windSpeedLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 6),
            windSpeedLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            windSpeedLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            windDirectionLabel.topAnchor.constraint(equalTo: windSpeedLabel.bottomAnchor, constant: 6),
            windDirectionLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            windDirectionLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // sunriseLabel(일출 라벨) 위치
            sunriseLabel.topAnchor.constraint(equalTo: windDirectionLabel.bottomAnchor, constant: 12),
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
        locationManager.delegate = self                          // 내 컨트롤러에서 위치 업데이트 콜백 받기
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 가장 정확한 위치 정보 요청
        locationManager.requestWhenInUseAuthorization()           // 앱 실행 중에만 위치 사용 허가 요청
    }
    
    // 설정 목록(테이블뷰) 관련 설정
    private func setupTableView() {
        settingsTableView.delegate = self        // 테이블뷰 이벤트 처리 위임
        settingsTableView.dataSource = self      // 테이블뷰 데이터 제공 위임
        settingsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell") // 셀 등록
    }
    
    // 현재 위치 기반으로 일출/일몰 시간 계산 및 UI 업데이트
    private func updateSunriseSunsetInfo() {
        guard let location = currentLocation else { return } // 위치 정보가 없으면 아무것도 하지 않음
        
        // Solar 라이브러리를 활용해 일출/일몰 계산 (위치, 날짜 기반)
        if let solar = Solar(for: Date(), coordinate: location.coordinate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"     // 시간:분 형식
            dateFormatter.timeZone = TimeZone.current // 현재 내 타임존 기준
            
            if let sunrise = solar.sunrise {
                sunriseLabel.text = "일출 시간: \(dateFormatter.string(from: sunrise))"
            } else {
                sunriseLabel.text = "일출 시간: 계산 불가"
            }
            
            if let sunset = solar.sunset {
                sunsetLabel.text = "일몰 시간: \(dateFormatter.string(from: sunset))"
            } else {
                sunsetLabel.text = "일몰 시간: 계산 불가"
            }
        } else {
            sunriseLabel.text = "일출 시간: 계산 불가"
            sunsetLabel.text = "일몰 시간: 계산 불가"
        }
    }
    
    private func updateWeatherInfo(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let current = weather.currentWeather
                DispatchQueue.main.async {
                    self.temperatureLabel.text = "기온: \(current.temperature.value)\(current.temperature.unit.symbol)"
                    self.windSpeedLabel.text = "풍속: \(current.wind.speed.value)\(current.wind.speed.unit.symbol)"
                    self.windDirectionLabel.text = "풍향: \(Int(current.wind.direction.value))°"
                }
            } catch {
                DispatchQueue.main.async {
                    self.temperatureLabel.text = "기온: -"
                    self.windSpeedLabel.text = "풍속: -"
                    self.windDirectionLabel.text = "풍향: -"
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource(테이블뷰 데이터 관련)
    // 섹션 개수 (지도/알림/기타)
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // 각 섹션별 셀 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // 알림 설정
        case 1: return 2 // 기타 설정
        default: return 0
        }
    }
    
    // 각 섹션 헤더 타이틀(상단 제목)
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "알림 설정"
        case 1: return "기타 설정"
        default: return nil
        }
    }
    
    // 각 셀(행) 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        switch indexPath.section {

        case 0: // 알림 설정
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "도형 만료 알림"
                cell.accessoryView = UISwitch()   // 스위치 표시
            case 1:
                cell.textLabel?.text = "일출 일몰 알림"
                cell.accessoryView = UISwitch()
            case 2:
                cell.textLabel?.text = "알림음"
                cell.accessoryView = UISwitch()
            default: break
            }
        case 1: // 기타 설정
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "iCloud 데이터 백업"
                cell.accessoryView = UISwitch()
            case 1:
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
        tableView.deselectRow(at: indexPath, animated: true) // 클릭 효과 제거
        // TODO: 각 설정 항목 선택 시 처리 추가 예정
    }
    
    // MARK: - CLLocationManagerDelegate(위치정보 콜백)
    // 위치 업데이트 이벤트
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }  // 마지막 위치 정보 사용
        currentLocation = location                            // 저장
        updateSunriseSunsetInfo()                             // UI 갱신
        updateWeatherInfo(for: location.coordinate)
        locationManager.stopUpdatingLocation()                // 한 번만 받으면 중지
    }
    
    // 위치 정보 오류 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 업데이트 실패: \(error.localizedDescription)")
        sunriseLabel.text = "일출 시간: 위치 정보 없음"
        sunsetLabel.text = "일몰 시간: 위치 정보 없음"
        temperatureLabel.text = "기온: -"
        windSpeedLabel.text = "풍속: -"
        windDirectionLabel.text = "풍향: -"
    }
}
