//
//  ShapeDetailViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
import UIKit

final class ShapeDetailViewController: UIViewController {
    private let shape: PlaceShape
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
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
    
    init(shape: PlaceShape) {
        self.shape = shape
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        configureInfo()
    }
    
    
    
    // MARK: - viewDidLayoutSubviews에서 각 뷰의 frame 찍기
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("scrollView frame:", scrollView.frame)
        print("contentView frame:", contentView.frame)
        print("infoStack frame:", infoStack.frame)
        for (i, view) in infoStack.arrangedSubviews.enumerated() {
            print("infoStack[\(i)] frame:", view.frame)
        }
    }
    
    
    private func setupLayout() {
        // 닫기 버튼
        view.addSubview(closeButton)
        print("closeButton added")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // 스크롤뷰, 컨텐츠, 스택
        view.addSubview(scrollView)
        print("scrollView added")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        print("contentView added")
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoStack)
        print("infoStack added")
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        
        
        // MARK: - (디버그)임시 색상으로 각각 확인
//        scrollView.backgroundColor = .yellow.withAlphaComponent(0.2)
//        contentView.backgroundColor = .cyan.withAlphaComponent(0.2)
//        infoStack.backgroundColor = .green.withAlphaComponent(0.2)
        
        
        // 버튼스택
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addArrangedSubview(editButton)
        buttonStack.addArrangedSubview(deleteButton)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            // 닫기 버튼
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 스크롤뷰
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -16),
            
            // contentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // infoStack
            infoStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24), // ★
            
            // 버튼스택
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    private func makeInfoRow(title: String, value: String) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, valueLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.distribution = .fill

        return row
    }
    
    private func configureInfo() {
         infoStack.addArrangedSubview(makeInfoRow(title: "제목", value: shape.title))
         infoStack.addArrangedSubview(makeInfoRow(title: "도형 타입", value: shape.shapeType.koreanName))
         infoStack.addArrangedSubview(makeInfoRow(title: "주소", value: shape.address ?? "-"))
         if let radius = shape.radius {
             infoStack.addArrangedSubview(makeInfoRow(title: "반경(m)", value: String(format: "%.0f", radius)))
         }
         infoStack.addArrangedSubview(makeInfoRow(title: "메모", value: shape.memo ?? "-"))
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
         infoStack.addArrangedSubview(makeInfoRow(title: "시작일", value: dateFormatter.string(from: shape.startedAt)))
         if let expire = shape.expireDate {
             infoStack.addArrangedSubview(makeInfoRow(title: "종료일", value: dateFormatter.string(from: expire)))
         }
        
    }
    
    // MARK: - 도형 세부정보

    private func makeInfoLabel(_ text: String) -> UILabel {
        print("makeInfoLabel: \(text)")
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "도형 삭제",
            message: "'\(shape.title)' 도형을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            PlaceShapeStore.shared.removeShape(id: self.shape.id)
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    @objc private func editButtonTapped() {
        // TODO: 수정 화면 이동 구현
    }
    @objc private func closeTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}
