//
//  SavedBottomSheetViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//


import UIKit
import Combine



/// 터치 패스스루 컨테이너 필요 (BottomSheetContainerView.swift)
final class SavedBottomSheetViewController: UIViewController, UIGestureRecognizerDelegate {
    
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private lazy var handleTouchAreaView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    private lazy var handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = Metric.handleHeight / 2
        return view
    }()
    private lazy var contentView: UIView = {
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
    private lazy var containerView: BottomSheetContainerView = {
        let view = BottomSheetContainerView(sheetView: contentView)
        return view
    }()
    
    // MARK: - Constants
    private enum Metric {
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
    private let viewModel: SavedBottomSheetViewModel
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: SavedBottomSheetDelegate?
    private var sheetHeightConstraint: NSLayoutConstraint!
    private var initialHeight: CGFloat = 0
    private var hasSetInitialPosition = false
    
    // MARK: - Sheet Heights
    private let tabBarHeight: CGFloat
    private let collapsedHeight: CGFloat
    private var expandedHeight: CGFloat {
        view.bounds.height - view.safeAreaInsets.top - tabBarHeight - 8
    }
    private var midHeight: CGFloat
    
    // MARK: - Gestures
    private var panGesture: UIPanGestureRecognizer!
    
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
        self.view = PassThroughView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if let passView = self.view as? PassThroughView {
            passView.passThroughTarget = containerView
        }
        print("📱 SavedBottomSheetViewController - viewDidLoad")
        setupUI()
        bindViewModel()
        viewModel.loadData()
    }
    
    
    final class PassThroughView: UIView {
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
    private func setupUI() {
        setupContainerView()
        setupContentView()
        setupHandleView()
        setupTableView()
        setupGestures()
    }
    
    private func setupContainerView() {
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
    
    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupHandleView() {
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
    
    private func setupTableView() {
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: handleTouchAreaView.bottomAnchor, constant: Metric.tableViewTopPadding),
            tableView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupGestures() {
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
    
    private func setupInitialPosition() {
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
    private func bindViewModel() {
        viewModel.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (shapes: [PlaceShape]) in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Pan Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
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
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let currentHeight = sheetHeightConstraint.constant
        let targetHeight = currentHeight == expandedHeight ? midHeight : expandedHeight
        animateToHeight(targetHeight)
    }
    
    private func handlePanEnd(velocity: CGFloat) {
        if velocity > Metric.velocityThreshold {
            dismissSheet()
            return
        }
        let targetHeight = calculateTargetHeight(velocity: velocity)
        animateToHeight(targetHeight)
    }
    
    private func calculateTargetHeight(velocity: CGFloat) -> CGFloat {
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
    
    private func animateToHeight(_ height: CGFloat) {
        UIView.animate(withDuration: Metric.animationDuration) {
            self.sheetHeightConstraint.constant = height
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissSheet() {
        viewModel.dismissSheet()
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
    
    private func showShapeDetail(shape: PlaceShape) {
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
