//
//  URLExtensions.swift
//  LinkRouter
//
//  Created by Claude Code on 05.01.2026.
//

import Foundation

extension Bundle {
    /// Human-readable app name that never crashes: not every app declares
    /// CFBundleName (some only set CFBundleDisplayName, or neither).
    var appDisplayName: String {
        (infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (infoDictionary?["CFBundleName"] as? String)
            ?? bundleURL.deletingPathExtension().lastPathComponent
    }
}

extension URL {
    /// Decodes a linkrouter://open?url=<base64> deep link. Only web URLs are
    /// accepted: any page can link to this scheme, so allowing file://,
    /// javascript:, etc. would let a crafted link open arbitrary content —
    /// without a prompt when a routing rule matches.
    var linkRouterDeepLinkTarget: URL? {
        guard scheme == "linkrouter", host == "open",
              let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let encoded = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let data = Data(base64Encoded: encoded),
              let string = String(data: data, encoding: .utf8),
              let target = URL(string: string),
              let targetScheme = target.scheme?.lowercased(),
              ["http", "https"].contains(targetScheme)
        else {
            return nil
        }

        return target
    }

    func matchesHost(_ configuredHost: String) -> Bool {
        if configuredHost.isEmpty {
            return true
        }

        guard let urlHost = self.host()?.lowercased() else { return false }
        let appHost = configuredHost.lowercased()
        return urlHost == appHost || urlHost.hasSuffix("." + appHost)
    }
}
