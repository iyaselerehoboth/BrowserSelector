import Foundation

extension URL {
    /// A link wrapper that hides the real destination behind a query parameter.
    private struct RedirectWrapper {
        let hostSuffix: String
        /// Query parameter holding the real destination.
        let parameter: String
        /// Path the wrapper lives at, when the host also serves ordinary pages.
        /// `nil` means any path on that host is a wrapper.
        let requiredPath: String?
    }

    /// Deliberately an allowlist. Matching any URL that merely *has* a `?url=`
    /// parameter would rewrite ordinary share and preview links, so a host must
    /// be a known redirector before its parameter is trusted.
    ///
    /// Host matching is on suffix because tenants vary: Outlook issues
    /// `nam12.`, `eur03.`, `apc01.` and many more.
    private static let redirectWrappers: [RedirectWrapper] = [
        .init(hostSuffix: "safelinks.protection.outlook.com", parameter: "url", requiredPath: nil),
        .init(hostSuffix: "google.com", parameter: "q", requiredPath: "/url"),
        .init(hostSuffix: "linkedin.com", parameter: "url", requiredPath: "/redir/redirect"),
        .init(hostSuffix: "l.facebook.com", parameter: "u", requiredPath: "/l.php"),
        .init(hostSuffix: "out.reddit.com", parameter: "url", requiredPath: nil),
    ]

    /// Wrappers nest — a SafeLink can wrap a Google redirect. The cap stops a
    /// malicious or looping chain from spinning.
    private static let maxUnwrapDepth = 5

    /// The real destination behind any known redirect wrappers, or `self`.
    ///
    /// Purely offline: it only reads query parameters. Shorteners like `t.co`
    /// and `lnkd.in` cannot be resolved this way — they need a network round
    /// trip, which costs latency and discloses the click, so they are handled
    /// separately and opt-in.
    var unwrapped: URL {
        var current = self
        for _ in 0 ..< Self.maxUnwrapDepth {
            guard let next = current.unwrappingOnce(), next != current else { break }
            current = next
        }
        return current
    }

    private func unwrappingOnce() -> URL? {
        guard let host = host()?.lowercased() else { return nil }

        let wrapper = Self.redirectWrappers.first { candidate in
            let hostMatches = host == candidate.hostSuffix
                || host.hasSuffix("." + candidate.hostSuffix)
            guard hostMatches else { return false }
            guard let required = candidate.requiredPath else { return true }
            return path == required
        }
        guard let wrapper else { return nil }

        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let raw = components.queryItems?.first(where: { $0.name == wrapper.parameter })?.value,
              !raw.isEmpty,
              let target = URL(string: raw),
              let scheme = target.scheme?.lowercased(),
              ["http", "https"].contains(scheme)
        else {
            return nil
        }

        return target
    }
}
