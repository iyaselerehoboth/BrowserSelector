// swift-testing, not XCTest: XCTest ships inside Xcode.app and is absent from
// Command Line Tools, so XCTest-based tests cannot run without a full Xcode.
import Testing
import Foundation
@testable import BrowserSelectorCore

@Suite struct HostMatching {
    @Test func emptyConfiguredHostMatchesEverything() {
        #expect(URL(string: "https://anything.example")!.matchesHost(""))
    }

    @Test func exactHostMatches() {
        #expect(URL(string: "https://github.com/foo")!.matchesHost("github.com"))
    }

    @Test func subdomainMatches() {
        #expect(URL(string: "https://gist.github.com")!.matchesHost("github.com"))
    }

    @Test func suffixLookalikeDoesNotMatch() {
        #expect(!URL(string: "https://notgithub.com")!.matchesHost("github.com"))
    }

    @Test func matchingIsCaseInsensitive() {
        #expect(URL(string: "https://GitHub.com")!.matchesHost("github.com"))
        #expect(URL(string: "https://github.com")!.matchesHost("GitHub.com"))
    }

    @Test func urlWithoutHostDoesNotMatchConfiguredHost() {
        #expect(!URL(string: "about:blank")!.matchesHost("github.com"))
    }
}

@Suite struct RuleMatching {
    private func rule(_ regex: String) -> Rule {
        Rule(regex: regex, app: URL(fileURLWithPath: "/Applications/Safari.app"))
    }

    @Test func emptyPatternNeverMatches() {
        #expect(!rule("").matches("https://example.com"))
    }

    @Test func invalidPatternNeverMatches() {
        #expect(!rule("[").matches("https://example.com"))
    }

    @Test func substringMatch() {
        #expect(rule("github").matches("https://github.com/foo"))
    }

    @Test func matchingIsCaseInsensitive() {
        #expect(rule("GITHUB").matches("https://github.com"))
    }

    @Test func nonMatchingPattern() {
        #expect(!rule("gitlab").matches("https://github.com"))
    }

    @Test func anchoredPattern() {
        #expect(rule("^https://mail\\.").matches("https://mail.example.com"))
        #expect(!rule("^https://mail\\.").matches("https://example.com/mail."))
    }
}

@Suite struct DeepLink {
    private func deepLink(encoding target: String) -> URL {
        let encoded = Data(target.utf8).base64EncodedString()
        return URL(string: "browserselector://open?url=\(encoded)")!
    }

    @Test func decodesHTTPSTarget() {
        #expect(deepLink(encoding: "https://example.com/path?q=1").browserSelectorDeepLinkTarget
                == URL(string: "https://example.com/path?q=1"))
    }

    @Test func decodesHTTPTarget() {
        #expect(deepLink(encoding: "http://example.com").browserSelectorDeepLinkTarget
                == URL(string: "http://example.com"))
    }

    @Test func schemeComparisonIsCaseInsensitive() {
        #expect(deepLink(encoding: "HTTPS://EXAMPLE.COM").browserSelectorDeepLinkTarget != nil)
    }

    @Test func rejectsFileTarget() {
        #expect(deepLink(encoding: "file:///etc/passwd").browserSelectorDeepLinkTarget == nil)
    }

    @Test func rejectsJavaScriptTarget() {
        #expect(deepLink(encoding: "javascript:alert(1)").browserSelectorDeepLinkTarget == nil)
    }

    @Test func rejectsSchemeRelativeTarget() {
        #expect(deepLink(encoding: "//example.com").browserSelectorDeepLinkTarget == nil)
    }

    @Test func rejectsInvalidBase64() {
        #expect(URL(string: "browserselector://open?url=%%%")!.browserSelectorDeepLinkTarget == nil)
    }

    @Test func rejectsMissingQuery() {
        #expect(URL(string: "browserselector://open")!.browserSelectorDeepLinkTarget == nil)
    }

    @Test func ignoresOtherSchemesAndHosts() {
        let encoded = Data("https://example.com".utf8).base64EncodedString()
        #expect(URL(string: "https://open?url=\(encoded)")!.browserSelectorDeepLinkTarget == nil)
        #expect(URL(string: "browserselector://other?url=\(encoded)")!.browserSelectorDeepLinkTarget == nil)
    }
}

@Suite struct StorageCoding {
    @Test func urlArrayRoundTrip() {
        let urls = [
            URL(string: "file:///Applications/Safari.app/")!,
            URL(string: "file:///Applications/Google%20Chrome.app/")!,
        ]
        #expect([URL](rawValue: urls.rawValue) == urls)
    }

    @Test func ruleArrayRoundTrip() {
        let rules = [Rule(regex: "^https://mail\\.", app: URL(fileURLWithPath: "/Applications/Safari.app"))]
        #expect([Rule](rawValue: rules.rawValue) == rules)
    }

    @Test func dictionaryRoundTrip() {
        let shortcuts = ["com.apple.Safari": "S", "com.google.Chrome": "C"]
        #expect([String: String](rawValue: shortcuts.rawValue) == shortcuts)
    }

    @Test func malformedRawValueDecodesToNil() {
        #expect([URL](rawValue: "not json") == nil)
        #expect([String: String](rawValue: "{broken") == nil)
    }
}
