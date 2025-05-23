//
//  PassThroughView.swift
//  MapSketch
//
//  Created by 문주성 on 5/15/25.
//

// 역할: 특정 영역만 터치 이벤트를 통과시키는 커스텀 뷰
// 연관기능: 바텀시트, 오버레이, 터치 패스스루

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)

final class PassThroughView: UIView { // 터치 패스스루를 위한 커스텀 뷰입니다.
    weak var passThroughTarget: UIView? // 터치 이벤트를 통과시킬 타겟 뷰입니다.

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { // 터치 이벤트가 발생했을 때 호출되는 메서드입니다.
        if let target = passThroughTarget {
            let targetPoint = convert(point, to: target) // 터치 좌표를 타겟 뷰 기준으로 변환
            if target.bounds.contains(targetPoint) { // 타겟 뷰 내부라면
                return super.hitTest(point, with: event) // 기본 hitTest 결과 반환
            }
            return nil // 타겟 뷰 외부라면 이벤트 무시(패스스루)
        }
        return super.hitTest(point, with: event) // 타겟이 없으면 기본 hitTest
    }
} 