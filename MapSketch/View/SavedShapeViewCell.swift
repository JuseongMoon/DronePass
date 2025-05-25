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
    private let statusLabel = UILabel() // 상태(날짜 등)를 표시하는 레이블
    private let radiusLabel = UILabel() // 반경을 표시하는 레이블
    private let infoButton: UIButton = { // 정보 버튼
        let button = UIButton(type: .system)
        // 크기를 키운 심볼 이미지로 설정
        if let image = UIImage(systemName: "info.circle") {
            let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            button.setImage(image.withConfiguration(config), for: .normal)
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
    private func setupUI() {
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
        statusLabel.numberOfLines = 0 // 여러 줄 허용
        statusLabel.textAlignment = .left // 날짜 왼쪽 정렬
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        radiusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        radiusLabel.textColor = .systemGray2
        radiusLabel.numberOfLines = 1
        radiusLabel.textAlignment = .right
        radiusLabel.setContentHuggingPriority(.required, for: .horizontal)
        radiusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        radiusLabel.adjustsFontSizeToFitWidth = true
        radiusLabel.minimumScaleFactor = 0.7
        radiusLabel.translatesAutoresizingMaskIntoConstraints = false

        infoButton.addTarget(self, action: #selector(infoButtonAction), for: .touchUpInside)
        contentView.addSubview(infoButton)
        contentView.addSubview(radiusLabel)
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            // info 버튼 오른쪽 상단
            infoButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            infoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 30),
            infoButton.heightAnchor.constraint(equalToConstant: 30),
            // 반경 오른쪽 하단
            radiusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            radiusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            radiusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            // stackView는 contentView의 오른쪽까지(반경과 겹치지 않게 충분한 패딩)
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading // 왼쪽 정렬
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(addressLabel) // 제목
        stackView.addArrangedSubview(dateRangeLabel) // 주소
        stackView.addArrangedSubview(statusLabel) // 날짜
    }
    
    // MARK: - Configuration
    func configure(with shape: PlaceShape) { // 셀에 도형 데이터를 설정하는 메서드입니다.
        addressLabel.text = shape.title // 제목
        dateRangeLabel.text = shape.address ?? "주소 없음" // 주소
        if let endDate = shape.expireDate {
            let start = dateFormatter.string(from: shape.startedAt)
            let end = dateFormatter.string(from: endDate)
            statusLabel.text = "\(start) ~ \(end)" // 날짜
        } else {
            statusLabel.text = dateFormatter.string(from: shape.startedAt) // 날짜
        }
        if let radius = shape.radius {
            radiusLabel.text = "반경: \(Int(radius)) m"
        } else {
            radiusLabel.text = "반경: - m"
        }
        setupAccessibility(with: shape)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateSelectionUI(selected: selected)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // 스크롤 중 터치 하이라이트 방지: 아무것도 하지 않음
        // 또는 필요시 아래 한 줄만 유지
        // contentView.backgroundColor = highlighted ? UIColor.systemBlue : UIColor.white
    }
    
    private func setupAccessibility(with shape: PlaceShape) { // 접근성 라벨 및 속성 설정
        let address = shape.address ?? "주소 없음"
        let dateRange = "\(dateFormatter.string(from: shape.startedAt)) ~ \(dateFormatter.string(from: shape.expireDate ?? Date()))"
        let status = shape.memo ?? "메모 없음"
        accessibilityLabel = "\(address), 시작일: \(dateRange), 상태: \(status)"
        accessibilityTraits = .button
        isAccessibilityElement = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        addressLabel.text = nil
        dateRangeLabel.text = nil
        statusLabel.text = nil
        // 항상 초기화
        updateSelectionUI(selected: false)
    }
    
    private func updateSelectionUI(selected: Bool) {
        contentView.backgroundColor = selected ? UIColor.systemBlue : UIColor.white
        infoButton.tintColor = selected ? .white : .systemBlue
    }
    
    func setLightTheme() { // 라이트 테마 색상 적용
        addressLabel.textColor = .black
        dateRangeLabel.textColor = .black
        statusLabel.textColor = .black
        backgroundColor = .white
        contentView.backgroundColor = .white
    }
    
    @objc private func infoButtonAction() { // info 버튼 탭 시 클로저 실행
        infoButtonTapped?()
    }
}
