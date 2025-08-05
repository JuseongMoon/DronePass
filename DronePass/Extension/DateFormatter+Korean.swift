//
//  DateFormatter+Korean.swift
//  DronePass
//
//  Created by 문주성 on 5/26/25.
//

import Foundation

extension DateFormatter {
    static let koreanDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        formatter.dateFormat = "yyyy년 M월 d일 a h시 m분"
        return formatter
    }()
    
    static let korean: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
