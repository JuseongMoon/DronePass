import Foundation
import CoreLocation

final class NaverReverseGeocoder {
    static let shared = NaverReverseGeocoder()
    private let apiKeyId = "47b5di8weq" // X-NCP-APIGW-API-KEY-ID
    private let apiKey = "Z4MZw0saRvBpzgZAPUBQ0tDxV7azzVzFZuWCIEFz" // X-NCP-APIGW-API-KEY

    func fetchAddress(for coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let urlString = "https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc?coords=\(coordinate.longitude),\(coordinate.latitude)&output=json&orders=roadaddr,addr"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.addValue(apiKeyId, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(apiKey, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let region = first["region"] as? [String: Any],
                  let area1 = region["area1"] as? [String: Any],
                  let area1Name = area1["name"] as? String,
                  let area2 = region["area2"] as? [String: Any],
                  let area2Name = area2["name"] as? String,
                  let area3 = region["area3"] as? [String: Any],
                  let area3Name = area3["name"] as? String
            else {
                completion(nil)
                return
            }
            let address = "\(area1Name) \(area2Name) \(area3Name)"
            completion(address)
        }.resume()
    }
}

final class NaverGeocoder {
    static let shared = NaverGeocoder()
    private let apiKeyId = "47b5di8weq" // X-NCP-APIGW-API-KEY-ID
    private let apiKey = "Z4MZw0saRvBpzgZAPUBQ0tDxV7azzVzFZuWCIEFz" // X-NCP-APIGW-API-KEY

    func fetchCoordinate(for address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=\(encoded)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.addValue(apiKeyId, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(apiKey, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let addresses = json["addresses"] as? [[String: Any]],
                  let first = addresses.first,
                  let x = first["x"] as? String,
                  let y = first["y"] as? String,
                  let lon = Double(x),
                  let lat = Double(y)
            else {
                completion(nil)
                return
            }
            completion(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }.resume()
    }
} 