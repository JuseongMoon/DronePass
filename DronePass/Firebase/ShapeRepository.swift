//import Foundation
//import Firebase
//
//final class ShapeRepository: ShapeStoreProtocol {
//    typealias ShapeType = ShapeModel
//    static let shared = ShapeRepository()
//    
//    private var store: any ShapeStoreProtocol<ShapeModel>
//    
//    private init() {
//        // 로그인/백업 여부에 따라 저장소 선택
//        if LoginManager.shared.isLogin && SettingManager.shared.isCloudBackupEnabled {
//            store = ShapeFirebaseStore()
//        } else {
//            store = ShapeFileStore.shared
//        }
//    }
//    
//    func loadShapes() async throws -> [ShapeModel] {
//        try await store.loadShapes()
//    }
//    
//    func saveShapes(_ shapes: [ShapeModel]) async throws {
//        try await store.saveShapes(shapes)
//    }
//    
//    func addShape(_ shape: ShapeModel) async throws {
//        try await store.addShape(shape)
//    }
//    
//    func removeShape(id: UUID) async throws {
//        try await store.removeShape(id: id)
//    }
//    
//    func updateShape(_ shape: ShapeModel) async throws {
//        try await store.updateShape(shape)
//    }
//    
//    func deleteExpiredShapes() async throws {
//        try await store.deleteExpiredShapes()
//    }
//} 
