//
//  SettingManager.swift
//  MapSketch
//
//  Created by 문주성 on 5/25/25.
//

import Foundation
import UserNotifications
import CoreLocation
import Solar

final class SettingManager {
    static let shared = SettingManager()
    private init() {
        requestNotificationPermission()
    }

    // 종료일 알림 활성화 여부
    private let endDateAlarmKey = "endDateAlarmEnabled"
    var isEndDateAlarmEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: endDateAlarmKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: endDateAlarmKey)
            if newValue {
                // 현재 위치가 있는 경우에만 일출/일몰 알림 스케줄링
                if let location = LocationManager.shared.currentLocation {
                    scheduleSunriseSunsetAlarms(for: location.coordinate)
                }
            } else {
                removeEndDateAlarms()
            }
        }
    }
    var endDateAlarmDetailText: String {
        isEndDateAlarmEnabled ? "도형의 종료일이 다가오면 알림을 받습니다." : "알림이 꺼져 있습니다."
    }

    // 일출/일몰 알림 활성화 여부
    private let sunriseSunsetAlarmKey = "sunriseSunsetAlarmEnabled"
    var isSunriseSunsetAlarmEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: sunriseSunsetAlarmKey) }
        set { 
            UserDefaults.standard.set(newValue, forKey: sunriseSunsetAlarmKey)
            if newValue {
                // 현재 위치가 있는 경우에만 일출/일몰 알림 스케줄링
                if let location = LocationManager.shared.currentLocation {
                    scheduleSunriseSunsetAlarms(for: location.coordinate)
                }
            } else {
                removeSunriseSunsetAlarms()
            }
        }
    }
    var sunriseSunsetAlarmDetailText: String {
        isSunriseSunsetAlarmEnabled ? "일출/일몰 시간에 맞춰 알림을 받습니다." : "알림이 꺼져 있습니다."
    }

    // MARK: - 알림 권한 요청
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한이 허용되었습니다.")
            } else if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 종료일 알림 관련
    func scheduleEndDateAlarms(for shapes: [Shape]) {
        guard isEndDateAlarmEnabled else { return }
        
        // 기존 알림 제거
        removeEndDateAlarms()
        
        for shape in shapes {
            guard let endDate = shape.endDate else { continue }
            
            // 7일 전 알림
            let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            if sevenDaysBefore > Date() {
                scheduleNotification(
                    id: "endDate_\(shape.id)_7days",
                    title: "도형 종료일 알림",
                    body: "도형 '\(shape.name)'의 종료일이 7일 남았습니다.",
                    date: sevenDaysBefore
                )
            }
        }
    }

    private func removeEndDateAlarms() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["endDate"])
    }

    // MARK: - 일출/일몰 알림 관련
    func scheduleSunriseSunsetAlarms(for coordinate: CLLocationCoordinate2D) {
        guard isSunriseSunsetAlarmEnabled else { return }
        
        // 기존 알림 제거
        removeSunriseSunsetAlarms()
        
        guard let solar = Solar(for: Date(), coordinate: coordinate) else { return }
        
        if let sunrise = solar.sunrise {
            // 일출 30분 전
            let thirtyMinutesBeforeSunrise = Calendar.current.date(byAdding: .minute, value: -30, to: sunrise)!
            if thirtyMinutesBeforeSunrise > Date() {
                scheduleNotification(
                    id: "sunrise_30min",
                    title: "일출 알림",
                    body: "일출까지 30분 남았습니다.",
                    date: thirtyMinutesBeforeSunrise
                )
            }
            
            // 일출 10분 전
            let tenMinutesBeforeSunrise = Calendar.current.date(byAdding: .minute, value: -10, to: sunrise)!
            if tenMinutesBeforeSunrise > Date() {
                scheduleNotification(
                    id: "sunrise_10min",
                    title: "일출 알림",
                    body: "일출까지 10분 남았습니다.",
                    date: tenMinutesBeforeSunrise
                )
            }
        }
        
        if let sunset = solar.sunset {
            // 일몰 30분 전
            let thirtyMinutesBeforeSunset = Calendar.current.date(byAdding: .minute, value: -30, to: sunset)!
            if thirtyMinutesBeforeSunset > Date() {
                scheduleNotification(
                    id: "sunset_30min",
                    title: "일몰 알림",
                    body: "일몰까지 30분 남았습니다.",
                    date: thirtyMinutesBeforeSunset
                )
            }
            
            // 일몰 10분 전
            let tenMinutesBeforeSunset = Calendar.current.date(byAdding: .minute, value: -10, to: sunset)!
            if tenMinutesBeforeSunset > Date() {
                scheduleNotification(
                    id: "sunset_10min",
                    title: "일몰 알림",
                    body: "일몰까지 10분 남았습니다.",
                    date: tenMinutesBeforeSunset
                )
            }
        }
    }

    private func removeSunriseSunsetAlarms() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sunrise", "sunset"])
    }

    // MARK: - 알림 스케줄링 헬퍼
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 스케줄링 실패: \(error.localizedDescription)")
            }
        }
    }
}

