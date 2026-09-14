import Testing
import Foundation
@testable import BrowserSelectorCore

/// Wrapped links are the reason host-based rules silently fail on work mail:
/// every Outlook link arrives as `*.safelinks.protection.outlook.com`, so a
/// rule on the real host never matches.
@Suite struct URLUnwrapping {

    private func safeLink(_ target: String, tenant: String = "nam12") -> URL {
        let enc = target.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        return URL(string: "https://\(tenant).safelinks.protection.outlook.com/?url=\(enc)&data=05%7C01%7C&sdata=x&reserved=0")!
    }

    @Test func unwrapsOutlookSafeLinks() {
        let target = "https://babbangona.atlassian.net/browse/BG-1"
        #expect(safeLink(target).unwrapped.absoluteString == target)
    }

    @Test func unwrapsSafeLinksOnAnyTenantSubdomain() {
        let target = "https://example.com/a"
        #expect(safeLink(target, tenant: "eur03").unwrapped.absoluteString == target)
    }

    @Test func unwrapsGoogleRedirect() {
        let enc = "https://example.com/x".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let u = URL(string: "https://www.google.com/url?q=\(enc)&sa=D")!
        #expect(u.unwrapped.absoluteString == "https://example.com/x")
    }

    @Test func unwrapsLinkedInRedirect() {
        let enc = "https://example.com/y".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let u = URL(string: "https://www.linkedin.com/redir/redirect?url=\(enc)")!
        #expect(u.unwrapped.absoluteString == "https://example.com/y")
    }

    @Test func unwrapsNestedWrappers() {
        let inner = "https://example.com/deep"
        let gEnc = inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let google = "https://www.google.com/url?q=\(gEnc)"
        #expect(safeLink(google).unwrapped.absoluteString == inner)
    }

    // Guard against false positives: plenty of legitimate pages take a ?url=
    // parameter without being redirectors.
    @Test func leavesOrdinaryURLWithURLParamAlone() {
        let u = URL(string: "https://example.com/share?url=https%3A%2F%2Fother.com")!
        #expect(u.unwrapped == u)
    }

    @Test func leavesPlainURLAlone() {
        let u = URL(string: "https://github.com/foo/bar")!
        #expect(u.unwrapped == u)
    }

    // Same class of hole as the deep-link handler: a wrapper could carry a
    // file:// or javascript: payload that a rule would then open unprompted.
    @Test func refusesNonWebInnerScheme() {
        #expect(safeLink("file:///etc/passwd").unwrapped.scheme == "https")
        #expect(safeLink("javascript:alert(1)").unwrapped.scheme == "https")
    }

    @Test func survivesMissingOrEmptyParameter() {
        let a = URL(string: "https://nam12.safelinks.protection.outlook.com/?data=x")!
        let b = URL(string: "https://nam12.safelinks.protection.outlook.com/?url=")!
        #expect(a.unwrapped == a)
        #expect(b.unwrapped == b)
    }

    @Test func terminatesOnSelfReferentialWrapper() {
        // A wrapper pointing at itself must not spin forever.
        let s = "https://nam12.safelinks.protection.outlook.com/?url="
        let enc = s.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let u = URL(string: s + enc)!
        _ = u.unwrapped  // must return
        #expect(Bool(true))
    }
}
