import Foundation

final class NaverGeocodingService {
    static let shared = NaverGeocodingService()
    private let session = URLSession.shared
    private let clientID = "47b5di8weq"
    private let clientSecret = "Z4MZw0saRvBpzgZAPUBQ0tDxV7azzVzFZuWClEFz"
    
    func fetchAddress(latitude: Double, longitude: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=\(longitude),\(latitude)&orders=roadaddr,addr&output=json"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.addValue(clientID, forHTTPHeaderField: "x-ncp-apigw-api-key-id")
        request.addValue(clientSecret, forHTTPHeaderField: "x-ncp-apigw-api-key")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("네트워크 에러:", error)
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("데이터 없음")
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("네이버 응답:", json ?? "nil")
                if let results = (json?["results"] as? [[String: Any]]) {
                    // roadaddr 우선
                    if let road = results.first(where: { $0["name"] as? String == "roadaddr" }),
                       let land = road["land"] as? [String: Any],
                       let roadName = land["name"] as? String {
                        completion(.success(roadName))
                        return
                    }
                    // addr(지번주소)
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
                    // legalcode, admcode 등 추가 파싱 가능
                }
                completion(.failure(NSError(domain: "Parse", code: 0)))
            } catch {
                print("파싱 에러:", error)
                completion(.failure(error))
            }
        }.resume()
    }
} 
