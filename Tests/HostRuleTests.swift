import Testing
import Foundation
@testable import BrowserSelectorCore

/// `Rule.forHost` turns "always use this browser for this host" into a rule
/// the existing routing path already understands. The generated pattern must
/// be anchored: a loose one would match the host appearing anywhere in a URL
/// and silently hijack unrelated links.
@Suite struct HostRule {
    private let chrome = URL(fileURLWithPath: "/Applications/Google Chrome.app")

    private func rule(_ host: String) -> Rule {
        Rule.forHost(host, app: chrome)
    }

    @Test func matchesTheHostItself() {
        #expect(rule("babbangona.atlassian.net")
            .matches("https://babbangona.atlassian.net/browse/BG-1"))
    }

    @Test func matchesBareHostWithNoPath() {
        #expect(rule("example.com").matches("https://example.com"))
    }

    @Test func matchesSubdomains() {
        #expect(rule("atlassian.net").matches("https://babbangona.atlassian.net/x"))
        #expect(rule("zoho.com").matches("https://mail.zoho.com"))
    }

    @Test func matchesHTTPAndHTTPS() {
        #expect(rule("example.com").matches("http://example.com/a"))
        #expect(rule("example.com").matches("https://example.com/a"))
    }

    @Test func isCaseInsensitive() {
        #expect(rule("example.com").matches("https://EXAMPLE.COM/a"))
    }

    // The failures that matter — each of these would be a hijacked link.
    @Test func doesNotMatchSuffixLookalike() {
        #expect(!rule("example.com").matches("https://notexample.com/a"))
    }

    @Test func doesNotMatchHostAsPrefixOfAnother() {
        #expect(!rule("example.com").matches("https://example.com.evil.net/a"))
    }

    @Test func doesNotMatchHostAppearingInPathOrQuery() {
        #expect(!rule("example.com").matches("https://evil.net/?next=example.com"))
        #expect(!rule("example.com").matches("https://evil.net/example.com"))
    }

    @Test func doesNotMatchOtherSchemes() {
        #expect(!rule("example.com").matches("ftp://example.com/a"))
    }

    // Hosts are user data arriving from a clicked URL, so regex metacharacters
    // must not leak into the pattern.
    @Test func escapesRegexMetacharacters() {
        #expect(rule("a-b.example.com").matches("https://a-b.example.com/x"))
        #expect(!rule("a-b.example.com").matches("https://axb.example.com/x"))
    }

    @Test func carriesTheChosenApp() {
        #expect(rule("example.com").app == chrome)
    }
}
