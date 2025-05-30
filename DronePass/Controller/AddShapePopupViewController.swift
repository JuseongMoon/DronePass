//
//  AddShapePopupViewController.swift
//  DronePass
//
//  Created by 문주성 on 5/28/25.
//

import UIKit

final class AddShapePopupViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    // MARK: - Properties
    private let coordinate: Coordinate
    private let onAdd: (PlaceShape) -> Void
    private var isEditMode: Bool = false
    private var originalShapeId: UUID?

    // UI Components
    private let titleField = UITextField()
    private let addressField = UITextField()
    private let radiusField = UITextField()
    private let memoView = UITextView()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let dateOnlySwitch = UISwitch()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // Layout
    private var memoHeightConstraint: NSLayoutConstraint!
    private let minMemoHeight: CGFloat = 300
    private var maxMemoHeight: CGFloat = 0
    private var memoOriginalHeight: CGFloat = 0
    private let memoViewHeight: CGFloat = 400
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Constants
    private let dateOnlyKey = "isDateOnlyMode"
    
    // State
    private var initialValues: (title: String?, address: String?, memo: String?, radius: Double?, startedAt: Date?, expireDate: Date?)?

    // MARK: - Initialization
    init(coordinate: Coordinate, onAdd: @escaping (PlaceShape) -> Void) {
        self.coordinate = coordinate
        self.onAdd = onAdd
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollViewLayout()
        setupUI()
        setupKeyboardObservers()
        setupTapToDismissKeyboard()
        setupDatePickers()
        fetchAddressForCoordinate()
        memoView.delegate = self
        memoView.isScrollEnabled = false
        setupKeyboardObservers()
        adjustMemoHeight()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMemoMaxHeight()
    }
    

    
    private func setupScrollViewLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let buttonStack = UIStackView(arrangedSubviews: [saveButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        setupButtons()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Setup Methods
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func updateMemoMaxHeight() {
        let maxAllowedHeight = UIScreen.main.bounds.height * 0.6
        maxMemoHeight = maxAllowedHeight
        adjustMemoHeight()
    }

    // MARK: - UI
    private func setupUI() {
        let memoRow = makeMemoRow()
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        contentView.addSubview(closeButton)
        
        let titleRow = makeInputRow(title: "제목", field: titleField)
        let addressRow = makeInputRow(title: "주소", field: addressField)
        let radiusRow = makeInputRow(title: "반경(m)", field: radiusField)
        let dateOnlyRow = makeDateOnlyRow()
        let startDateRow = makeDatePickerRow(title: "시작일", picker: startDatePicker)
        let endDateRow = makeDatePickerRow(title: "종료일", picker: endDatePicker)
        
        memoHeightConstraint = memoView.heightAnchor.constraint(equalToConstant: minMemoHeight)
        memoHeightConstraint.isActive = true
        
        setupInputFields()
        
        let stack = UIStackView(arrangedSubviews: [
            titleRow,
            addressRow,
            radiusRow,
            startDateRow,
            endDateRow,
            dateOnlyRow,
            memoRow
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupInputFields() {
        titleField.placeholder = "제목을 입력하세요"
        titleField.borderStyle = .roundedRect
        titleField.layer.borderColor = UIColor.systemGray4.cgColor
        titleField.layer.borderWidth = 1
        titleField.delegate = self
        titleField.layer.cornerRadius = 8
        titleField.returnKeyType = .next
        
        addressField.placeholder = "해당 장소의 주소를 입력하세요"
        addressField.borderStyle = .roundedRect
        addressField.layer.borderColor = UIColor.systemGray4.cgColor
        addressField.layer.borderWidth = 1
        addressField.delegate = self
        addressField.layer.cornerRadius = 8
        addressField.returnKeyType = .next
        
        radiusField.placeholder = "미터 단위로 입력해주세요"
        radiusField.borderStyle = .roundedRect
        radiusField.layer.borderColor = UIColor.systemGray4.cgColor
        radiusField.layer.borderWidth = 1
        radiusField.keyboardType = .numberPad
        radiusField.delegate = self
        radiusField.layer.cornerRadius = 8
        radiusField.returnKeyType = .next
        radiusField.inputAccessoryView = makeKeyboardToolbar()
        
        memoView.delegate = self
        memoView.returnKeyType = .default
    }
    
    private func setupButtons() {
        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        saveButton.layer.cornerRadius = 12
        saveButton.layer.masksToBounds = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .systemGray
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.masksToBounds = true
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    // 5. 키보드 알림에서 scrollView의 inset을 조정 (기존 keyboardWillShow, keyboardWillHide에서 추가/수정)
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        let buttonStackHeight: CGFloat = 50 + 16 + view.safeAreaInsets.bottom // 버튼 높이 + 하단 마진 + 세이프에어리어
        let insetsBottom = keyboardHeight - buttonStackHeight
        var insets = scrollView.contentInset
        insets.bottom = max(insetsBottom, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func makeInputRow(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        field.translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView(arrangedSubviews: [label, field])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .fill
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: field.centerYAnchor)
        ])
        return row
    }
    private func makeMemoRow() -> UIStackView {
        let label = UILabel()
        label.text = "메모"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        memoView.isEditable = true
        memoView.isSelectable = true
        memoView.font = .systemFont(ofSize: 16)
        memoView.dataDetectorTypes = [.link, .phoneNumber]
        memoView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        memoView.layer.borderWidth = 1
        memoView.layer.borderColor = UIColor.systemGray4.cgColor
        memoView.layer.cornerRadius = 8
        memoView.translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView(arrangedSubviews: [label, memoView])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        row.distribution = .fill
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: memoView.topAnchor, constant: 5)
        ])
        return row
    }
    private func makeDateOnlyRow() -> UIStackView {
        let label = UILabel()
        label.text = "일단위 입력"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let row = UIStackView(arrangedSubviews: [label, spacer, dateOnlySwitch])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return row
    }
    private func makeDatePickerRow(title: String, picker: UIDatePicker) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let pickerHeight: CGFloat = 34
        picker.heightAnchor.constraint(equalToConstant: pickerHeight).isActive = true
        let row = UIStackView(arrangedSubviews: [label, picker])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }
    // MARK: - 날짜 Picker 로직
    private func setupDatePickers() {
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.locale = Locale(identifier: "ko_KR")
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.locale = Locale(identifier: "ko_KR")
        dateOnlySwitch.isOn = UserDefaults.standard.bool(forKey: dateOnlyKey)
        updateDatePickerMode()
        if dateOnlySwitch.isOn {
            let calendar = Calendar.current
            var startComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            startComponents.hour = 0; startComponents.minute = 0; startComponents.second = 0
            if let newStart = calendar.date(from: startComponents) {
                startDatePicker.date = newStart
            }
            var endComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            endComponents.hour = 23; endComponents.minute = 59; endComponents.second = 0
            if let newEnd = calendar.date(from: endComponents) {
                endDatePicker.date = newEnd
            }
        }
        dateOnlySwitch.addTarget(self, action: #selector(dateOnlySwitchChanged), for: .valueChanged)
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
    }
    @objc private func startDateChanged() {
        endDatePicker.minimumDate = startDatePicker.date
        if endDatePicker.date < startDatePicker.date {
            endDatePicker.date = startDatePicker.date
        }
    }
    @objc private func dateOnlySwitchChanged() {
        updateDatePickerMode()
        if dateOnlySwitch.isOn {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: startDatePicker.date)
            components.hour = 0; components.minute = 0
            if let newDate = calendar.date(from: components) {
                startDatePicker.date = newDate
            }
            components = calendar.dateComponents([.year, .month, .day], from: endDatePicker.date)
            components.hour = 23; components.minute = 59
            if let newDate = calendar.date(from: components) {
                endDatePicker.date = newDate
            }
        }
        UserDefaults.standard.set(dateOnlySwitch.isOn, forKey: dateOnlyKey)
    }
    private func updateDatePickerMode() {
        let mode: UIDatePicker.Mode = dateOnlySwitch.isOn ? .date : .dateAndTime
        startDatePicker.datePickerMode = mode
        endDatePicker.datePickerMode = mode
    }
    // MARK: - 키보드 관련
    private func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.items = [UIBarButtonItem.flexibleSpace(), done]
        return toolbar
    }
    @objc private func doneButtonTapped() {
        view.endEditing(true)
    }
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            addressField.becomeFirstResponder()
        } else if textField == addressField {
            radiusField.becomeFirstResponder()
        } else if textField == radiusField {
            memoView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    // MARK: - PlaceShape 생성 및 저장
    @objc private func saveTapped() {
        let title = titleField.text?.isEmpty == false ? titleField.text! : "새 도형"
        let address = addressField.text?.isEmpty == false ? addressField.text : nil
        let memo = memoView.text
        let radius = Double(radiusField.text ?? "") ?? 200
        let newShape = PlaceShape(
            id: originalShapeId ?? UUID(),
            title: title,
            shapeType: .circle,
            baseCoordinate: coordinate,
            radius: radius,
            memo: memo,
            address: address,
            expireDate: endDatePicker.date,
            startedAt: startDatePicker.date,
            color: ColorManager.shared.defaultColor.rawValue
        )
        onAdd(newShape)
        dismiss(animated: true)
    }
    @objc private func cancelTapped() {
        if hasChanges() {
            let alert = UIAlertController(
                title: "수정 중인 정보가 있습니다",
                message: "수정 중인 내용이 모두 사라집니다. 닫으시겠습니까?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "닫기", style: .destructive) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    private func hasChanges() -> Bool {
        guard let initial = initialValues else { return false }
        let currentTitle = titleField.text
        let currentAddress = addressField.text
        let currentMemo = memoView.text
        let currentRadius = Double(radiusField.text ?? "")
        let currentStartedAt = startDatePicker.date
        let currentExpireDate = endDatePicker.date
        return currentTitle != initial.title ||
               currentAddress != initial.address ||
               currentMemo != initial.memo ||
               currentRadius != initial.radius ||
               currentStartedAt != initial.startedAt ||
               currentExpireDate != initial.expireDate
    }
    // MARK: - 주소 자동조회
    private func fetchAddressForCoordinate() {
        if addressField.text != nil { return }
        NaverGeocodingService.shared.fetchAddress(latitude: coordinate.latitude, longitude: coordinate.longitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let address):
                    self?.addressField.text = address
                case .failure:
                    self?.addressField.text = "주소를 찾을 수 없음"
                }
            }
        }
    }
    // MARK: - 외부에서 수정/초기값 주입시 사용
    public func setInitialValues(title: String?, address: String?, memo: String?, radius: Double?, startedAt: Date?, expireDate: Date?, shapeId: UUID? = nil) {
        isEditMode = true
        originalShapeId = shapeId
        initialValues = (title, address, memo, radius, startedAt, expireDate)
        titleField.text = title
        addressField.text = address
        memoView.text = memo
        if let radius = radius {
            radiusField.text = String(format: "%.0f", radius)
        }
        if let startedAt = startedAt {
            startDatePicker.date = startedAt
        }
        if let expireDate = expireDate {
            endDatePicker.date = expireDate
        }
    }
    public func setInitialAddress(_ address: String?) {
        addressField.text = address
    }
    // MARK: - 메모 높이
    private func adjustMemoHeight() {
        let width = memoView.frame.width > 0 ? memoView.frame.width : UIScreen.main.bounds.width - 48 - 80 - 12
        let size = memoView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        var newHeight = size.height
        
        // 최소 높이 적용
        newHeight = max(minMemoHeight, newHeight)
        
        // 최대 높이 제한 (화면 높이의 60%로 제한)
        let maxAllowedHeight = UIScreen.main.bounds.height * 0.6
        newHeight = min(maxAllowedHeight, newHeight)
        
        if memoHeightConstraint.constant != newHeight {
            memoHeightConstraint.constant = newHeight
            memoView.isScrollEnabled = (newHeight >= maxAllowedHeight)
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        adjustMemoHeight()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


