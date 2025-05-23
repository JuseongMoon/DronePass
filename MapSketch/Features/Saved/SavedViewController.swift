import UIKit
import NMapsMap
import Combine

final class SavedViewController: UIViewController {
    let naverMapView = NMFNaverMapView()
    private let tableView = UITableView()
    private var cancellables = Set<AnyCancellable>()
    private var shapes: [PlaceShape] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupTableView()
        bindShapes()
        setupLongPressGesture()
    }

    private func setupMap() {
        naverMapView.frame = view.bounds
        naverMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(naverMapView)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 300)
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SavedShapeViewCell.self, forCellReuseIdentifier: "SavedShapeViewCell")
        tableView.register(AddShapeButtonCell.self, forCellReuseIdentifier: "AddShapeButtonCell")
        tableView.tableFooterView = UIView()
    }

    private func bindShapes() {
        PlaceShapeStore.shared.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shapes in
                self?.shapes = shapes
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        naverMapView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: naverMapView)
            let latLng = naverMapView.mapView.projection.latlng(from: point)
            let coordinate = Coordinate(latitude: latLng.lat, longitude: latLng.lng)
            let newShape = PlaceShape(
                title: "새 도형",
                shapeType: .circle,
                baseCoordinate: coordinate,
                radius: 100,
                memo: "지도에서 생성"
            )
            PlaceShapeStore.shared.addShape(newShape)
        }
    }

    private func presentAddShapePopup() {
        let addVC = AddShapePopupViewController()
        addVC.modalPresentationStyle = .overCurrentContext
        addVC.onAddShape = { [weak self] newShape in
            PlaceShapeStore.shared.addShape(newShape)
            self?.dismiss(animated: true)
        }
        present(addVC, animated: true)
    }
}

extension SavedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shapes.count + 1 // 마지막 셀은 추가 버튼
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < shapes.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SavedShapeViewCell", for: indexPath) as? SavedShapeViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: shapes[indexPath.row])
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddShapeButtonCell", for: indexPath) as? AddShapeButtonCell else {
                return UITableViewCell()
            }
            cell.onAddTapped = { [weak self] in
                self?.presentAddShapePopup()
            }
            return cell
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row < shapes.count {
            let shape = shapes[indexPath.row]
            PlaceShapeStore.shared.removeShape(id: shape.id)
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < shapes.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == shapes.count {
            return 64 // 추가 버튼 셀 높이
        }
        return 80 // 일반 셀 높이
    }
}

// MARK: - 커스텀 추가 버튼 셀
final class AddShapeButtonCell: UITableViewCell {
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 도형 추가", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    var onAddTapped: (() -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            addButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc private func addTapped() {
        onAddTapped?()
    }
}

// MARK: - 도형 추가 팝업 뷰컨트롤러
final class AddShapePopupViewController: UIViewController {
    var onAddShape: ((PlaceShape) -> Void)?
    private let titleField = UITextField()
    private let memoField = UITextField()
    private let addButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 16
        popup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popup)
        NSLayoutConstraint.activate([
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.widthAnchor.constraint(equalToConstant: 300),
            popup.heightAnchor.constraint(equalToConstant: 220)
        ])
        titleField.placeholder = "제목"
        titleField.borderStyle = .roundedRect
        memoField.placeholder = "메모"
        memoField.borderStyle = .roundedRect
        addButton.setTitle("추가", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [titleField, memoField, addButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: popup.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: popup.bottomAnchor, constant: -20)
        ])
        addButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addButton.addTarget(self, action: #selector(addShape), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }
    @objc private func addShape() {
        let title = titleField.text?.isEmpty == false ? titleField.text! : "새 도형"
        let memo = memoField.text
        let newShape = PlaceShape(
            title: title,
            shapeType: .circle,
            baseCoordinate: Coordinate(latitude: 37.5, longitude: 127.0),
            radius: 100,
            memo: memo
        )
        onAddShape?(newShape)
    }
    @objc private func cancel() {
        dismiss(animated: true)
    }
} 