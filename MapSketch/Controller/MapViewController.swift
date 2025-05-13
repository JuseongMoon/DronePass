//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
import UIKit
import WebKit
import NMapsMap


class MapViewController: UIViewController {
//    @IBOutlet weak var mapView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = NMFMapView(frame: view.frame)
        view.addSubview(mapView)

    }
}

// (선택) 로딩 완료 후 추가 제어가 필요할 때 사용
extension MapViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("네이버 지도 로딩 완료")
    }
}
