import UIKit
import Combine
import MapSketch

final class SavedBottomSheetViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet private weak var tableView: UITableView!
    private let viewModel = SavedBottomSheetViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SavedShapeCell", bundle: nil), forCellReuseIdentifier: "SavedShapeCell")
    }
    
    private func setupBindings() {
        viewModel.$shapes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension SavedBottomSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.shapes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SavedShapeCell", for: indexPath) as? SavedShapeCell else {
            return UITableViewCell()
        }
        
        let shape = viewModel.shapes[indexPath.row]
        cell.configure(with: shape)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SavedBottomSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let shape = viewModel.shapes[indexPath.row]
        NotificationCenter.default.post(name: ShapeSelectionCoordinator.shapeSelectedOnList, object: shape)
    }
} 