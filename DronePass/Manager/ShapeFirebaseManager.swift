//
//  ShapeFirebaseManager.swift
//  DronePass
//
//  Created by 문주성 on 7/22/25.
//

import Foundation

class ShapeFirebaseManager {
    static let shared = ShapeFirebaseManager()
    
    private let firebaseStore = ShapeFirebaseStore.shared
    private let localStore = ShapeFileStore.shared
    
    private init() {}
    
    /// 파이어스토어에서 도형 데이터를 로드하고 색상을 로컬과 동기화
    func loadShapesWithColorSync() async throws -> [ShapeModel] {
        print("🔄 파이어스토어에서 도형 데이터 로드 및 색상 동기화 시작")
        
        do {
            let firebaseShapes = try await firebaseStore.loadShapes()
            print("✅ 파이어스토어 데이터 로드 완료: \(firebaseShapes.count)개")
            
            // 색상 동기화가 이미 loadShapes() 내에서 수행되므로 추가 작업 없음
            return firebaseShapes
            
        } catch {
            print("❌ 파이어스토어 데이터 로드 실패: \(error)")
            throw error
        }
    }
    
    /// 로컬과 파이어스토어 간 색상 동기화 상태 확인
    func checkColorSyncStatus() async -> ColorSyncStatus {
        do {
            let firebaseShapes = try await firebaseStore.loadShapes()
            let currentDefaultColor = ColorManager.shared.defaultColor.hex
            
            // 파이어스토어에서 가장 많이 사용된 색상 확인
            let firebaseDominantColor = getDominantColor(from: firebaseShapes)
            
            if currentDefaultColor == firebaseDominantColor {
                return .synchronized
            } else {
                return .needsSync(localColor: currentDefaultColor, firebaseColor: firebaseDominantColor)
            }
            
        } catch {
            return .error(error)
        }
    }
    
    /// 색상 분포에서 가장 많이 사용된 색상 반환
    private func getDominantColor(from shapes: [ShapeModel]) -> String {
        var colorCount: [String: Int] = [:]
        
        for shape in shapes {
            colorCount[shape.color, default: 0] += 1
        }
        
        return colorCount.max(by: { $0.value < $1.value })?.key ?? "#007AFF"
    }
    
    /// 색상 동기화 테스트 및 디버깅
    func debugColorSync() async {
        print("🔍 색상 동기화 디버깅 시작")
        
        do {
            let status = await checkColorSyncStatus()
            print("📊 동기화 상태: \(status.description)")
            
            let currentDefaultColor = ColorManager.shared.defaultColor.hex
            let firebaseShapes = try await firebaseStore.loadShapes()
            
            print("🎨 현재 설정된 기본 도형 색상: \(currentDefaultColor)")
            print("🔥 파이어스토어 도형 수: \(firebaseShapes.count)")
            
            if !firebaseShapes.isEmpty {
                let firebaseColors = analyzeColorDistribution(firebaseShapes)
                print("🔥 파이어스토어 색상 분포: \(firebaseColors)")
            }
            
        } catch {
            print("❌ 디버깅 실패: \(error)")
        }
    }
    
    /// 색상 분포 분석 (디버깅용)
    private func analyzeColorDistribution(_ shapes: [ShapeModel]) -> [String: Int] {
        var colorCount: [String: Int] = [:]
        
        for shape in shapes {
            colorCount[shape.color, default: 0] += 1
        }
        
        return colorCount
    }
    
    /// 수동으로 색상 동기화 수행
    func forceColorSync() async throws {
        print("🔄 수동 색상 동기화 시작")
        
        do {
            let firebaseShapes = try await firebaseStore.loadShapes()
            let currentDefaultColor = ColorManager.shared.defaultColor.hex
            print("🎨 현재 설정된 기본 도형 색상: \(currentDefaultColor)")
            
            var updatedShapes = firebaseShapes
            var syncCount = 0
            
            for i in 0..<updatedShapes.count {
                if updatedShapes[i].color != currentDefaultColor {
                    updatedShapes[i].color = currentDefaultColor
                    syncCount += 1
                }
            }
            
            if syncCount > 0 {
                try await firebaseStore.saveShapes(updatedShapes)
                print("✅ 수동 색상 동기화 완료: \(syncCount)개 도형 업데이트")
            } else {
                print("✅ 색상이 이미 동기화되어 있습니다.")
            }
            
        } catch {
            print("❌ 수동 색상 동기화 실패: \(error)")
            throw error
        }
    }
}

// MARK: - Color Sync Status
enum ColorSyncStatus {
    case synchronized
    case needsSync(localColor: String, firebaseColor: String)
    case error(Error)
    
    var description: String {
        switch self {
        case .synchronized:
            return "색상이 동기화되어 있습니다."
        case .needsSync(let localColor, let firebaseColor):
            return "색상 동기화 필요: 설정 색상(\(localColor)) ↔ 파이어스토어(\(firebaseColor))"
        case .error(let error):
            return "동기화 상태 확인 실패: \(error.localizedDescription)"
        }
    }
}
