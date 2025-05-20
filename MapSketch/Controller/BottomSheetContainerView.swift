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
    // MARK: - Properties
    private let sheetView: UIView
    
    // MARK: - Initialization
    init(sheetView: UIView) {
        self.sheetView = sheetView
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        addSubview(sheetView)
        
        // sheetView 제약조건 설정
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sheetView.topAnchor.constraint(equalTo: topAnchor),
            sheetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Touch Handling
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let pointInSheet = convert(point, to: sheetView)
        return sheetView.bounds.contains(pointInSheet)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointInSheet = convert(point, to: sheetView)
        
        // sheetView 영역 밖이면 nil 반환 (터치 패스스루)
        guard sheetView.bounds.contains(pointInSheet) else {
            return nil
        }
        
        // sheetView 내부의 모든 서브뷰들에 대해 hitTest 수행
        let hitView = sheetView.hitTest(pointInSheet, with: event)
        return hitView ?? sheetView
    }
}
