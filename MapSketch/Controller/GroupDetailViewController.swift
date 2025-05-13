//
//  GroupDetailViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

import UIKit

class GroupDetailViewController: UIViewController {
  // 1) SavedViewController에서 전달된 그룹 모델
  var shapeGroup: ShapeGroup!

  // 2) UI 아웃렛 연결 (예: 라벨, 테이블 뷰 등)
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    title = shapeGroup.name
    nameLabel.text = shapeGroup.name
    // tableView.dataSource = self, delegate = self 등 설정
  }
}
