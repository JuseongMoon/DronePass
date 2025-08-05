//
//  SettingManager.swift
//  DronePass
//
//  Created by 문주성 on 5/25/25.
//
// 이사검증완료

import Foundation
import UserNotifications   // iOS의 푸시 알림(로컬 알림 포함) 기능을 사용하기 위한 프레임워크
import CoreLocation       // 위치정보(위도/경도 등)를 다루기 위한 프레임워크
import Solar              // 일출/일몰 계산용 외부 라이브러리(https://github.com/ceeK/Solar)
import Combine           // ObservableObject 사용을 위한 프레임워크

/// 앱 전체에서 알림 및 설정 관련 기능을 담당하는 싱글톤 객체입니다.
/// (이 객체를 통해 알림, 일출/일몰 스케줄링, 종료일 알림 관리 등 수행)
final class SettingManager: ObservableObject {
    // 전역에서 공유해서 사용하기 위한 싱글톤 인스턴스 생성
    static let shared = SettingManager()
    
    /// 외부에서 새로운 인스턴스를 만들지 못하도록 private으로 선언(싱글톤 패턴)
    private init() {
        // 객체가 처음 생성될 때 알림 권한을 요청합니다.
        requestNotificationPermission()
        loadCloudBackupSetting() // 초기화 시 클라우드 백업 설정 로드
    }

    // MARK: - 종료일 알림 관련 프로퍼티

    /// 종료일 알림 활성화 여부를 저장하는 UserDefaults 키(문자열 상수)
    private let endDateAlarmKey = "endDateAlarmEnabled"

    /// 종료일 알림 활성화 여부를 저장/불러오기 위한 프로퍼티
    /// - get: UserDefaults에서 불러옴
    /// - set: UserDefaults에 저장, 값이 true면 알림 스케줄링/false면 알림 해제
    var isEndDateAlarmEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: endDateAlarmKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: endDateAlarmKey)
            if newValue {
                // 위치 정보가 있을 때만 일출/일몰 알림도 스케줄링
                if let location = LocationManager.shared.currentLocation {
                    scheduleSunriseSunsetAlarms(for: location.coordinate)
                }
            } else {
                // 해제 시 알림 모두 제거
                removeEndDateAlarms()
            }
        }
    }

    /// 종료일 알림 상세 설명 텍스트(설정화면 등에 사용)
    var endDateAlarmDetailText: String {
        isEndDateAlarmEnabled ? "도형의 종료일이 다가오면 알림을 받습니다." : "알림이 꺼져 있습니다."
    }

    // MARK: - 일출/일몰 알림 관련 프로퍼티

    /// 일출/일몰 알림 활성화 여부를 저장하는 UserDefaults 키
    private let sunriseSunsetAlarmKey = "sunriseSunsetAlarmEnabled"

    /// 일출/일몰 알림 활성화 여부 프로퍼티 (UserDefaults에 저장/불러오기)
    var isSunriseSunsetAlarmEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: sunriseSunsetAlarmKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: sunriseSunsetAlarmKey)
            if newValue {
                if let location = LocationManager.shared.currentLocation {
                    // 현재 위치가 있다면 알림 예약
                    scheduleSunriseSunsetAlarms(for: location.coordinate)
                }
            } else {
                // 비활성화시 기존 알림 삭제
                removeSunriseSunsetAlarms()
            }
        }
    }

    /// 일출/일몰 알림 상세 설명 텍스트
    var sunriseSunsetAlarmDetailText: String {
        isSunriseSunsetAlarmEnabled ? "일출/일몰 시간에 알림을 받습니다." : "알림이 꺼져 있습니다."
    }
    
    // MARK: - 만료된 도형 숨기기 관련 프로퍼티
    
    /// 만료된 도형 숨기기 활성화 여부를 저장하는 UserDefaults 키
    private let hideExpiredShapesKey = "hideExpiredShapesEnabled"
    
    /// 만료된 도형 숨기기 활성화 여부 프로퍼티 (UserDefaults에 저장/불러오기)
    var isHideExpiredShapesEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: hideExpiredShapesKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: hideExpiredShapesKey)
            // 설정 변경 시 지도 오버레이 리로드 알림 전송
            NotificationCenter.default.post(name: Notification.Name("ReloadMapOverlays"), object: nil)
        }
    }
    
    // MARK: - 클라우드 백업 관련 프로퍼티
    
    /// 클라우드 백업 활성화 여부를 저장하는 UserDefaults 키
    private let cloudBackupKey = "cloudBackupEnabled"
    
    /// 클라우드 백업 활성화 여부 프로퍼티 (UserDefaults에 저장/불러오기)
    @Published var isCloudBackupEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isCloudBackupEnabled, forKey: cloudBackupKey)
        }
    }
    
    /// 초기화 시 UserDefaults에서 값 불러오기
    private func loadCloudBackupSetting() {
        // 처음 설치 시에는 기본값을 false로 설정
        if !UserDefaults.standard.bool(forKey: "\(cloudBackupKey)_initialized") {
            UserDefaults.standard.set(false, forKey: cloudBackupKey)
            UserDefaults.standard.set(true, forKey: "\(cloudBackupKey)_initialized")
        }
        
        isCloudBackupEnabled = UserDefaults.standard.bool(forKey: cloudBackupKey)
        print("✅ 클라우드 백업 설정 로드: \(isCloudBackupEnabled ? "활성화" : "비활성화")")
    }

    // MARK: - 알림 권한 요청

    /// 앱이 처음 실행되었을 때, 푸시/로컬 알림 사용 권한을 요청하는 함수
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다.")
            } else if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 종료일 알림 스케줄링

    /// 종료일이 가까운 도형(Shape)들을 받아서, 알림을 예약하는 함수
    func scheduleEndDateAlarms(for shapes: [Shape]) {
        guard isEndDateAlarmEnabled else { return }  // 기능이 꺼져있으면 아무것도 안 함
        
        // 기존 알림 삭제(중복 방지)
        removeEndDateAlarms()
        
        for shape in shapes {
            guard let endDate = shape.endDate else { continue }  // 종료일이 없으면 skip

            // 종료일 7일 전 알림
            let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            if sevenDaysBefore > Date() {
                scheduleNotification(
                    id: "endDate_\(shape.id)_7days", // 고유 식별자
                    title: "도형 종료일 알림",
                    body: "도형 '\(shape.name)'의 종료일이 7일 남았습니다.",
                    date: sevenDaysBefore
                )
            }
            // 필요하다면 추가적으로 1일 전, 당일 등 다양한 알림 예약 가능
        }
    }

    /// 종료일 알림 전체 삭제
    private func removeEndDateAlarms() {
        // 식별자 배열로 삭제(식별자가 여러개라면 이 방식은 보완 필요)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["endDate"])
    }

    // MARK: - 일출/일몰 알림 스케줄링

    /// 현재 위치의 위도/경도를 받아 일출/일몰 알림을 예약하는 함수
    func scheduleSunriseSunsetAlarms(for coordinate: CLLocationCoordinate2D) {
        guard isSunriseSunsetAlarmEnabled else { return }
        removeSunriseSunsetAlarms()

        let now = Date()
        let calendar = Calendar.current
        let solarToday = Solar(for: now, coordinate: coordinate)
        let solarTomorrow = Solar(for: calendar.date(byAdding: .day, value: 1, to: now)!, coordinate: coordinate)

        if let sunrise = solarToday?.sunrise, sunrise > now {
            // 오늘 일출 알림 예약
            registerSunriseAlarms(for: sunrise)
        } else if let sunrise = solarTomorrow?.sunrise {
            // 내일 일출 알림 예약
            registerSunriseAlarms(for: sunrise)
        }
        if let sunset = solarToday?.sunset, sunset > now {
            // 오늘 일몰 알림 예약
            registerSunsetAlarms(for: sunset)
        }
    }
    private func registerSunriseAlarms(for sunrise: Date) {
        let thirtyMinBefore = Calendar.current.date(byAdding: .minute, value: -30, to: sunrise)!
        let tenMinBefore = Calendar.current.date(byAdding: .minute, value: -10, to: sunrise)!
        if thirtyMinBefore > Date() {
            scheduleNotification(id: "sunrise_30min", title: "일출 30분 전", body: "일출까지 30분 남았습니다.", date: thirtyMinBefore)
        }
        if tenMinBefore > Date() {
            scheduleNotification(id: "sunrise_10min", title: "일출 10분 전", body: "일출까지 10분 남았습니다.", date: tenMinBefore)
        }
    }
    private func registerSunsetAlarms(for sunset: Date) {
        let thirtyMinBefore = Calendar.current.date(byAdding: .minute, value: -30, to: sunset)!
        let tenMinBefore = Calendar.current.date(byAdding: .minute, value: -10, to: sunset)!
        if thirtyMinBefore > Date() {
            scheduleNotification(id: "sunset_30min", title: "일몰 30분 전", body: "일몰까지 30분 남았습니다.", date: thirtyMinBefore)
        }
        if tenMinBefore > Date() {
            scheduleNotification(id: "sunset_10min", title: "일몰 10분 전", body: "일몰까지 10분 남았습니다.", date: tenMinBefore)
        }
    }

    /// 일출/일몰 알림 전체 삭제
    private func removeSunriseSunsetAlarms() {
        // 식별자에 "sunrise", "sunset" 포함된 알림 모두 제거
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sunrise", "sunset"])
    }
    
    // MARK: - 종료일 지난 도형 일괄 삭제

    /// 앱의 ShapeRepository를 호출하여, 종료일이 지난 도형을 일괄 삭제
    func deleteExpiredShapes() {
        Task {
            do {
                try await ShapeRepository.shared.deleteExpiredShapes()
            } catch {
                print("❌ 만료된 도형 삭제 실패: \(error)")
            }
        }
    }
    
    // MARK: - 알림 예약을 위한 공통 함수

    /// 실질적으로 알림을 예약하는 함수(모든 알림 공통)
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title              // 알림 제목
        content.body = body                // 알림 본문 메시지
        content.sound = .default           // 기본 알림음

        // 알림이 울릴 시각을 년/월/일/시/분 단위로 분리해서 trigger 생성
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // 알림 요청 객체를 생성해서 시스템에 등록
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 스케줄링 실패: \(error.localizedDescription)")
            }
        }
    }
}
