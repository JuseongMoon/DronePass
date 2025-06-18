////
////  SavedViewController.swift
////  DronePass
////
////  Created by 문주성 on 5/13/25.
////
//
//// 역할: 저장된 도형을 지도에 표시하는 뷰 컨트롤러
//// 연관기능: 지도, 바텀시트, 도형 목록
//
//import UIKit // UIKit 프레임워크를 가져옵니다. (UI 구성 및 이벤트 처리)
//import NMapsMap // 네이버 지도 SDK를 가져옵니다. (지도 표시 기능)
//
//class SavedViewController: UIViewController { // 저장된 도형을 지도에 표시하는 뷰 컨트롤러입니다.
//    let naverMapView = NMFNaverMapView() // 네이버 지도 뷰 객체입니다.
//    var savedBottomSheetVC: SavedBottomSheetViewController! // 저장 바텀시트 뷰 컨트롤러입니다.
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupMap() // 지도 뷰 설정
//    }
//
//    func setupMap() { // 지도 뷰의 프레임 및 오토리사이징 설정
//        naverMapView.frame = view.bounds
//        naverMapView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
//        view.addSubview(naverMapView)
//    }
//}
