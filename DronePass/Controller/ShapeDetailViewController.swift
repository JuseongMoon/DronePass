//
//  ShapeDetailViewController.swift
//  DronePass
//

import UIKit
import CoreLocation

final class ShapeDetailViewController: UIViewController {
    
    private let shapeId: UUID
    private var shape: PlaceShape? {
        return PlaceShapeStore.shared.shapes.first(where: { $0.id == shapeId })
    }
        
    

    private let infoStack = UIStackView()
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("닫기", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("수정하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("삭제하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let buttonStack = UIStackView()
    
    // 메모버튼 높이 관련 속성
    private var memoHeightConstraint: NSLayoutConstraint?

    
    init(shape: PlaceShape) {
        self.shapeId = shape.id
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        configureInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // infoStack 초기화 후 최신 데이터로 다시 구성
        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        configureInfo()
    }
    
    private func setupLayout() {
        // 닫기 버튼
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.heightAnchor.constraint(equalToConstant: 44), // ★ 닫기 버튼의 높이를 44로 고정
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60) // 가로도 보장(필요시)
        ])
        
        // infoStack 추가 (vertical)
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)
        
        // 버튼 스택
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(editButton)
        buttonStack.addArrangedSubview(deleteButton)
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 32),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: buttonStack.topAnchor, constant: -24)
        ])
        
        
        // infoStack이 공간이 부족할 때(특히 세로) 다른 뷰보다 먼저 잘리게(축소되게) 우선순위 조정
        infoStack.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    // 일반 정보 행(제목, 타입, 주소 등)
    private func makeInfoRow(title: String, value: String) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueContainer = UIView()
        valueContainer.translatesAutoresizingMaskIntoConstraints = false
        valueContainer.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: valueContainer.topAnchor, constant: 8),
            valueLabel.bottomAnchor.constraint(equalTo: valueContainer.bottomAnchor, constant: -8),
            valueLabel.leadingAnchor.constraint(equalTo: valueContainer.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: valueContainer.trailingAnchor, constant: -8),
            valueContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        valueContainer.layer.borderWidth = 1
        valueContainer.layer.borderColor = UIColor.systemGray5.cgColor
        valueContainer.layer.cornerRadius = 8
        valueContainer.backgroundColor = .clear
        valueContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, valueContainer])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .fill
        row.distribution = .fill
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: valueContainer.centerYAnchor)
        ])
        return row
    }
    
    // 메모 행
    private func makeMemoRow(memo: String) -> UIStackView {
        let label = UILabel()
        label.text = "메모"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false

        let memoTextView = UITextView()
        memoTextView.text = memo.isEmpty ? "-" : memo
        memoTextView.font = .systemFont(ofSize: 16)
        memoTextView.isEditable = false
        memoTextView.isSelectable = true
        memoTextView.dataDetectorTypes = [.link, .phoneNumber]
        memoTextView.backgroundColor = .clear
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.borderColor = UIColor.systemGray5.cgColor
        memoTextView.layer.cornerRadius = 8
        memoTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        memoTextView.textContainer.lineFragmentPadding = 0
        memoTextView.isScrollEnabled = true
        memoTextView.translatesAutoresizingMaskIntoConstraints = false

        let minHeight: CGFloat = 300 // 높이를 더 높게!
        let maxHeight: CGFloat = 400 // 원하는 최대 높이

        // 최소, 최대 높이 constraint 적용
        let minHeightConstraint = memoTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        minHeightConstraint.priority = .required
        minHeightConstraint.isActive = true

        let maxHeightConstraint = memoTextView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
        maxHeightConstraint.priority = .required
        maxHeightConstraint.isActive = true

        // valueContainer에도 명시적으로 최소 높이
        let valueContainer = UIView()
        valueContainer.translatesAutoresizingMaskIntoConstraints = false
        valueContainer.addSubview(memoTextView)
        NSLayoutConstraint.activate([
            memoTextView.topAnchor.constraint(equalTo: valueContainer.topAnchor),
            memoTextView.bottomAnchor.constraint(equalTo: valueContainer.bottomAnchor),
            memoTextView.leadingAnchor.constraint(equalTo: valueContainer.leadingAnchor),
            memoTextView.trailingAnchor.constraint(equalTo: valueContainer.trailingAnchor),
            valueContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight) // ★추가
        ])
        valueContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, valueContainer])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        row.distribution = .fill
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: memoTextView.topAnchor, constant: 5)
        ])
        return row
    }
    
    private func configureInfo() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        guard let shape = self.shape else { return }
        infoStack.addArrangedSubview(makeInfoRow(title: "제목", value: shape.title))
        infoStack.addArrangedSubview(makeInfoRow(title: "도형 타입", value: shape.shapeType.koreanName))
        infoStack.addArrangedSubview(makeInfoRow(title: "주소", value: shape.address ?? "-"))
        if let radius = shape.radius {
            let radiusString = numberFormatter.string(from: NSNumber(value: radius)) ?? "-"
            infoStack.addArrangedSubview(makeInfoRow(title: "반경", value: "\(radiusString) m"))
        }
        let dateFormatter = DateFormatter.koreanDateTime
        infoStack.addArrangedSubview(makeInfoRow(title: "시작일", value: dateFormatter.string(from: shape.startedAt)))
        if let expire = shape.expireDate {
            infoStack.addArrangedSubview(makeInfoRow(title: "종료일", value: dateFormatter.string(from: expire)))
        }
        infoStack.addArrangedSubview(makeMemoRow(memo: shape.memo ?? ""))
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "도형 삭제",
            message: "'\(shape?.title ?? "")' 도형을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            PlaceShapeStore.shared.removeShape(id: self.shapeId)
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    @objc private func editButtonTapped() {
        let editVC = AddShapePopupViewController(
            coordinate: shape?.baseCoordinate ?? Coordinate(latitude: 0, longitude: 0)
        ) { [weak self] newShape in
            guard let self = self else { return }
            PlaceShapeStore.shared.removeShape(id: self.shapeId)
            PlaceShapeStore.shared.addShape(newShape)
            self.dismiss(animated: true)
        }
        editVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        editVC.setInitialValues(
            title: shape?.title ?? "",
            address: shape?.address,
            memo: shape?.memo,
            radius: shape?.radius,
            startedAt: shape?.startedAt ?? Date(),
            expireDate: shape?.expireDate,
            shapeId: self.shapeId
        )
        present(editVC, animated: true)
    }
    @objc private func closeTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UITextView 높이 계산 유틸

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}
