//
//  BottomSheetContainerView.swift
//  DronePass
//
//  Created by 문주성 on 5/15/25.
//

// 역할: 바텀시트 외부 터치 패스스루 컨테이너 뷰
// 연관기능: 바텀시트 오버레이, 터치 이벤트 관리

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)

/// 시트 외부 터치(시트View 영역 밖)는 터치 이벤트를 nil 반환해
/// 뒤쪽(지도)로 그대로 내려보내고,
/// 시트View 영역 안의 터치만 가로채는 용도입니다.
class BottomSheetContainerView: UIView { // 바텀시트의 터치 패스스루를 위한 커스텀 뷰입니다.
    // MARK: - Properties
    private let sheetView: UIView // 실제 바텀시트 뷰를 저장하는 프로퍼티입니다.
    
    // MARK: - Initialization
    init(sheetView: UIView) { // sheetView를 받아 초기화합니다.
        self.sheetView = sheetView
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { // 스토리보드 초기화는 지원하지 않습니다.
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() { // 뷰의 초기 설정을 담당합니다.
        backgroundColor = .clear // 배경색을 투명하게 설정합니다.
        addSubview(sheetView) // sheetView를 서브뷰로 추가합니다.
        
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
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { // 터치가 sheetView 내부인지 확인합니다.
        let pointInSheet = convert(point, to: sheetView)
        return sheetView.bounds.contains(pointInSheet)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { // 터치 이벤트를 sheetView 내부에서만 처리합니다.
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
