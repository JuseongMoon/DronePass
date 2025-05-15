//
//  SavedBottomSheetViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//


import UIKit

/// 터치 패스스루 컨테이너 필요 (BottomSheetContainerView.swift)
class SavedBottomSheetViewController: UIViewController {
    // MARK: - 높이 설정
    private let tabBarHeight: CGFloat = 49
    private let collapsedHeight: CGFloat = 200
    private var expandedHeight: CGFloat {
        return view.bounds.height - view.safeAreaInsets.top - tabBarHeight - 8
    }

    // 시트 높이 제약
    private var sheetHeightConstraint: NSLayoutConstraint!
    private var containerView: BottomSheetContainerView!
    private var initialHeight: CGFloat = 0
    private var hasSetInitialPosition = false

    // MARK: - 초기화
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 뷰 계층 구성
    override func loadView() {
        // 1) 시트 콘텐츠 뷰
        let sheetView = UIView()
        sheetView.backgroundColor = .darkGray
        sheetView.layer.cornerRadius = 16
        sheetView.clipsToBounds = true

        // 2) 그랩바
        let grabber = UIView()
        grabber.backgroundColor = .systemGray3
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5)
        ])

        // 3) Pan 제스처 추가 (시트 전체 드래그)
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetView.addGestureRecognizer(panGR)

        // 4) 터치 패스스루 컨테이너
        containerView = BottomSheetContainerView(sheetView: sheetView)
        containerView.backgroundColor = .clear
        view = containerView

        // 5) 제약 설정: leading, trailing, bottom, height
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        sheetHeightConstraint = sheetView.heightAnchor.constraint(equalToConstant: collapsedHeight)
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sheetHeightConstraint
        ])
    }

    // MARK: - 초기 위치 설정 (midHeight)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasSetInitialPosition else { return }
        let midHeight = (expandedHeight + collapsedHeight) / 2
        sheetHeightConstraint.constant = midHeight
        containerView.layoutIfNeeded()
        hasSetInitialPosition = true
    }

    // MARK: - Pan 제스처 핸들러
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let container = view as? BottomSheetContainerView else { return }
        let translation = gesture.translation(in: view).y

        switch gesture.state {
        case .began:
            initialHeight = sheetHeightConstraint.constant

        case .changed:
            let rawHeight = initialHeight - translation
            sheetHeightConstraint.constant = min(max(rawHeight, collapsedHeight), expandedHeight)
            container.layoutIfNeeded()

        case .ended, .cancelled:
            let velocityY = gesture.velocity(in: view).y
            let midHeight = (expandedHeight + collapsedHeight) / 2
            var targetHeight: CGFloat
            if velocityY < -500 {
                // 빠른 위 방향 스와이프 → expand
                targetHeight = expandedHeight
            } else if velocityY > 500 {
                // 빠른 아래 스와이프 → close (완전 닫혀 버림)
                willMove(toParent: nil)
                view.removeFromSuperview()
                removeFromParent()
                return
            } else {
                // 세 개 스냅 포인트 중 가장 가까운 곳으로 이동
                let distances = [
                    abs(sheetHeightConstraint.constant - collapsedHeight),
                    abs(sheetHeightConstraint.constant - midHeight),
                    abs(sheetHeightConstraint.constant - expandedHeight)
                ]
                if let minIndex = distances.enumerated().min(by: { $0.element < $1.element })?.offset {
                    switch minIndex {
                    case 0: targetHeight = collapsedHeight
                    case 1: targetHeight = midHeight
                    default: targetHeight = expandedHeight
                    }
                } else {
                    targetHeight = midHeight
                }
            }
            UIView.animate(withDuration: 0.3) {
                self.sheetHeightConstraint.constant = targetHeight
                self.containerView.layoutIfNeeded()
            }

        default:
            break
        }
    }
}
