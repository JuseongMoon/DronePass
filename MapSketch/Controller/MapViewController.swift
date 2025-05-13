//
//  MapViewController.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//
import UIKit
import WebKit


class MapViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) WKWebView Delegate 설정 (필요 시)
        webView.navigationDelegate = self

        // 2) 번들에 포함된 map.html 경로
        guard let url = Bundle.main.url(forResource: "map", withExtension: "html") else {
            print("⚠️ map.html 파일을 찾을 수 없습니다.")
            return
        }

        // 3) 로컬 파일 로드
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

// (선택) 로딩 완료 후 추가 제어가 필요할 때 사용
extension MapViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("네이버 지도 로딩 완료")
    }
}
