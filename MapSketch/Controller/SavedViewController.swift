//
//  SavedViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
// SavedViewController.swift
// MapSketch

import UIKit
import Combine

class SavedViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    /// JSONStorage 기반으로 바뀐 ShapeGroup 모델
    private var groups: [ShapeGroup] = []
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        bindStore()
    }

    private func setupUI() {
        title = "저장된 그룹"
        view.backgroundColor = .systemBackground
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    /// ShapeGroupStore의 @Published groups를 구독
    private func bindStore() {
        ShapeGroupStore.shared.$groups
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newGroups in
                self?.groups = newGroups
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension SavedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups.count
    }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell  = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        let group = groups[ip.row]

        cell.textLabel?.text = group.name
        cell.detailTextLabel?.text = "\(group.shapes.count)개 도형"
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)

        // DetailVC는 아직 없으므로, 먼저 스토리보드에 GroupDetailViewController를 만들고
        // Storyboard ID를 "GroupDetailViewController"로 지정하세요.
        guard
          let detailVC = storyboard?
            .instantiateViewController(withIdentifier: "GroupDetailViewController")
            as? GroupDetailViewController
        else { return }

        detailVC.shapeGroup = groups[ip.row]
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
