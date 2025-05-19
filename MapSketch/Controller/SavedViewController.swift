//
//  SavedViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
// SavedViewController.swift
// MapSketch

import UIKit
import NMapsMap

class SavedViewController: UIViewController {
    let naverMapView = NMFNaverMapView()
    var savedBottomSheetVC: SavedBottomSheetViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
    }

    func setupMap() {
        naverMapView.frame = view.bounds
        naverMapView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        view.addSubview(naverMapView)
    }
}
