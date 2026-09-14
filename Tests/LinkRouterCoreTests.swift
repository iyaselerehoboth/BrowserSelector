import XCTest
@testable import LinkRouterCore

final class HostMatchingTests: XCTestCase {
    func testEmptyConfiguredHostMatchesEverything() {
        XCTAssertTrue(URL(string: "https://anything.example")!.matchesHost(""))
    }

    func testExactHostMatches() {
        XCTAssertTrue(URL(string: "https://github.com/foo")!.matchesHost("github.com"))
    }

    func testSubdomainMatches() {
        XCTAssertTrue(URL(string: "https://gist.github.com")!.matchesHost("github.com"))
    }

    func testSuffixLookalikeDoesNotMatch() {
        XCTAssertFalse(URL(string: "https://notgithub.com")!.matchesHost("github.com"))
    }

    func testMatchingIsCaseInsensitive() {
        XCTAssertTrue(URL(string: "https://GitHub.com")!.matchesHost("github.com"))
        XCTAssertTrue(URL(string: "https://github.com")!.matchesHost("GitHub.com"))
    }

    func testURLWithoutHostDoesNotMatchConfiguredHost() {
        XCTAssertFalse(URL(string: "about:blank")!.matchesHost("github.com"))
    }
}

final class RuleMatchingTests: XCTestCase {
    private func rule(_ regex: String) -> Rule {
        Rule(regex: regex, app: URL(fileURLWithPath: "/Applications/Safari.app"))
    }

    func testEmptyPatternNeverMatches() {
        XCTAssertFalse(rule("").matches("https://example.com"))
    }

    func testInvalidPatternNeverMatches() {
        XCTAssertFalse(rule("[").matches("https://example.com"))
    }

    func testSubstringMatch() {
        XCTAssertTrue(rule("github").matches("https://github.com/foo"))
    }

    func testMatchingIsCaseInsensitive() {
        XCTAssertTrue(rule("GITHUB").matches("https://github.com"))
    }

    func testNonMatchingPattern() {
        XCTAssertFalse(rule("gitlab").matches("https://github.com"))
    }

    func testAnchoredPattern() {
        XCTAssertTrue(rule("^https://mail\\.").matches("https://mail.example.com"))
        XCTAssertFalse(rule("^https://mail\\.").matches("https://example.com/mail."))
    }
}

final class DeepLinkTests: XCTestCase {
    private func deepLink(encoding target: String) -> URL {
        let encoded = Data(target.utf8).base64EncodedString()
        return URL(string: "linkrouter://open?url=\(encoded)")!
    }

    func testDecodesHTTPSTarget() {
        XCTAssertEqual(
            deepLink(encoding: "https://example.com/path?q=1").linkRouterDeepLinkTarget,
            URL(string: "https://example.com/path?q=1")
        )
    }

    func testDecodesHTTPTarget() {
        XCTAssertEqual(
            deepLink(encoding: "http://example.com").linkRouterDeepLinkTarget,
            URL(string: "http://example.com")
        )
    }

    func testSchemeComparisonIsCaseInsensitive() {
        XCTAssertNotNil(deepLink(encoding: "HTTPS://EXAMPLE.COM").linkRouterDeepLinkTarget)
    }

    func testRejectsFileTarget() {
        XCTAssertNil(deepLink(encoding: "file:///etc/passwd").linkRouterDeepLinkTarget)
    }

    func testRejectsJavaScriptTarget() {
        XCTAssertNil(deepLink(encoding: "javascript:alert(1)").linkRouterDeepLinkTarget)
    }

    func testRejectsSchemeRelativeTarget() {
        XCTAssertNil(deepLink(encoding: "//example.com").linkRouterDeepLinkTarget)
    }

    func testRejectsInvalidBase64() {
        XCTAssertNil(URL(string: "linkrouter://open?url=%%%")!.linkRouterDeepLinkTarget)
    }

    func testRejectsMissingQuery() {
        XCTAssertNil(URL(string: "linkrouter://open")!.linkRouterDeepLinkTarget)
    }

    func testIgnoresOtherSchemesAndHosts() {
        let encoded = Data("https://example.com".utf8).base64EncodedString()
        XCTAssertNil(URL(string: "https://open?url=\(encoded)")!.linkRouterDeepLinkTarget)
        XCTAssertNil(URL(string: "linkrouter://other?url=\(encoded)")!.linkRouterDeepLinkTarget)
    }
}

final class StorageCodingTests: XCTestCase {
    func testURLArrayRoundTrip() {
        let urls = [
            URL(string: "file:///Applications/Safari.app/")!,
            URL(string: "file:///Applications/Google%20Chrome.app/")!,
        ]
        XCTAssertEqual([URL](rawValue: urls.rawValue), urls)
    }

    func testRuleArrayRoundTrip() {
        let rules = [Rule(regex: "^https://mail\\.", app: URL(fileURLWithPath: "/Applications/Safari.app"))]
        XCTAssertEqual([Rule](rawValue: rules.rawValue), rules)
    }

    func testDictionaryRoundTrip() {
        let shortcuts = ["com.apple.Safari": "S", "com.google.Chrome": "C"]
        XCTAssertEqual([String: String](rawValue: shortcuts.rawValue), shortcuts)
    }

    func testMalformedRawValueDecodesToNil() {
        XCTAssertNil([URL](rawValue: "not json"))
        XCTAssertNil([String: String](rawValue: "{broken"))
    }
}
