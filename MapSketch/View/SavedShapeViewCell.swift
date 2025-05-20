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
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()
    private let stackView = UIStackView()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
        addressLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        dateLabel.font = .preferredFont(forTextStyle: .footnote)
        dateLabel.textColor = .secondaryLabel
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.textColor = .tertiaryLabel
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .right
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(addressLabel)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(statusLabel)
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
        dateLabel.text = dateFormatter.string(from: shape.createdAt)
        statusLabel.text = shape.memo ?? "메모 없음"
        setupAccessibility(with: shape)
    }
    
    private func setupAccessibility(with shape: PlaceShape) {
        let address = shape.address ?? "주소 없음"
        let date = dateFormatter.string(from: shape.createdAt)
        let status = shape.memo ?? "메모 없음"
        accessibilityLabel = "\(address), 생성일: \(date), 상태: \(status)"
        accessibilityTraits = .button
        isAccessibilityElement = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        addressLabel.text = nil
        dateLabel.text = nil
        statusLabel.text = nil
    }
}
