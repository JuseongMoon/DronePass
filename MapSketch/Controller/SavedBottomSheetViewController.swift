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
    private lazy var handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = Metric.handleHeight / 2
        return view
    }()
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = Metric.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
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
        static let handleHeight: CGFloat = 6
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
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 SavedBottomSheetViewController - viewDidLoad")
        setupUI()
        bindViewModel()
        viewModel.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 SavedBottomSheetViewController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 SavedBottomSheetViewController - viewDidAppear")
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupContainerView()
        setupContentView()
        setupHandleView()
        setupTableView()
        setupGestures()
        setupInitialPosition()
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
        handleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(handleView)
        
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metric.handleTopPadding),
            handleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
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
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: Metric.tableViewTopPadding),
            tableView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func setupInitialPosition() {
        guard !hasSetInitialPosition else { return }
        hasSetInitialPosition = true
        view.layoutIfNeeded()
        sheetHeightConstraint.constant = midHeight
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
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: containerView)
        return location.y <= Metric.dragThreshold
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
        return cell
    }
}

// MARK: - UITableViewDelegate, UIScrollViewDelegate
extension SavedBottomSheetViewController: UITableViewDelegate, UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectShape(at: indexPath)
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
