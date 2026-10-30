//
//  Rule.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 02.12.2024.
//

import Foundation

struct Rule: Hashable, Codable {
    var regex: String
    var app: URL
    var profileDirectory: String? = nil

    /// Whether this rule's pattern matches the URL. Matching is
    /// case-insensitive and unanchored. Empty and invalid patterns never
    /// match — an empty regex would otherwise match every URL and silently
    /// swallow all links.
    func matches(_ urlString: String) -> Bool {
        guard !regex.isEmpty, let compiled = try? Regex(regex).ignoresCase() else {
            return false
        }

        return urlString.firstMatch(of: compiled) != nil
    }
}

extension Rule {
    /// A rule routing `host` and its subdomains to `app`, for the picker's
    /// "always use this browser" option.
    ///
    /// The pattern is anchored at the scheme and terminated at the end of the
    /// host. Both matter: an unanchored pattern would also match the host
    /// appearing in a path or query string, so a link like
    /// `https://somewhere-else.example/?next=mail.zoho.com` would be hijacked
    /// by a rule meant for Zoho.
    ///
    /// The host arrives from a clicked URL, so it is escaped rather than
    /// interpolated — otherwise a host containing regex metacharacters would
    /// build a pattern that matches far more than intended.
    static func forHost(_ host: String, app: URL, profileDirectory: String? = nil, includeSubdomains: Bool = true) -> Rule {
        let escaped = NSRegularExpression.escapedPattern(for: host.lowercased())
        // Terminator allows a port, path, query or fragment, or end of string.
        let prefix = includeSubdomains ? "([^/]*\\.)?" : ""
        return Rule(regex: "^https?://\(prefix)\(escaped)(?:[:/?#]|$)", app: app, profileDirectory: profileDirectory)
    }

    /// Recognize only our exact generated patterns. Custom expressions stay advanced.
    var website: (host: String, includeSubdomains: Bool)? {
        let start = "^https?://"
        let end = "(?:[:/?#]|$)"
        guard regex.hasPrefix(start), regex.hasSuffix(end) else { return nil }
        var body = String(regex.dropFirst(start.count).dropLast(end.count))
        let subdomainPrefix = "([^/]*\\.)?"
        let includes = body.hasPrefix(subdomainPrefix)
        if includes { body.removeFirst(subdomainPrefix.count) }
        let host = body.replacingOccurrences(of: "\\.", with: ".")
        guard Self.normalizedWebsite(host) == host,
              Self.forHost(host, app: app, includeSubdomains: includes).regex == regex else { return nil }
        return (host, includes)
    }

    static func normalizedWebsite(_ input: String) -> String? {
        let host = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !host.isEmpty, host.count <= 253 else { return nil }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.allSatisfy({ label in
            !label.isEmpty && label.count <= 63 && label.first != "-" && label.last != "-" &&
            label.utf8.allSatisfy { (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }
        }) else { return nil }
        return host
    }
}
