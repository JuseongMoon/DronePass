import Foundation
import FirebaseFirestore

final class ShapeFirebaseStore: ShapeStoreProtocol {
    typealias ShapeType = ShapeModel
    
    static let shared = ShapeFirebaseStore()
    
    private let db = Firestore.firestore()
    private let collectionName = "shapes"
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 1.0
    
    private init() {
        // Firestore 설정은 앱 시작 시에만 수행 (DronePassApp.swift에서 처리)
        // 중복 설정을 방지하기 위해 여기서는 설정하지 않음
    }
    
    // 현재 사용자의 컬렉션 참조를 가져옵니다
    private var userCollection: CollectionReference? {
        guard let userId = AuthManager.shared.currentAuthUser?.uid else {
            print("❌ Firebase: 인증된 사용자가 없습니다")
            return nil
        }
        return db.collection("users").document(userId).collection(collectionName)
    }
    
    func loadShapes() async throws -> [ShapeModel] {
        return try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            let snapshot = try await collection.getDocuments()
            let allShapes = snapshot.documents.compactMap { document in
                do {
                    return try self.parseShapeFromDocument(document.data(), id: document.documentID)
                } catch {
                    print("⚠️ 도형 파싱 실패 (ID: \(document.documentID)): \(error)")
                    return nil
                }
            }
            
            // 삭제된 도형들을 필터링 (deletedAt이 nil인 도형들만)
            let activeShapes = allShapes.filter { shape in
                return shape.deletedAt == nil
            }
            
            // 데이터 검증
            if !self.validateFirebaseShapes(activeShapes) {
                throw FirebaseError.invalidData
            }
            
            print("✅ Firebase에서 도형 데이터 로드 성공: \(activeShapes.count)개 (전체: \(allShapes.count)개, 삭제됨: \(allShapes.count - activeShapes.count)개)")
            return activeShapes
        }
    }
    
    func saveShapes(_ shapes: [ShapeModel]) async throws {
        // 저장 전 데이터 검증
        guard validateFirebaseShapes(shapes) else {
            throw FirebaseError.invalidData
        }
        
        try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            // 배치 크기 제한 (Firestore 배치 제한 500개)
            let batchSize = 500
            let shapeBatches = shapes.chunked(into: batchSize)
            
            for shapeBatch in shapeBatches {
                let batch = self.db.batch()
                
                for shape in shapeBatch {
                    let docRef = collection.document(shape.id.uuidString)
                    let data = try self.shapeToFirestoreData(shape)
                    batch.setData(data, forDocument: docRef)
                }
                
                try await batch.commit()
            }
            
            // 서버 메타데이터 업데이트 (마지막 수정 시간)
            try await self.updateServerMetadata()
            
            print("✅ Firebase에 도형 데이터 저장 및 메타데이터 업데이트 성공: \(shapes.count)개")
        }
    }
    
    func addShape(_ shape: ShapeModel) async throws {
        // 데이터 검증
        guard validateSingleShape(shape) else {
            throw FirebaseError.invalidData
        }
        
        try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            let data = try self.shapeToFirestoreData(shape)
            try await collection.document(shape.id.uuidString).setData(data)
            
            // 서버 메타데이터 업데이트
            try await self.updateServerMetadata()
            
            print("✅ Firebase에 도형 추가 및 메타데이터 업데이트 성공: \(shape.title)")
        }
    }
    
    func removeShape(id: UUID) async throws {
        try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            // soft delete: 문서를 완전히 삭제하지 않고 deletedAt 필드만 설정
            let data: [String: Any] = [
                "deletedAt": Timestamp(date: Date())
            ]
            
            try await collection.document(id.uuidString).setData(data, merge: true)
            
            // 서버 메타데이터 업데이트
            try await self.updateServerMetadata()
            
            print("✅ Firebase에서 도형 soft delete 및 메타데이터 업데이트 성공: \(id)")
        }
    }
    
    func updateShape(_ shape: ShapeModel) async throws {
        // 데이터 검증
        guard validateSingleShape(shape) else {
            throw FirebaseError.invalidData
        }
        
        try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            let data = try self.shapeToFirestoreData(shape)
            try await collection.document(shape.id.uuidString).setData(data, merge: true)
            
            // 서버 메타데이터 업데이트
            try await self.updateServerMetadata()
            
            print("✅ Firebase에서 도형 수정 및 메타데이터 업데이트 성공: \(shape.title)")
        }
    }
    
    func deleteExpiredShapes() async throws {
        try await performWithRetry {
            guard let collection = self.userCollection else {
                throw FirebaseError.notAuthenticated
            }
            
            let now = Date()
            let snapshot = try await collection.getDocuments()
            let batch = self.db.batch()
            
            var deletedCount = 0
            for document in snapshot.documents {
                if let shape = try? self.parseShapeFromDocument(document.data(), id: document.documentID),
                   let expireDate = shape.flightEndDate,
                   expireDate < now {
                    batch.deleteDocument(document.reference)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try await batch.commit()
                print("✅ Firebase에서 만료된 도형 삭제 성공: \(deletedCount)개")
            }
        }
    }
    
    // MARK: - Server Metadata Methods
    
    /// 서버 메타데이터 업데이트 (마지막 수정 시간)
    private func updateServerMetadata() async throws {
        try await performWithRetry {
            let metadataRef = self.db.collection("metadata").document("server")
            try await metadataRef.setData([
                "lastModified": Timestamp(date: Date())
            ])
        }
    }
    
    /// 서버의 마지막 수정 시간 가져오기
    func getServerLastModifiedTime() async throws -> Date {
        try await performWithRetry {
            let metadataRef = self.db.collection("metadata").document("server")
            let document = try await metadataRef.getDocument()
            
            if let timestamp = document.data()?["lastModified"] as? Timestamp {
                return timestamp.dateValue()
            } else {
                // 메타데이터가 없으면 과거 시간 반환 (변경사항 없음으로 처리)
                return Date.distantPast
            }
        }
    }
    
    /// 변경사항이 있는지 확인
    func hasChanges() async throws -> Bool {
        let serverLastModified = try await getServerLastModifiedTime()
        let localLastSync = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date ?? Date.distantPast
        
        return serverLastModified > localLastSync
    }
    
    // MARK: - Helper Methods
    
    /// ShapeModel을 Firestore 데이터로 변환
    private func shapeToFirestoreData(_ shape: ShapeModel) throws -> [String: Any] {
        var data: [String: Any] = [
            "id": shape.id.uuidString,
            "title": shape.title,
            "shapeType": shape.shapeType.rawValue,
            "baseCoordinate": [
                "latitude": shape.baseCoordinate.latitude,
                "longitude": shape.baseCoordinate.longitude
            ],
            "memo": shape.memo ?? "",
            "address": shape.address ?? "",
            "createdAt": Timestamp(date: shape.createdAt),
            "flightStartDate": Timestamp(date: shape.flightStartDate),
            "color": shape.color
        ]
        
        // flightEndDate가 있는 경우에만 추가
        if let flightEndDate = shape.flightEndDate {
            data["flightEndDate"] = Timestamp(date: flightEndDate)
        }
        
        // deletedAt이 있는 경우에만 추가
        if let deletedAt = shape.deletedAt {
            data["deletedAt"] = Timestamp(date: deletedAt)
        }
        
        // 추가 도형 데이터
        if let radius = shape.radius {
            data["radius"] = radius
        }
        
        if let secondCoordinate = shape.secondCoordinate {
            data["secondCoordinate"] = [
                "latitude": secondCoordinate.latitude,
                "longitude": secondCoordinate.longitude
            ]
        }
        
        if let polygonCoordinates = shape.polygonCoordinates {
            data["polygonCoordinates"] = polygonCoordinates.map { coord in
                [
                    "latitude": coord.latitude,
                    "longitude": coord.longitude
                ]
            }
        }
        
        if let polylineCoordinates = shape.polylineCoordinates {
            data["polylineCoordinates"] = polylineCoordinates.map { coord in
                [
                    "latitude": coord.latitude,
                    "longitude": coord.longitude
                ]
            }
        }
        
        return data
    }
    
    /// Firestore 데이터를 ShapeModel로 변환
    private func parseShapeFromDocument(_ data: [String: Any], id: String) throws -> ShapeModel {
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let shapeTypeString = data["shapeType"] as? String,
              let shapeType = DronePass.ShapeType(rawValue: shapeTypeString),
              let baseCoordData = data["baseCoordinate"] as? [String: Any],
              let baseLat = baseCoordData["latitude"] as? Double,
              let baseLng = baseCoordData["longitude"] as? Double,
              let color = data["color"] as? String else {
            throw FirebaseError.invalidData
        }
        
        let baseCoordinate = CoordinateManager(latitude: baseLat, longitude: baseLng)
        let memo = data["memo"] as? String
        let address = data["address"] as? String
        
        // 날짜 필드들 읽기 (새로운 필드명 우선, 기존 필드명은 방어 코드로 사용)
        let flightStartDate: Date
        if let flightStartTimestamp = data["flightStartDate"] as? Timestamp {
            flightStartDate = flightStartTimestamp.dateValue()
        } else if let startedAtTimestamp = data["startedAt"] as? Timestamp {
            // 기존 데이터 방어 코드: startedAt 필드 사용
            flightStartDate = startedAtTimestamp.dateValue()
        } else {
            throw FirebaseError.invalidData
        }
        
        let flightEndDate: Date?
        if let flightEndTimestamp = data["flightEndDate"] as? Timestamp {
            flightEndDate = flightEndTimestamp.dateValue()
        } else {
            // 기존 데이터 방어 코드: expireDate 필드 사용
            flightEndDate = (data["expireDate"] as? Timestamp)?.dateValue()
        }
        
        // createdAt 처리 (새로운 필드 우선, 없으면 기존 로직 사용)
        let createdAt: Date
        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            createdAt = createdAtTimestamp.dateValue()
        } else {
            // 기존 데이터 방어 코드: startedAt을 createdAt으로 사용
            createdAt = flightStartDate
            
            // 백그라운드에서 createdAt 필드 추가 (마이그레이션)
            Task {
                await self.migrateDocumentCreatedAt(documentId: idString, createdAt: createdAt)
            }
        }
        
        // deletedAt 처리
        let deletedAt: Date? = (data["deletedAt"] as? Timestamp)?.dateValue()
        
        // 도형 타입별 데이터 파싱
        var radius: Double?
        var secondCoordinate: CoordinateManager?
        var polygonCoordinates: [CoordinateManager]?
        var polylineCoordinates: [CoordinateManager]?
        
        switch shapeType {
        case .circle:
            radius = data["radius"] as? Double
        case .rectangle:
            if let secondCoordData = data["secondCoordinate"] as? [String: Any],
               let secondLat = secondCoordData["latitude"] as? Double,
               let secondLng = secondCoordData["longitude"] as? Double {
                secondCoordinate = CoordinateManager(latitude: secondLat, longitude: secondLng)
            }
        case .polygon:
            if let polygonData = data["polygonCoordinates"] as? [[String: Any]] {
                polygonCoordinates = polygonData.compactMap { coordData in
                    guard let lat = coordData["latitude"] as? Double,
                          let lng = coordData["longitude"] as? Double else { return nil }
                    return CoordinateManager(latitude: lat, longitude: lng)
                }
            }
        case .polyline:
            if let polylineData = data["polylineCoordinates"] as? [[String: Any]] {
                polylineCoordinates = polylineData.compactMap { coordData in
                    guard let lat = coordData["latitude"] as? Double,
                          let lng = coordData["longitude"] as? Double else { return nil }
                    return CoordinateManager(latitude: lat, longitude: lng)
                }
            }
        }
        
        return ShapeModel(
            id: uuid,
            title: title,
            shapeType: shapeType,
            baseCoordinate: baseCoordinate,
            radius: radius,
            secondCoordinate: secondCoordinate,
            polygonCoordinates: polygonCoordinates,
            polylineCoordinates: polylineCoordinates,
            memo: memo,
            address: address,
            createdAt: createdAt,
            deletedAt: deletedAt,
            flightStartDate: flightStartDate,
            flightEndDate: flightEndDate,
            color: color
        )
    }
    
    /// Firebase 문서에 createdAt 필드를 추가 (마이그레이션)
    private func migrateDocumentCreatedAt(documentId: String, createdAt: Date) async {
        do {
            guard let collection = userCollection else { return }
            
            let data: [String: Any] = [
                "createdAt": Timestamp(date: createdAt)
            ]
            
            try await collection.document(documentId).setData(data, merge: true)
            print("📅 Firebase 문서 '\(documentId)' createdAt 마이그레이션 완료: \(createdAt)")
        } catch {
            print("⚠️ Firebase 문서 createdAt 마이그레이션 실패: \(error)")
        }
    }
    
    // MARK: - Safety & Retry Methods
    
    /// 재시도 메커니즘이 있는 비동기 작업 수행
    private func performWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetryCount {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // 재시도 불가능한 오류들
                if let firebaseError = error as? FirebaseError {
                    switch firebaseError {
                    case .notAuthenticated, .invalidData:
                        throw error
                    case .unknownError:
                        // unknownError는 재시도 가능
                        break
                    }
                }
                
                // 마지막 시도가 아니면 잠시 대기 후 재시도
                if attempt < maxRetryCount {
                    print("⚠️ Firebase 작업 실패 (시도 \(attempt)/\(maxRetryCount)): \(error)")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? FirebaseError.unknownError
    }
    
    /// Firebase 도형 데이터 검증 (배열)
    private func validateFirebaseShapes(_ shapes: [ShapeModel]) -> Bool {
        // 빈 배열은 유효함
        if shapes.isEmpty { return true }
        
        // 각 도형 검증
        for shape in shapes {
            if !validateSingleShape(shape) {
                return false
            }
        }
        
        // 중복 ID 검증
        let uniqueIds = Set(shapes.map { $0.id })
        return uniqueIds.count == shapes.count
    }
    
    /// 단일 도형 데이터 검증
    private func validateSingleShape(_ shape: ShapeModel) -> Bool {
        // ID 검증
        if shape.id.uuidString.isEmpty {
            return false
        }
        
        // 제목 검증
        if shape.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        
        // 좌표 검증
        if !isValidCoordinate(shape.baseCoordinate) {
            return false
        }
        
        // 도형 타입별 검증
        switch shape.shapeType {
        case .circle:
            if let radius = shape.radius, radius <= 0 || radius > 50000 { // 50km 제한
                return false
            }
        case .rectangle:
            if let secondCoord = shape.secondCoordinate,
               !isValidCoordinate(secondCoord) {
                return false
            }
        case .polygon:
            if let coords = shape.polygonCoordinates {
                if coords.count < 3 || coords.count > 1000 || !coords.allSatisfy(isValidCoordinate) {
                    return false
                }
            }
        case .polyline:
            if let coords = shape.polylineCoordinates {
                if coords.count < 2 || coords.count > 1000 || !coords.allSatisfy(isValidCoordinate) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// 좌표 유효성 검증
    private func isValidCoordinate(_ coordinate: CoordinateManager) -> Bool {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
               !lat.isNaN && !lng.isNaN && lat.isFinite && lng.isFinite
    }
}

// MARK: - Firebase Error
enum FirebaseError: LocalizedError {
    case notAuthenticated
    case invalidData
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "사용자가 인증되지 않았습니다."
        case .invalidData:
            return "잘못된 데이터 형식입니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
} 
