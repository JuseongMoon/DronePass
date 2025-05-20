import UIKit

final class ShapeDetailViewController: UIViewController {
    private let shape: PlaceShape
    
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let addressLabel = UILabel()
    private let radiusLabel = UILabel()
    private let memoLabel = UILabel()
    private let createdAtLabel = UILabel()
    private let expireDateLabel = UILabel()
    private let colorLabel = UILabel()
    private let idLabel = UILabel()
    private let stackView = UIStackView()
    
    init(shape: PlaceShape) {
        self.shape = shape
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLabels()
        setupStackView()
        setupCloseButton()
        fillData()
    }
    
    private func setupLabels() {
        [titleLabel, typeLabel, addressLabel, radiusLabel, memoLabel, createdAtLabel, expireDateLabel, colorLabel, idLabel].forEach {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = .black
            $0.numberOfLines = 0
        }
    }
    
    private func setupStackView() {
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
    
    private func setupCloseButton() {
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
    
    @objc private func closeTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func fillData() {
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
