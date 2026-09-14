//
//  Rule.swift
//  LinkRouter
//
//  Created by Aleksandr Strizhnev on 02.12.2024.
//

import Foundation

struct Rule: Hashable, Codable {
    var regex: String
    var app: URL

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
