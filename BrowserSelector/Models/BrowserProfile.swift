import Foundation

/// Only metadata is read; browser cookies and account credentials are never accessed.
struct BrowserProfile: Hashable, Identifiable {
    var directory: String
    var name: String
    var email: String?
    var id: String { directory }
    var label: String {
        if let email, !email.isEmpty { return "\(name) · \(email)" }
        return name
    }
}

enum BrowserProfiles {
    static func dataDirectory(for bundleID: String, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL? {
        let paths = [
            "com.google.Chrome": "Google/Chrome",
            "com.google.Chrome.beta": "Google/Chrome Beta",
            "com.google.Chrome.dev": "Google/Chrome Dev",
            "com.google.Chrome.canary": "Google/Chrome Canary",
            "org.chromium.Chromium": "Chromium",
            "com.microsoft.edgemac": "Microsoft Edge",
            "com.microsoft.edgemac.Beta": "Microsoft Edge Beta",
            "com.microsoft.edgemac.Dev": "Microsoft Edge Dev",
            "com.microsoft.edgemac.Canary": "Microsoft Edge Canary",
            "com.brave.Browser": "BraveSoftware/Brave-Browser",
            "com.brave.Browser.beta": "BraveSoftware/Brave-Browser-Beta",
            "com.brave.Browser.nightly": "BraveSoftware/Brave-Browser-Nightly"
        ]
        guard let path = paths[bundleID] else { return nil }
        return home.appendingPathComponent("Library/Application Support").appendingPathComponent(path)
    }

    static func isValidDirectory(_ directory: String) -> Bool {
        !directory.isEmpty && directory != "." && directory != ".."
            && !directory.contains("/") && !directory.contains("\\")
            && !directory.contains("\0")
    }

    static func parse(_ data: Data) -> [BrowserProfile] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any],
              let cache = profile["info_cache"] as? [String: Any] else { return [] }
        return cache.compactMap { directory, value in
            guard isValidDirectory(directory), let metadata = value as? [String: Any],
                  metadata["is_omitted"] as? Bool != true,
                  metadata["is_ephemeral"] as? Bool != true else { return nil }
            let name = metadata["name"] as? String
            return BrowserProfile(directory: directory,
                                  name: name.flatMap { $0.isEmpty ? nil : $0 } ?? directory,
                                  email: metadata["user_name"] as? String)
        }.sorted {
            if $0.name != $1.name { return $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return $0.directory < $1.directory
        }
    }

    static func discover(bundleID: String, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [BrowserProfile] {
        guard let root = dataDirectory(for: bundleID, home: home),
              let data = try? Data(contentsOf: root.appendingPathComponent("Local State")) else { return [] }
        return parse(data).filter {
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: root.appendingPathComponent($0.directory).path,
                                                   isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }

    /// Arguments remain separate strings, including profile names containing spaces.
    static func launchArguments(profile: String?, privateArgument: String?, urls: [URL]) -> [String] {
        var arguments: [String] = []
        if let profile, isValidDirectory(profile) { arguments.append("--profile-directory=\(profile)") }
        if let privateArgument, !privateArgument.isEmpty { arguments.append(privateArgument) }
        return arguments + urls.map(\.absoluteString)
    }
}

/// Names are the only identity Safari exposes in its profile window menu.
/// Keep these distinct from Chromium's directory arguments.
enum SafariProfileMenu {
    static func profile(name: String) -> BrowserProfile {
        BrowserProfile(directory: "safari-menu:" + name, name: name, email: nil)
    }

    static func profile(title: String) -> BrowserProfile? {
        let prefix = "New "
        let suffix = " Window"
        guard title.hasPrefix(prefix), title.hasSuffix(suffix) else { return nil }
        let name = String(title.dropFirst(prefix.count).dropLast(suffix.count))
        guard !name.isEmpty, name != "Private" else { return nil }
        return profile(name: name)
    }
}
