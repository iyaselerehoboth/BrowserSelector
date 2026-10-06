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
    static func forHost(_ host: String, app: URL, profileDirectory: String? = nil) -> Rule {
        let escaped = NSRegularExpression.escapedPattern(for: host.lowercased())
        // Terminator allows a port, path, query or fragment, or end of string.
        return Rule(regex: "^https?://([^/]*\\.)?\(escaped)(?:[:/?#]|$)", app: app, profileDirectory: profileDirectory)
    }
}
