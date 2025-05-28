//
//  ColorPickerViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/26/25.
//

import UIKit

/// 도형 색상 선택 화면 (테이블형 컬러피커)
class ColorPickerViewController: UIViewController {
    var onColorSelected: ((PaletteColor) -> Void)?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // 현재 선택된 색상의 인덱스를 변수로 저장
    private var selectedColorIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "색상 선택"
        view.backgroundColor = .systemGroupedBackground
        
        // 첫 번째 도형의 색상에 해당하는 인덱스를 계산해서 변수에 저장
        if let firstShape = PlaceShapeStore.shared.shapes.first,
           let idx = ColorManager.palette.firstIndex(where: { $0.hex.lowercased() == firstShape.color.lowercased() }) {
            selectedColorIndex = idx
        } else {
            selectedColorIndex = 0 // 기본값(파랑)
        }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 56
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ColorCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 화면에 보인 후에만 셀을 선택 상태로 표시 가능
        let indexPath = IndexPath(row: selectedColorIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    }
}

extension ColorPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ColorManager.palette.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let color = ColorManager.palette[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)
        cell.selectionStyle = .none

        // 색상명 한글 표기
        let colorName: String
        switch color {
        case .red:    colorName = "빨강"
        case .orange: colorName = "오렌지"
        case .yellow: colorName = "노랑"
        case .green:  colorName = "초록"
        case .teal:   colorName = "청록"
        case .blue:   colorName = "파랑"
        case .indigo: colorName = "남색"
        case .purple: colorName = "보라"
        case .pink:   colorName = "분홍"
        case .gray:   colorName = "회색"
        }
        cell.textLabel?.text = colorName
        cell.imageView?.image = UIImage(color: color.uiColor, size: CGSize(width: 14, height: 14)).circleMasked

        // **하이라이트(선택) 표시: 체크마크/배경/폰트 등으로 명확하게!**
        if indexPath.row == selectedColorIndex {
            cell.accessoryType = .checkmark
            cell.textLabel?.font = .boldSystemFont(ofSize: 17)
//            cell.contentView.backgroundColor = color.uiColor.withAlphaComponent(0.15)
        } else {
            cell.accessoryType = .none
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.contentView.backgroundColor = .clear
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedColorIndex = indexPath.row // 선택 인덱스 갱신
        let color = ColorManager.palette[indexPath.row]
        PlaceShapeStore.shared.updateAllShapesColor(to: color.hex)
        tableView.reloadData() // 모든 셀의 하이라이트/체크박크를 갱신
        onColorSelected?(color)
        dismiss(animated: true)
    }
}


extension UIImage {
    /// 색상과 크기로 UIImage를 생성 (정사각형)
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init()
        }
    }
    
    /// 원형 마스킹된 이미지 반환
    var circleMasked: UIImage {
        let minEdge = min(size.width, size.height)
        let square = CGRect(x: 0, y: 0, width: minEdge, height: minEdge)
        UIGraphicsBeginImageContextWithOptions(square.size, false, scale)
        UIBezierPath(ovalIn: square).addClip()
        draw(in: square)
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }
}
