////
////  SavedShapeViewCell.swift
////  DronePass
////
////  Created by 문주성 on 5/13/25.
////
//
//// 역할: 저장된 도형 정보를 표시하는 테이블뷰 셀
//// 연관기능: 저장 목록, 도형 정보, 접근성, 버튼 액션
//
//import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
//
//final class SavedShapeViewCell: UITableViewCell { // 저장된 도형 정보를 표시하는 테이블뷰 셀 클래스입니다.
//    // MARK: - UI Components
//    private let addressLabel = UILabel() // 주소를 표시하는 레이블
//    private let dateRangeLabel = UILabel() // 날짜 범위를 표시하는 레이블
//    private let statusLabel = UILabel() // 상태(날짜 등)를 표시하는 레이블
//    private let radiusLabel = UILabel() // 반경을 표시하는 레이블
//    private let infoButton: UIButton = { // 정보 버튼
//        let button = UIButton(type: .system)
//        // 크기를 키운 심볼 이미지로 설정
//        if let image = UIImage(systemName: "info.circle") {
//            let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
//            button.setImage(image.withConfiguration(config), for: .normal)
//        }
//        button.tintColor = .systemBlue
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private let stackView = UIStackView() // 전체 레이아웃을 위한 스택뷰
//    
//    // stackView에 버튼을 옆에 붙일 수 있도록 dateRangeLabel + 버튼을 감싸는 horizontal stack
//    private let dateRangeContainer = UIStackView()
//    private let dateFormatter: DateFormatter = { // 날짜 포맷터
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter
//    }()
//    var infoButtonTapped: (() -> Void)? // info 버튼 탭 시 실행될 클로저
//    
//    // 곧 만료, 만료버튼 설정용
//    private let expireStatusButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemGray
//        button.layer.cornerRadius = 8
//        button.layer.masksToBounds = true
//        button.isHidden = true // 기본값: 숨김
//        button.translatesAutoresizingMaskIntoConstraints = false
//
//        if #available(iOS 15.0, *) {
//            var config = UIButton.Configuration.plain()
//            config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
//            button.configuration = config
//        } else {
//            button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
//        }
//        return button
//    }()
//    
//    // MARK: - Init
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupUI()
//    }
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupUI()
//    }
//    
//    // MARK: - UI Setup
//    private func setupUI() {
//        addressLabel.font = .preferredFont(forTextStyle: .body)
//        addressLabel.numberOfLines = 1
//        addressLabel.textColor = .label
//        addressLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
//        addressLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        
//        dateRangeLabel.font = .preferredFont(forTextStyle: .footnote)
//        dateRangeLabel.textColor = .secondaryLabel
//        dateRangeLabel.numberOfLines = 1
//        dateRangeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        
//        statusLabel.font = .preferredFont(forTextStyle: .caption1)
//        statusLabel.textColor = .tertiaryLabel
//        statusLabel.numberOfLines = 0
//        statusLabel.textAlignment = .left
//        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        
//        radiusLabel.font = .systemFont(ofSize: 13, weight: .regular)
//        radiusLabel.textColor = .systemGray2
//        radiusLabel.numberOfLines = 1
//        radiusLabel.textAlignment = .right
//        radiusLabel.setContentHuggingPriority(.required, for: .horizontal)
//        radiusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//        radiusLabel.adjustsFontSizeToFitWidth = true
//        radiusLabel.minimumScaleFactor = 0.7
//        radiusLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        infoButton.addTarget(self, action: #selector(infoButtonAction), for: .touchUpInside)
//        contentView.addSubview(infoButton)
//        contentView.addSubview(radiusLabel)
//        contentView.addSubview(stackView)
//        NSLayoutConstraint.activate([
//            infoButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            infoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
//            infoButton.widthAnchor.constraint(equalToConstant: 30),
//            infoButton.heightAnchor.constraint(equalToConstant: 30),
//            radiusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
//            radiusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
//            radiusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
//            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
//            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
//            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
//        ])
//
//        stackView.axis = .vertical
//        stackView.spacing = 4
//        stackView.alignment = .leading
//        stackView.distribution = .fill
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // dateRangeContainer: 수평 스택
//        dateRangeContainer.axis = .horizontal
//        dateRangeContainer.spacing = 6
//        dateRangeContainer.alignment = .center
//        dateRangeContainer.distribution = .fill
//        dateRangeContainer.translatesAutoresizingMaskIntoConstraints = false
//        dateRangeContainer.addArrangedSubview(dateRangeLabel)
//        dateRangeContainer.addArrangedSubview(expireStatusButton)
//        
//        // 스택뷰에 컴포넌트 추가
//        stackView.addArrangedSubview(addressLabel)
//        stackView.addArrangedSubview(statusLabel)
//        stackView.addArrangedSubview(dateRangeContainer)
//
//    }
//    
//    // MARK: - Configuration
//    func configure(with shape: PlaceShape) {
//        addressLabel.text = shape.title
//        
//        // 시작~종료일 표시
//        if let endDate = shape.expireDate {
//            let start = dateFormatter.string(from: shape.startedAt)
//            let end = dateFormatter.string(from: endDate)
//            dateRangeLabel.text = "\(start) ~ \(end)"
//        } else {
//            dateRangeLabel.text = dateFormatter.string(from: shape.startedAt)
//        }
//        
//        statusLabel.text = shape.address ?? "주소 없음"
//        
//        if let radius = shape.radius {
//            let numberFormatter = NumberFormatter()
//            numberFormatter.numberStyle = .decimal
//            let formattedRadius = numberFormatter.string(from: NSNumber(value: Int(radius))) ?? "-"
//            radiusLabel.text = "반경: \(formattedRadius) m"
//        } else {
//            radiusLabel.text = "반경: - m"
//        }
//        
//        setupAccessibility(with: shape)
//        
//        // 만료버튼 로직
//        expireStatusButton.isHidden = true
//        
//        if let expireDate = shape.expireDate {
//            let now = Date()
//            let calendar = Calendar.current
//            let daysLeft = calendar.dateComponents([.day], from: now.startOfDay, to: expireDate.startOfDay).day ?? 0
//
//            let font = UIFont.boldSystemFont(ofSize: 11)
//            let color = UIColor.white
//
//            // 만료된 경우 셀의 색상을 회색으로 변경
//            if daysLeft < 0 {
//                contentView.backgroundColor = .systemGray6
//                addressLabel.textColor = .systemGray
//                dateRangeLabel.textColor = .systemGray
//                statusLabel.textColor = .systemGray
//                radiusLabel.textColor = .systemGray
//            } else {
//                contentView.backgroundColor = .systemBackground
//                addressLabel.textColor = .label
//                dateRangeLabel.textColor = .secondaryLabel
//                statusLabel.textColor = .tertiaryLabel
//                radiusLabel.textColor = .systemGray2
//            }
//
//            if #available(iOS 15.0, *) {
//                var config = UIButton.Configuration.plain()
//                config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
//                
//                if daysLeft < 0 {
//                    expireStatusButton.isHidden = false
//                    config.attributedTitle = AttributedString("만료", attributes: AttributeContainer([
//                        .font: font,
//                        .foregroundColor: color
//                    ]))
//                    expireStatusButton.backgroundColor = .systemGray
//                } else if daysLeft <= 7 {
//                    expireStatusButton.isHidden = false
//                    config.attributedTitle = AttributedString("곧 만료", attributes: AttributeContainer([
//                        .font: font,
//                        .foregroundColor: color
//                    ]))
//                    expireStatusButton.backgroundColor = .systemRed
//                } else {
//                    expireStatusButton.isHidden = true
//                }
//                expireStatusButton.configuration = config
//            } else {
//                if daysLeft < 0 {
//                    expireStatusButton.isHidden = false
//                    expireStatusButton.setTitle("만료", for: .normal)
//                    expireStatusButton.titleLabel?.font = font
//                    expireStatusButton.setTitleColor(color, for: .normal)
//                    expireStatusButton.backgroundColor = .systemGray
//                } else if daysLeft <= 7 {
//                    expireStatusButton.isHidden = false
//                    expireStatusButton.setTitle("곧 만료", for: .normal)
//                    expireStatusButton.titleLabel?.font = font
//                    expireStatusButton.setTitleColor(color, for: .normal)
//                    expireStatusButton.backgroundColor = .systemRed
//                } else {
//                    expireStatusButton.isHidden = true
//                }
//            }
//        }
//    }
//    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        updateSelectionUI(selected: selected)
//    }
//
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        super.setHighlighted(highlighted, animated: animated)
//        // 스크롤 중 터치 하이라이트 방지: 아무것도 하지 않음
//        // 또는 필요시 아래 한 줄만 유지
//        // contentView.backgroundColor = highlighted ? UIColor.systemBlue : UIColor.white
//    }
//    
//    private func setupAccessibility(with shape: PlaceShape) { // 접근성 라벨 및 속성 설정
//        let address = shape.address ?? "주소 없음"
//        let dateRange = "\(dateFormatter.string(from: shape.startedAt)) ~ \(dateFormatter.string(from: shape.expireDate ?? Date()))"
//        let status = shape.memo ?? "메모 없음"
//        accessibilityLabel = "\(address), 시작일: \(dateRange), 상태: \(status)"
//        accessibilityTraits = .button
//        isAccessibilityElement = true
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        addressLabel.text = nil
//        dateRangeLabel.text = nil
//        statusLabel.text = nil
//        // 항상 초기화
//        updateSelectionUI(selected: false)
//    }
//    
//    private func updateSelectionUI(selected: Bool) {
//        contentView.backgroundColor = selected ? UIColor.systemBlue : UIColor.white
//        infoButton.tintColor = selected ? .white : .systemBlue
//    }
//    
//    func setLightTheme() { // 라이트 테마 색상 적용
//        addressLabel.textColor = .black
//        dateRangeLabel.textColor = .black
//        statusLabel.textColor = .black
//        backgroundColor = .white
//        contentView.backgroundColor = .white
//    }
//    
//    @objc private func infoButtonAction() { // info 버튼 탭 시 클로저 실행
//        infoButtonTapped?()
//    }
//}
//
//// startOfDay 확장
//extension Date {
//    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
//}
