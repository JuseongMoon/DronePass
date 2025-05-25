//
//  NaverGeocodingService.swift
//  MapSketch
//
//  Created by 문주성 on 5/24/25.
//


import Foundation // 네트워크 통신 등 기본 기능을 위해 Foundation 프레임워크를 가져옵니다.

// 네이버 지오코딩(좌표→주소 변환) API를 호출하는 서비스 클래스입니다.
final class NaverGeocodingService {
    // 싱글톤 패턴: 앱 전체에서 이 서비스 인스턴스를 하나만 공유합니다.
    static let shared = NaverGeocodingService()
    
    // URLSession: 네트워크 통신을 담당하는 객체입니다.
    private let session = URLSession.shared
    
    // 네이버 API 인증에 필요한 client ID와 secret입니다.
    private let clientID = "47b5di8weq"
    private let clientSecret = "Z4MZw0saRvBpzgZAPUBQ0tDxV7azzVzFZuWClEFz"
    
    // 위도(latitude)와 경도(longitude)를 받아 주소를 조회하는 함수입니다.
    // completion 파라미터는 네트워크 요청이 끝난 후 주소(String) 또는 에러(Error)를 반환합니다.
    func fetchAddress(latitude: Double, longitude: Double, completion: @escaping (Result<String, Error>) -> Void) {
        // 네이버 리버스 지오코딩 API를 호출할 URL 문자열을 만듭니다.
        // (경도, 위도 순서에 주의!)
        let urlString = "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=\(longitude),\(latitude)&orders=roadaddr,addr&output=json"
        
        // 문자열을 URL 타입으로 변환합니다. 잘못된 경우(주소 생성 실패) 에러를 반환하고 함수 종료.
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URL", code: 0)))
            return
        }
        
        // URLRequest 객체를 만듭니다. (이걸로 서버에 요청을 보냅니다.)
        var request = URLRequest(url: url)
        // 네이버 API에서 요구하는 인증 헤더를 추가합니다.
        // ⚠️ 여기서 키는 "X-NCP-APIGW-API-KEY-ID", "X-NCP-APIGW-API-KEY"이어야 정상작동!
        request.addValue(clientID, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(clientSecret, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        // 네트워크 요청을 비동기로 보냅니다. (결과는 클로저에서 받아 처리)
        session.dataTask(with: request) { data, response, error in
            // 에러가 있으면 콘솔에 출력하고, completion에 에러를 넘깁니다.
            if let error = error {
                print("네트워크 에러:", error)
                completion(.failure(error))
                return
            }
            // 데이터가 없으면 에러 처리
            guard let data = data else {
                print("데이터 없음")
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            do {
                // 응답 데이터를 JSON 객체로 변환
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("네이버 응답:", json ?? "nil")
                
                // "results"라는 배열에서 주소 정보 추출 시도
                if let results = (json?["results"] as? [[String: Any]]) {
                    // (1) 도로명 주소(roadaddr)가 있으면 먼저 반환
                    if let road = results.first(where: { $0["name"] as? String == "roadaddr" }),
                       let land = road["land"] as? [String: Any],
                       let roadName = land["name"] as? String {
                        completion(.success(roadName))
                        return
                    }
                    // (2) 지번 주소(addr)가 있으면 지역명(시, 구, 동, 리 등)을 조합해 반환
                    if let addr = results.first(where: { $0["name"] as? String == "addr" }),
                       let region = addr["region"] as? [String: Any],
                       let area1 = region["area1"] as? [String: Any], let name1 = area1["name"] as? String,
                       let area2 = region["area2"] as? [String: Any], let name2 = area2["name"] as? String,
                       let area3 = region["area3"] as? [String: Any], let name3 = area3["name"] as? String,
                       let area4 = region["area4"] as? [String: Any], let name4 = area4["name"] as? String {
                        let address = "\(name1) \(name2) \(name3) \(name4)"
                        completion(.success(address))
                        return
                    }
                    // (3) 그 외 legalcode, admcode 등도 추가 파싱 가능 (추후 확장 가능)
                }
                // 원하는 주소를 찾지 못한 경우(파싱 실패)
                completion(.failure(NSError(domain: "Parse", code: 0)))
            } catch {
                // JSON 파싱 중 에러 발생 시
                print("파싱 에러:", error)
                completion(.failure(error))
            }
        }.resume() // 네트워크 요청 시작
    }
}
