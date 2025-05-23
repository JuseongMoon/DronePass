import UIKit
import MapSketch

final class ShapeDetailViewController: UIViewController {
    // MARK: - Properties
    private let shape: PlaceShape
    private let store = PlaceShapeStore.shared
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoStack = UIStackView()
    private let deleteButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(shape: PlaceShape) {
        self.shape = shape
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // 스크롤뷰/컨텐츠/스택뷰
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoStack)
        infoStack.axis = .vertical
        infoStack.spacing = 12
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        
        // 삭제 버튼
        view.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle("도형 삭제", for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // 오토레이아웃
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -16),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            infoStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 정보 표시
        infoStack.addArrangedSubview(makeInfoLabel("제목: \(shape.title)"))
        infoStack.addArrangedSubview(makeInfoLabel("도형 타입: \(shape.shapeType.rawValue)"))
        infoStack.addArrangedSubview(makeInfoLabel("주소: \(shape.address ?? "-")"))
        if let radius = shape.radius {
            infoStack.addArrangedSubview(makeInfoLabel("반경: \(radius) m"))
        }
        infoStack.addArrangedSubview(makeInfoLabel("메모: \(shape.memo ?? "-")"))
        infoStack.addArrangedSubview(makeInfoLabel("생성일: \(formattedDate(shape.createdAt))"))
        if let expire = shape.expireDate {
            infoStack.addArrangedSubview(makeInfoLabel("종료일: \(formattedDate(expire))"))
        }
        infoStack.addArrangedSubview(makeInfoLabel("색상: \(shape.color)"))
        infoStack.addArrangedSubview(makeInfoLabel("ID: \(shape.id.uuidString)"))
    }
    
    private func makeInfoLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "도형 삭제",
            message: "'\(shape.title)' 도형을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.store.removeShape(id: self?.shape.id ?? UUID())
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
} 