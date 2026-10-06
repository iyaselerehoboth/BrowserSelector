import Foundation
import Testing
@testable import BrowserSelectorCore

struct BrowserProfileTests {
    @Test func parsesNamesAndAccounts() {
        let data = Data(#"{"profile":{"info_cache":{"Default":{"name":"Personal"},"Profile 1":{"name":"Work","user_name":"work@example.com"},"../bad":{"name":"Invalid"},"Guest Profile":{"is_omitted":true},"Profile 2":{"is_ephemeral":true}}}}"#.utf8)
        let profiles = BrowserProfiles.parse(data)
        #expect(profiles.map(\.directory) == ["Default", "Profile 1"])
        #expect(profiles[1].label == "Work · work@example.com")
        #expect(BrowserProfiles.parse(Data("invalid".utf8)).isEmpty)
        #expect(BrowserProfiles.parse(Data("{}".utf8)).isEmpty)
    }

    @Test func argumentsPreserveSpacesAndPrivateMode() {
        let url = URL(string: "https://example.com/?a=1&b=2")!
        #expect(BrowserProfiles.launchArguments(profile: "Profile 1", privateArgument: "--incognito", urls: [url]) == ["--profile-directory=Profile 1", "--incognito", url.absoluteString])
        #expect(BrowserProfiles.launchArguments(profile: "../bad", privateArgument: nil, urls: [url]) == [url.absoluteString])
    }

    @Test func existingRulesDecodeWithoutProfile() throws {
        let old = Data(#"{"regex":"example","app":"file:///Applications/Google%20Chrome.app"}"#.utf8)
        let rule = try JSONDecoder().decode(Rule.self, from: old)
        #expect(rule.profileDirectory == nil)
        let profiled = Rule.forHost("example.com", app: rule.app, profileDirectory: "Profile 1")
        #expect(try JSONDecoder().decode(Rule.self, from: JSONEncoder().encode(profiled)) == profiled)
    }

    @Test func discoveryExcludesMissingDirectories() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let root = BrowserProfiles.dataDirectory(for: "com.google.Chrome", home: home)!
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Default"), withIntermediateDirectories: true)
        try Data(#"{"profile":{"info_cache":{"Default":{"name":"Personal"},"Profile 1":{"name":"Missing"}}}}"#.utf8).write(to: root.appendingPathComponent("Local State"))
        #expect(BrowserProfiles.discover(bundleID: "com.google.Chrome", home: home).map(\.directory) == ["Default"])
        #expect(BrowserProfiles.discover(bundleID: "com.apple.Safari", home: home).isEmpty)
    }
}

struct SafariProfileMenuTests {
    @Test func parsesOnlyNamedProfileWindows() {
        #expect(SafariProfileMenu.profile(title: "New Work Window")?.name == "Work")
        #expect(SafariProfileMenu.profile(title: "New Personal Window")?.directory == "safari-menu:Personal")
        #expect(SafariProfileMenu.profile(title: "New Window") == nil)
        #expect(SafariProfileMenu.profile(title: "New Private Window") == nil)
        #expect(SafariProfileMenu.profile(title: "New Tab") == nil)
        #expect(SafariProfileMenu.profile(title: "Move Tab to New Window") == nil)
    }

    @Test func retainsFullProfileName() {
        #expect(SafariProfileMenu.profile(title: "New My Work / Research Window")?.name == "My Work / Research")
        #expect(SafariProfileMenu.profile(title: "New Window Window")?.name == "Window")
    }

    @Test func safariRuleRoundTrip() throws {
        let rule = Rule.forHost("example.com", app: URL(fileURLWithPath: "/Applications/Safari.app"), profileDirectory: "safari-menu:Work")
        #expect(try JSONDecoder().decode(Rule.self, from: JSONEncoder().encode(rule)) == rule)
    }
}
