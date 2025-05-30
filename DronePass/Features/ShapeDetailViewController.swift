import UIKit // UIKit 프레임워크를 가져옵니다. (iOS 앱의 기본 UI 컴포넌트들을 사용하기 위함)

final class ShapeDetailViewController: UIViewController { // 도형 상세 정보를 보여주는 뷰 컨트롤러입니다.
    private let shape: PlaceShape // 표시할 도형 데이터를 저장하는 프로퍼티입니다.
    
    // UI 컴포넌트들을 선언합니다.
    private let titleLabel = UILabel() // 제목을 표시할 레이블
    private let typeLabel = UILabel() // 도형 타입을 표시할 레이블
    private let addressLabel = UILabel() // 주소를 표시할 레이블
    private let radiusLabel = UILabel() // 반경을 표시할 레이블
    private let memoLabel = UILabel() // 메모를 표시할 레이블
    private let createdAtLabel = UILabel() // 생성일을 표시할 레이블
    private let expireDateLabel = UILabel() // 종료일을 표시할 레이블
    private let colorLabel = UILabel() // 색상을 표시할 레이블
    private let idLabel = UILabel() // ID를 표시할 레이블
    private let stackView = UIStackView() // 레이블들을 수직으로 배치할 스택뷰
    private let editButton = UIButton(type: .system)
    
    init(shape: PlaceShape) { // 초기화 메서드입니다.
        self.shape = shape // 전달받은 도형 데이터를 저장합니다.
        super.init(nibName: nil, bundle: nil) // 부모 클래스의 초기화 메서드를 호출합니다.
    }
    
    required init?(coder: NSCoder) { // Storyboard에서 초기화할 때 필요한 메서드입니다.
        fatalError("init(coder:) has not been implemented") // Storyboard 초기화는 지원하지 않습니다.
    }
    
    override func viewDidLoad() { // 뷰가 로드될 때 호출되는 메서드입니다.
        super.viewDidLoad() // 부모 클래스의 메서드를 호출합니다.
        view.backgroundColor = .white // 배경색을 흰색으로 설정합니다.
        setupLabels() // 레이블들의 기본 설정을 합니다.
        setupStackView() // 스택뷰를 설정합니다.
        setupCloseButton() // 닫기 버튼을 설정합니다.
        setupEditButton() // 수정하기 버튼을 설정합니다.
        fillData() // 도형 데이터를 UI에 표시합니다.
    }
    
    private func setupLabels() { // 레이블들의 기본 설정을 하는 메서드입니다.
        [titleLabel, typeLabel, addressLabel, radiusLabel, memoLabel, createdAtLabel, expireDateLabel, colorLabel, idLabel].forEach {
            $0.font = .systemFont(ofSize: 16) // 폰트 크기를 16으로 설정합니다.
            $0.textColor = .black // 텍스트 색상을 검정색으로 설정합니다.
            $0.numberOfLines = 0 // 여러 줄 표시가 가능하도록 설정합니다.
        }
    }
    
    private func setupStackView() { // 스택뷰를 설정하는 메서드입니다.
        stackView.axis = .vertical // 수직 방향으로 배치합니다.
        stackView.spacing = 12 // 요소들 사이의 간격을 12로 설정합니다.
        stackView.alignment = .leading // 왼쪽 정렬로 설정합니다.
        stackView.translatesAutoresizingMaskIntoConstraints = false // Auto Layout을 사용하기 위해 설정합니다.
        [titleLabel, typeLabel, addressLabel, radiusLabel, memoLabel, createdAtLabel, expireDateLabel, colorLabel, idLabel].forEach {
            stackView.addArrangedSubview($0) // 모든 레이블을 스택뷰에 추가합니다.
        }
        view.addSubview(stackView) // 스택뷰를 메인 뷰에 추가합니다.
        NSLayoutConstraint.activate([ // 스택뷰의 위치와 크기를 설정합니다.
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24), // 상단 여백 24
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), // 좌측 여백 20
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20) // 우측 여백 20
        ])
    }
    
    private func setupCloseButton() { // 닫기 버튼을 설정하는 메서드입니다.
        let closeButton = UIButton(type: .system) // 시스템 스타일의 버튼을 생성합니다.
        closeButton.setTitle("닫기", for: .normal) // 버튼의 텍스트를 설정합니다.
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 17) // 폰트를 굵게 설정합니다.
        closeButton.tintColor = .systemBlue // 버튼 색상을 파란색으로 설정합니다.
        closeButton.translatesAutoresizingMaskIntoConstraints = false // Auto Layout을 사용하기 위해 설정합니다.
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside) // 버튼 탭 이벤트를 처리할 메서드를 연결합니다.
        view.addSubview(closeButton) // 버튼을 메인 뷰에 추가합니다.
        NSLayoutConstraint.activate([ // 버튼의 위치를 설정합니다.
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8), // 상단 여백 8
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16) // 우측 여백 16
        ])
    }
    
    private func setupEditButton() {
        editButton.setTitle("수정하기", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.backgroundColor = .systemBlue
        editButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        editButton.layer.cornerRadius = 12
        editButton.layer.masksToBounds = true
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        view.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            editButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func closeTapped() { // 닫기 버튼이 탭되었을 때 호출되는 메서드입니다.
        if let nav = navigationController { // 네비게이션 컨트롤러가 있다면
            nav.popViewController(animated: true) // 이전 화면으로 돌아갑니다.
        } else { // 네비게이션 컨트롤러가 없다면
            dismiss(animated: true, completion: nil) // 모달을 닫습니다.
        }
    }
    
    @objc private func editTapped() {
        let editVC = AddShapePopupViewController(
            coordinate: shape.baseCoordinate,
            onAdd: { [weak self] newShape in
                // 기존 도형을 삭제하고 새 도형으로 교체 (ID 유지)
                PlaceShapeStore.shared.removeShape(id: self?.shape.id ?? newShape.id)
                PlaceShapeStore.shared.addShape(newShape)
                self?.dismiss(animated: true)
            }
        )
        // 기존 값 전달 (AddShapePopupViewController에 프로퍼티 추가 필요)
        editVC.modalPresentationStyle = .fullScreen
        // 아래는 AddShapePopupViewController에 public 프로퍼티로 선언되어 있어야 함
        if let vc = editVC as? AddShapePopupViewController {
            vc.setInitialValues(
                title: shape.title,
                address: shape.address,
                memo: shape.memo,
                radius: shape.radius,
                startedAt: shape.startedAt,
                expireDate: shape.expireDate
            )
        }
        present(editVC, animated: true)
    }
    
    private func fillData() { // 도형 데이터를 UI에 표시하는 메서드입니다.
        titleLabel.text = "제목: \(shape.title)" // 제목을 표시합니다.
        typeLabel.text = "도형 타입: \(shape.shapeType.rawValue)" // 도형 타입을 표시합니다.
        addressLabel.text = "주소: \(shape.address ?? "-")" // 주소를 표시합니다. 없으면 "-"를 표시합니다.
        radiusLabel.text = "반경: \(shape.radius != nil ? String(format: "%.0f m", shape.radius!) : "-")" // 반경을 표시합니다. 없으면 "-"를 표시합니다.
        memoLabel.text = "메모: \(shape.memo ?? "-")" // 메모를 표시합니다. 없으면 "-"를 표시합니다.
        let dateFormatter = DateFormatter() // 날짜 포맷터를 생성합니다.
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 날짜 형식을 설정합니다.
        createdAtLabel.text = "생성일: \(dateFormatter.string(from: shape.createdAt))" // 생성일을 표시합니다.
        if let expire = shape.expireDate { // 종료일이 있다면
            expireDateLabel.text = "종료일: \(dateFormatter.string(from: expire))" // 종료일을 표시합니다.
        } else { // 종료일이 없다면
            expireDateLabel.text = "종료일: -" // "-"를 표시합니다.
        }
        colorLabel.text = "색상: \(shape.color)" // 색상을 표시합니다.
        idLabel.text = "ID: \(shape.id.uuidString)" // ID를 표시합니다.
    }
} 