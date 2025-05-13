//
//  WKWebViewBridge.swift
//  MapSketch
//
//  Created by 문주성 on 5/13/25.
//

//역할: Swift ↔ JS 연동
//연관기능: 지도 위 도형 표시

import WebKit

final class WKWebViewBridge: NSObject, WKScriptMessageHandler {
  static let shared = WKWebViewBridge()

  private override init() {}

  func configure(webView: WKWebView) {
    let config = webView.configuration.userContentController
    config.add(self, name: "didDrawShape")
    config.add(self, name: "didTapMarker")
    // 필요 메시지 핸들러 추가
  }

  // JS → Swift
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
      switch message.name {
      case "didDrawShape":
        guard
          let body = message.body as? [String: Any],
          let jsonData = try? JSONSerialization.data(withJSONObject: body),
          let shape = try? JSONDecoder().decode(PlaceShape.self, from: jsonData)
        else { return }
        
        // ─── 임시 땜빵 코드 ───
        // 그룹 선택 로직이 구현되기 전까지,
        // ShapeGroupStore에 있는 첫 번째 그룹 ID를 사용
        if let defaultGroupId = ShapeGroupStore.shared.groups.first?.id {
          ShapeGroupStore.shared.addShape(shape, to: defaultGroupId)
        }
        // ────────────────────

      default:
        break
      }
    }

  // Swift → JS
  func callJS(_ script: String, in webView: WKWebView, completion: ((Any?, Error?) -> Void)? = nil) {
    webView.evaluateJavaScript(script, completionHandler: completion)
  }
}
