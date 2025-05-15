//
//  BottomSheetContainerView.swift
//  MapSketch
//
//  Created by 문주성 on 5/15/25.
//

import UIKit

/// 시트 외부 터치(시트View 영역 밖)는 터치 이벤트를 nil 반환해
/// 뒤쪽(지도)로 그대로 내려보내고,
/// 시트View 영역 안의 터치만 가로채는 용도입니다.
class BottomSheetContainerView: UIView {
    /// 실제 바텀 시트 콘텐츠 뷰
    let sheetView: UIView

    init(sheetView: UIView) {
        self.sheetView = sheetView
        super.init(frame: .zero)
        backgroundColor = .clear            // 투명 배경
        addSubview(sheetView)               // 시트뷰만 자식으로 추가
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 터치 지점이 sheetView 영역 안이면 normal 처리
        let localPoint = convert(point, to: sheetView)
        if sheetView.bounds.contains(localPoint) {
            return super.hitTest(point, with: event)
        }
        // sheetView 밖이면 nil 반환 → 뒤쪽 뷰(지도)에 터치가 전달됩니다
        return nil
    }
}
