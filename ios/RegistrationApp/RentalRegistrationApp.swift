//
//  RentalRegistrationApp.swift
//  RentalRegistration
//
//  租赁系统「设备客户登记」壳APP。
//
//  这个 APP 只做一件事：全屏打开 MDM 注入的客户登记页（现有 H5）。
//  设备在激活向导阶段被服务端用自治单应用模式（ASAM）锁进本 APP，
//  店员必须提交客户姓名/手机号；提交成功（或未匹配放行）后服务端
//  退出单应用锁定，店员按 Home 键即可回到主屏幕。
//

import SwiftUI
import UIKit

@main
struct RentalRegistrationApp: App {
    var body: some Scene {
        WindowGroup {
            RegistrationContainerView()
                // 全屏覆盖，不响应状态栏/安全区，配合单应用锁定观感一致。
                .ignoresSafeArea()
        }
    }
}

struct RegistrationContainerView: View {
    @State private var config = ManagedConfig.current()
    @State private var reloadToken = UUID()
    @State private var loadError: String?

    /// MDM 可能先装 APP、后补配置（ABM 自动安装时常见），定时重读配置。
    private let configTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    /// App Store 审核（自定 APP）要求审核员能独立运行 APP：
    /// 设备没有 MDM 注入配置时，加载内置的本地演示登记页（不依赖网络/服务端）。
    private static let demoPageURL: URL? = Bundle.main
        .url(forResource: "RegistrationDemo", withExtension: "html")

    var body: some View {
        Group {
            if config.isReady, let urlString = config.registerUrl, let url = URL(string: urlString) {
                RegistrationWebView(url: url, reloadToken: reloadToken)
                    .ignoresSafeArea()
            } else if let demoURL = Self.demoPageURL {
                // 审核/无 MDM 环境兜底：加载本地演示页展示完整登记交互。
                // 真实设备稍后配置到位时，refreshConfigIfNeeded 会切回正式登记页。
                RegistrationWebView(url: demoURL, reloadToken: reloadToken)
                    .ignoresSafeArea()
            } else {
                waitingView
            }
        }
        .onReceive(configTimer) { _ in
            refreshConfigIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshConfigIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .registrationLoadFailed)) { note in
            loadError = note.object as? String
        }
    }

    private func refreshConfigIfNeeded() {
        let latest = ManagedConfig.current()
        if latest.registerUrl != config.registerUrl
            || latest.registrationToken != config.registrationToken {
            config = latest
            reloadToken = UUID()
            loadError = nil
        }
    }

    /// 配置尚未下发时的占位界面：设备被锁进 APP 但登记页地址还没到。
    private var waitingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("正在初始化设备配置…")
                .font(.headline)
            if let serial = config.serialNumber, !serial.isEmpty {
                Text("序列号：\(serial)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let error = loadError, !error.isEmpty {
                Text("页面加载失败：\(error)\n请确认设备已连接网络，稍后会自动重试。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
