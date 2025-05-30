//
//  SampleShapeLoader.swift
//  DronePass
//
//  Created by 문주성 on 5/19/25.
//

// 역할: 샘플 도형 데이터를 로드하는 클래스
// 연관기능: 앱 초기화, 테스트 데이터 로드

import Foundation // Foundation 프레임워크를 가져옵니다. (기본적인 데이터 타입과 기능을 사용하기 위함)

final class SampleShapeLoader { // 샘플 도형 데이터를 로드하는 클래스입니다. final 키워드로 상속을 방지합니다.
    static func loadSampleShapes() -> [PlaceShape] { // 샘플 도형 데이터를 로드하는 정적 메서드입니다.
        guard let url = Bundle.main.url(forResource: "sample_shapes", withExtension: "json") else { // 샘플 JSON 파일의 URL을 가져옵니다.
            print("❌ 샘플 JSON 파일을 찾을 수 없습니다.") // 파일을 찾을 수 없는 경우 에러 메시지를 출력합니다.
            return [] // 빈 배열을 반환합니다.
        }
        do {
            let data = try Data(contentsOf: url) // JSON 파일의 내용을 데이터로 읽어옵니다.
            let decoder = JSONDecoder() // JSON 디코더를 생성합니다.
            decoder.dateDecodingStrategy = .iso8601 // 날짜 형식을 ISO8601로 설정합니다. (startedAt, expireDate 필드용)
            let shapes = try decoder.decode([PlaceShape].self, from: data) // JSON 데이터를 PlaceShape 배열로 디코딩합니다.
            return shapes // 디코딩된 도형 배열을 반환합니다.
        } catch {
            print("❌ 샘플 도형 디코딩 실패:", error) // 디코딩 실패 시 에러 메시지를 출력합니다.
            return [] // 빈 배열을 반환합니다.
        }
    }
}
