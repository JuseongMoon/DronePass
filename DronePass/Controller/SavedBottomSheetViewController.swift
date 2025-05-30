//
//  SavedBottomSheetViewController.swift
//  DronePass
//
//  Created by 문주성 on 5/13/25.
//

// 역할: 저장된 도형 목록을 바텀시트로 보여주는 뷰 컨트롤러
// 연관기능: 바텀시트 오버레이, 테이블뷰, 제스처, 도형 상세 보기

import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
import Combine // Combine 프레임워크를 가져옵니다. (반응형 프로그래밍)

/// 터치 패스스루 컨테이너 필요 (BottomSheetContainerView.swift)
final class SavedBottomSheetViewController: UIViewController, UIGestureRecognizerDelegate { // 저장된 도형 목록을 바텀시트로 보여주는 뷰 컨트롤러입니다.
    
    // MARK: - UI Components
    private let tableView = UITableView() // 도형 목록을 표시할 테이블뷰입니다.
    
    //안내 라벨 속성값
    private let emptyMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "지도의 원하는곳을 길게 터치해 새로운 도형을 만들어보세요"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var handleTouchAreaView: UIView = { // 핸들 터치 영역 뷰입니다.
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    private lazy var handleView: UIView = { // 바텀시트 핸들 바 뷰입니다.
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = Metric.handleHeight / 2
        return view
    }()
    private lazy var contentView: UIView = { // 바텀시트 실제 내용 뷰입니다.
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = Metric.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = Metric.shadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: Metric.shadowYOffset)
        view.layer.shadowRadius = Metric.shadowRadius
        view.isUserInteractionEnabled = true
        return view
    }()
    private lazy var containerView: BottomSheetContainerView = { // 바텀시트 전체를 감싸는 컨테이너 뷰입니다.
        let view = BottomSheetContainerView(sheetView: contentView)
        return view
    }()
    
    // MARK: - Constants
    private enum Metric { // UI 관련 상수 모음입니다.
        static let handleHeight: CGFloat = 9
        static let handleWidth: CGFloat = 40
        static let handleTopPadding: CGFloat = 8
        static let tableViewTopPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 16
        static let dragThreshold: CGFloat = 40
        static let rowHeight: CGFloat = 80
        static let shadowOpacity: Float = 0.15
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = -2
        static let animationDuration: TimeInterval = 0.3
        static let velocityThreshold: CGFloat = 500
    }
    
    // MARK: - Properties
    private let viewModel: SavedBottomSheetViewModel // 바텀시트의 뷰모델입니다.
    private var cancellables = Set<AnyCancellable>() // Combine 구독 해제용
    weak var delegate: SavedBottomSheetDelegate? // 바텀시트 델리게이트
    private var sheetHeightConstraint: NSLayoutConstraint! // 시트 높이 제약조건
    private var initialHeight: CGFloat = 0 // 드래그 시작 시 높이
    private var hasSetInitialPosition = false // 초기 위치 설정 여부
    private var selectedShapeID: UUID? // 선택상태
    
    // MARK: - Sheet Heights
    private let tabBarHeight: CGFloat // 탭바 높이
    private let collapsedHeight: CGFloat // 최소 높이
    private var expandedHeight: CGFloat { // 최대 높이
        view.bounds.height - view.safeAreaInsets.top - tabBarHeight - 8
    }
    private var midHeight: CGFloat // 중간 높이
    
    // MARK: - Gestures
    private var panGesture: UIPanGestureRecognizer! // 팬 제스처
    
    // MARK: - Initialization
    init(viewModel: SavedBottomSheetViewModel,
         tabBarHeight: CGFloat = 49,
         collapsedHeight: CGFloat = 200,
         midHeight: CGFloat = 430) {
        self.viewModel = viewModel
        self.tabBarHeight = tabBarHeight
        self.collapsedHeight = collapsedHeight
        self.midHeight = midHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let viewModel = SavedBottomSheetViewModel()
        self.viewModel = viewModel
        self.tabBarHeight = 49
        self.collapsedHeight = 200
        self.midHeight = 430
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = PassThroughView() // 터치 패스스루 뷰로 교체
    }
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(highlightShapeInList(_:)), name: Notification.Name("HighlightShapeInList"), object: nil)

        view.backgroundColor = .clear
        if let passView = self.view as? PassThroughView {
            passView.passThroughTarget = containerView
        }
        print("📱 SavedBottomSheetViewController - viewDidLoad")
        setupUI()
        bindViewModel()
        viewModel.loadData()
        
    }
    
    // 리스트에서 하이라이트하는 코드
    @objc private func highlightShapeInList(_ notification: Notification) {
        guard let shape = notification.object as? PlaceShape else { return }
        guard let idx = viewModel.shapes.firstIndex(where: { $0.id == shape.id }) else { return }
        let indexPath = IndexPath(row: idx, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    }
    
    
    final class PassThroughView: UIView { // 내부에서만 사용하는 패스스루 뷰입니다.
        weak var passThroughTarget: UIView?
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if let target = passThroughTarget {
                let targetPoint = convert(point, to: target)
                if target.bounds.contains(targetPoint) {
                    return super.hitTest(point, with: event)
                }
                return nil
            }
            return super.hitTest(point, with: event)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 SavedBottomSheetViewController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 SavedBottomSheetViewController - viewDidAppear")
        setupInitialPosition()
    }
    
    // MARK: - Setup
    private func setupUI() { // UI 전체를 설정하는 메서드입니다.
        setupContainerView()
        setupContentView()
        setupHandleView()
        setupTableView()
        setupGestures()
    }
    
    private func setupContainerView() { // 컨테이너 뷰 설정
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        sheetHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: midHeight)
        sheetHeightConstraint.isActive = true
    }
    
    private func setupContentView() { // 내용 뷰 제약조건 설정
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupHandleView() { // 핸들 바 및 터치 영역 제약조건 설정
        contentView.addSubview(handleTouchAreaView)
        contentView.addSubview(handleView)
        handleTouchAreaView.translatesAutoresizingMaskIntoConstraints = false
        handleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 터치 영역은 높이 40, 전체 폭
            handleTouchAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            handleTouchAreaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            //            handleTouchAreaView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8),
            
            handleTouchAreaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            handleTouchAreaView.heightAnchor.constraint(equalToConstant: 40),
            // 핸들 바는 중앙에 위치, 높이 6, 폭 40
            handleView.centerXAnchor.constraint(equalTo: handleTouchAreaView.centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: handleTouchAreaView.centerYAnchor),
            handleView.widthAnchor.constraint(equalToConstant: Metric.handleWidth),
            handleView.heightAnchor.constraint(equalToConstant: Metric.handleHeight)
        ])
    }
    
    private func setupTableView() { // 테이블뷰 설정 및 제약조건
        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = Metric.rowHeight
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.register(SavedShapeViewCell.self, forCellReuseIdentifier: "SavedShapeViewCell")
        tableView.delaysContentTouches = false
        tableView.canCancelContentTouches = true
        tableView.backgroundColor = .white
        tableView.separatorColor = .lightGray
        
        updateEmptyMessageVisibility() // 테이블데이터가 비었을때 메세지 보여주는 함수 호출
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: handleTouchAreaView.bottomAnchor, constant: Metric.tableViewTopPadding),
            tableView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupGestures() { // 제스처(드래그, 탭) 설정
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        handleTouchAreaView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        handleTouchAreaView.addGestureRecognizer(tapGesture)
    }
    
    private func setupInitialPosition() { // 시트의 초기 위치를 설정합니다.
        guard !hasSetInitialPosition else { return }
        hasSetInitialPosition = true
        
        // 초기 레이아웃 설정
        view.layoutIfNeeded()
        sheetHeightConstraint.constant = midHeight
        
        // 애니메이션으로 부드럽게 표시
        UIView.animate(withDuration: Metric.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() { // 뷰모델과 바인딩하여 데이터 변경 시 UI를 갱신합니다.
        viewModel.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (shapes: [PlaceShape]) in
                self?.tableView.reloadData()
                self?.updateEmptyMessageVisibility()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 테이블이 비었을때 화면 도출

    private func updateEmptyMessageVisibility() {
        if viewModel.shapes.isEmpty {
            tableView.backgroundView = emptyMessageLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - Pan Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) { // 팬 제스처(드래그) 처리 메서드입니다.
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        
        switch gesture.state {
        case .began:
            initialHeight = sheetHeightConstraint.constant
        case .changed:
            let newHeight = initialHeight - translation
            sheetHeightConstraint.constant = newHeight.clamped(to: collapsedHeight...expandedHeight)
            view.layoutIfNeeded()
        case .ended, .cancelled:
            handlePanEnd(velocity: velocity)
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) { // 핸들 바를 탭하면 시트 높이 토글
        let currentHeight = sheetHeightConstraint.constant
        let targetHeight = currentHeight == expandedHeight ? midHeight : expandedHeight
        animateToHeight(targetHeight)
    }
    
    private func handlePanEnd(velocity: CGFloat) { // 드래그 종료 시 처리
        if velocity > Metric.velocityThreshold {
            dismissSheet()
            return
        }
        let targetHeight = calculateTargetHeight(velocity: velocity)
        animateToHeight(targetHeight)
    }
    
    private func calculateTargetHeight(velocity: CGFloat) -> CGFloat { // 드래그 속도에 따라 목표 높이 계산
        if velocity < -Metric.velocityThreshold {
            return expandedHeight
        }
        let currentHeight = sheetHeightConstraint.constant
        let distances = [
            (height: collapsedHeight, distance: abs(currentHeight - collapsedHeight)),
            (height: midHeight, distance: abs(currentHeight - midHeight)),
            (height: expandedHeight, distance: abs(currentHeight - expandedHeight))
        ]
        return distances.min { $0.distance < $1.distance }?.height ?? midHeight
    }
    
    private func animateToHeight(_ height: CGFloat) { // 시트 높이 애니메이션
        UIView.animate(withDuration: Metric.animationDuration) {
            self.sheetHeightConstraint.constant = height
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissSheet() { // 시트 닫기 처리
//        viewModel.dismissSheet()
        delegate?.savedBottomSheetDidDismiss()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 테이블뷰의 스크롤과 시트의 드래그 동작을 분리
        if otherGestureRecognizer == tableView.panGestureRecognizer {
            let location = gestureRecognizer.location(in: handleTouchAreaView)
            return handleTouchAreaView.bounds.contains(location)
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            let location = gestureRecognizer.location(in: handleTouchAreaView)
            return handleTouchAreaView.bounds.contains(location)
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 테이블뷰의 스크롤 제스처가 실패한 경우에만 팬 제스처를 인식
        if gestureRecognizer == panGesture && otherGestureRecognizer == tableView.panGestureRecognizer {
            return true
        }
        return false
    }
}

// MARK: - UITableViewDataSource
extension SavedBottomSheetViewController: UITableViewDataSource {
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.shapes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SavedShapeViewCell", for: indexPath) as? SavedShapeViewCell else {
            return UITableViewCell()
        }
        let shape = viewModel.shapes[indexPath.row]
        cell.configure(with: shape)
        cell.backgroundColor = .white
        cell.contentView.backgroundColor = .white
        cell.setLightTheme()
        cell.infoButtonTapped = { [weak self] in
            self?.showShapeDetail(shape: shape)
        }
        return cell
    }
    
    private func showShapeDetail(shape: PlaceShape) { // 도형 상세 화면 표시
        let detailVC = ShapeDetailViewController(shape: shape)
        detailVC.modalPresentationStyle = .fullScreen
        if let nav = self.navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            self.present(detailVC, animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDelegate, UIScrollViewDelegate
extension SavedBottomSheetViewController: UITableViewDelegate, UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 선택된 셀이 계속 선택 상태로 유지되도록 deselectRow를 호출하지 않음
        let shape = viewModel.shapes[indexPath.row]
        ShapeSelectionCoordinator.shared.selectShapeOnList(shape)
    }
    // 스크롤 시작 시 바텀시트 드래그 비활성화
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        panGesture.isEnabled = false
    }
    // 스크롤 끝나면 바텀시트 드래그 다시 활성화
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            panGesture.isEnabled = true
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        panGesture.isEnabled = true
    }
}





// MARK: - Comparable Extension
private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
}
