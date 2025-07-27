//
//  User.swift
//  DronePass
//
//  Created by 문주성 on 7/26/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String // Firebase Auth UID
    let email: String? // Apple에서 제공하는 이메일 (선택적 - 가린 경우 nil)
    let createdAt: Date // 계정 생성 날짜
    
    init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
        self.createdAt = Date()
    }
} 