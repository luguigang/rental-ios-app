//
//  RegistrationWebView.swift
//  RentalRegistration
//
//  全屏 WKWebView，加载服务端注入的设备客户登记页（现有 H5）。
//  店员在页面里提交客户姓名/手机号后，服务端负责退出单应用锁定，
//  本 APP 不需要任何额外交互。
//

import SwiftUI
import WebKit

struct RegistrationWebView: UIViewRepresentable {
    let url: URL
    /// 变化时强制整页重新加载（例如 MDM 补发配置后）。
    let reloadToken: UUID

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .systemBackground
        webView.isOpaque = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            uiView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(lastReloadToken: reloadToken)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastReloadToken: UUID

        init(lastReloadToken: UUID) {
            self.lastReloadToken = lastReloadToken
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation?,
                     withError error: Error) {
            NotificationCenter.default.post(
                name: .registrationLoadFailed,
                object: error.localizedDescription
            )
        }
    }
}

extension Notification.Name {
    /// 登记页加载失败（例如设备刚连上 WiFi 还没出网）。
    static let registrationLoadFailed = Notification.Name("registrationLoadFailed")
}
