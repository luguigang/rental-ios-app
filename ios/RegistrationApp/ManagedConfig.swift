//
//  ManagedConfig.swift
//  RentalRegistration
//
//  读取 MDM 下发的 Managed App Configuration。
//  服务端 InstallApplication 命令里的 Configuration 字典会被 iOS 写入
//  standard UserDefaults 的 "com.apple.configuration.managed" 键：
//  {
//      "registration_token": "设备一次性登记令牌",
//      "register_url": "https://…/api/mdm/register/<token>",
//      "serial_number": "设备序列号"
//  }
//

import Foundation

struct ManagedConfig {
    let registrationToken: String?
    let registerUrl: String?
    let serialNumber: String?

    static func current() -> ManagedConfig {
        let dict = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") ?? [:]
        return ManagedConfig(
            registrationToken: dict["registration_token"] as? String,
            registerUrl: dict["register_url"] as? String,
            serialNumber: dict["serial_number"] as? String
        )
    }

    /// MDM 可能先装 APP、后补配置；配置里给出合法的登记页地址才算就绪。
    var isReady: Bool {
        if let url = registerUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           url.lowercased().hasPrefix("https://") || url.lowercased().hasPrefix("http://") {
            return true
        }
        return false
    }
}
