//
//  SavedShapeViewCell.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 저장된 도형 정보를 표시하는 테이블뷰 셀
// 연관기능: 저장 목록, 도형 정보, 접근성, 버튼 액션

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)

final class SavedShapeViewCell: UITableViewCell { // 저장된 도형 정보를 표시하는 테이블뷰 셀 클래스입니다.
    // MARK: - UI Components
    private let addressLabel = UILabel() // 주소를 표시하는 레이블
    private let dateRangeLabel = UILabel() // 날짜 범위를 표시하는 레이블
    private let statusLabel = UILabel() // 상태(메모 등)를 표시하는 레이블
    private let infoButton: UIButton = { // 정보 버튼
        let button = UIButton(type: .system)
        if let image = UIImage(systemName: "info.circle") {
            button.setImage(image, for: .normal)
        }
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let stackView = UIStackView() // 전체 레이아웃을 위한 스택뷰
    private let dateFormatter: DateFormatter = { // 날짜 포맷터
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    var infoButtonTapped: (() -> Void)? // info 버튼 탭 시 실행될 클로저
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() { // UI 구성 및 제약조건 설정
        addressLabel.font = .preferredFont(forTextStyle: .body)
        addressLabel.numberOfLines = 1
        addressLabel.textColor = .label
        addressLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        addressLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        dateRangeLabel.font = .preferredFont(forTextStyle: .footnote)
        dateRangeLabel.textColor = .secondaryLabel
        dateRangeLabel.numberOfLines = 1
        dateRangeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.textColor = .tertiaryLabel
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .right
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // infoButton 액션 연결
        infoButton.addTarget(self, action: #selector(infoButtonAction), for: .touchUpInside)

        // statusLabel + infoButton을 위한 컨테이너
        let statusContainer = UIView()
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(statusLabel)
        statusContainer.addSubview(infoButton)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 8),
            infoButton.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            infoButton.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(addressLabel)
        stackView.addArrangedSubview(dateRangeLabel)
        stackView.addArrangedSubview(statusContainer)
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with shape: PlaceShape) { // 셀에 도형 데이터를 설정하는 메서드입니다.
        addressLabel.text = shape.address ?? "주소 없음"
        if let endDate = shape.expireDate {
            let start = dateFormatter.string(from: shape.createdAt)
            let end = dateFormatter.string(from: endDate)
            dateRangeLabel.text = "\(start) ~ \(end)"
        } else {
            dateRangeLabel.text = dateFormatter.string(from: shape.createdAt)
        }
        statusLabel.text = shape.memo ?? "메모 없음"
        setupAccessibility(with: shape)
    }
    
    private func setupAccessibility(with shape: PlaceShape) { // 접근성 라벨 및 속성 설정
        let address = shape.address ?? "주소 없음"
        let dateRange = "\(dateFormatter.string(from: shape.createdAt)) ~ \(dateFormatter.string(from: shape.expireDate ?? Date()))"
        let status = shape.memo ?? "메모 없음"
        accessibilityLabel = "\(address), 생성일: \(dateRange), 상태: \(status)"
        accessibilityTraits = .button
        isAccessibilityElement = true
    }
    
    override func prepareForReuse() { // 셀이 재사용될 때 호출됩니다.
        super.prepareForReuse()
        addressLabel.text = nil
        dateRangeLabel.text = nil
        statusLabel.text = nil
    }
    
    func setLightTheme() { // 라이트 테마 색상 적용
        addressLabel.textColor = .black
        dateRangeLabel.textColor = .black
        statusLabel.textColor = .black
        backgroundColor = .white
        contentView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) { // 셀 선택 시 배경색 변경
        super.setSelected(selected, animated: true)
        contentView.backgroundColor = selected ? UIColor.systemBlue : UIColor.white
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) { // 셀 하이라이트 시 배경색 변경
        super.setHighlighted(highlighted, animated: true)
        contentView.backgroundColor = highlighted ? UIColor.systemBlue : UIColor.white
    }
    
    @objc private func infoButtonAction() { // info 버튼 탭 시 클로저 실행
        infoButtonTapped?()
    }
}
