//
//  SavedShapeCell .swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

final class SavedShapeViewCell: UITableViewCell {
    // MARK: - UI Components
    private let addressLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let statusLabel = UILabel()
    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        if let image = UIImage(systemName: "info.circle") {
            button.setImage(image, for: .normal)
        }
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let stackView = UIStackView()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    var infoButtonTapped: (() -> Void)?
    
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
    func configure(with shape: PlaceShape) {
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
    
    private func setupAccessibility(with shape: PlaceShape) {
        let address = shape.address ?? "주소 없음"
        let dateRange = "\(dateFormatter.string(from: shape.createdAt)) ~ \(dateFormatter.string(from: shape.expireDate ?? Date()))"
        let status = shape.memo ?? "메모 없음"
        accessibilityLabel = "\(address), 생성일: \(dateRange), 상태: \(status)"
        accessibilityTraits = .button
        isAccessibilityElement = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        addressLabel.text = nil
        dateRangeLabel.text = nil
        statusLabel.text = nil
    }
    
    func setLightTheme() {
        addressLabel.textColor = .black
        dateRangeLabel.textColor = .black
        statusLabel.textColor = .black
        backgroundColor = .white
        contentView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        contentView.backgroundColor = selected ? UIColor.systemBlue : UIColor.white
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: true)
        contentView.backgroundColor = highlighted ? UIColor.systemBlue : UIColor.white
    }
    
    @objc private func infoButtonAction() {
        infoButtonTapped?()
    }
}
