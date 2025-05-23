//
//  ShapeDetailViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 도형 상세 정보를 보여주는 뷰 컨트롤러
// 연관기능: 도형 정보 표시, 상세 화면, 닫기 버튼

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)

final class ShapeDetailViewController: UIViewController { // 도형 상세 정보를 보여주는 뷰 컨트롤러입니다.
    private let shape: PlaceShape // 상세 정보를 표시할 도형 데이터입니다.
    
    private let titleLabel = UILabel() // 제목 레이블
    private let typeLabel = UILabel() // 도형 타입 레이블
    private let addressLabel = UILabel() // 주소 레이블
    private let radiusLabel = UILabel() // 반경 레이블
    private let memoLabel = UILabel() // 메모 레이블
    private let createdAtLabel = UILabel() // 생성일 레이블
    private let expireDateLabel = UILabel() // 만료일 레이블
    private let colorLabel = UILabel() // 색상 레이블
    private let idLabel = UILabel() // ID 레이블
    private let stackView = UIStackView() // 정보를 세로로 정렬할 스택뷰
    
    init(shape: PlaceShape) { // 도형 데이터를 받아 초기화합니다.
        self.shape = shape
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // 배경색을 흰색으로 지정
        setupLabels() // 레이블 스타일 설정
        setupStackView() // 스택뷰 설정
        setupCloseButton() // 닫기 버튼 설정
        fillData() // 도형 데이터로 레이블 채우기
    }
    
    private func setupLabels() { // 레이블 스타일을 일괄 설정합니다.
        [titleLabel, typeLabel, addressLabel, radiusLabel, memoLabel, createdAtLabel, expireDateLabel, colorLabel, idLabel].forEach {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = .black
            $0.numberOfLines = 0
        }
    }
    
    private func setupStackView() { // 스택뷰에 레이블을 추가하고 제약조건을 설정합니다.
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, typeLabel, addressLabel, radiusLabel, memoLabel, createdAtLabel, expireDateLabel, colorLabel, idLabel].forEach {
            stackView.addArrangedSubview($0)
        }
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupCloseButton() { // 닫기 버튼을 추가하고 제약조건을 설정합니다.
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        closeButton.tintColor = .systemBlue
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func closeTapped() { // 닫기 버튼 탭 시 화면을 닫습니다.
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func fillData() { // 도형 데이터를 레이블에 채워 넣습니다.
        titleLabel.text = "제목: \(shape.title)"
        typeLabel.text = "도형 타입: \(shape.shapeType.rawValue)"
        addressLabel.text = "주소: \(shape.address ?? "-")"
        radiusLabel.text = "반경: \(shape.radius != nil ? String(format: "%.0f m", shape.radius!) : "-")"
        memoLabel.text = "메모: \(shape.memo ?? "-")"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        createdAtLabel.text = "생성일: \(dateFormatter.string(from: shape.createdAt))"
        if let expire = shape.expireDate {
            expireDateLabel.text = "종료일: \(dateFormatter.string(from: expire))"
        } else {
            expireDateLabel.text = "종료일: -"
        }
        colorLabel.text = "색상: \(shape.color)"
        idLabel.text = "ID: \(shape.id.uuidString)"
    }
}
