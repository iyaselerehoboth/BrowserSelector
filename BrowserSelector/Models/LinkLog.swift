import Foundation

/// Append-only record of routed links, for deciding whether source-app rules
/// are worth building. Deliberately dumb: one JSON object per line, no
/// rotation, no schema. Delete the file to reset.
enum LinkLog {
    static let fileURL: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BrowserSelector", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("links.jsonl")
    }()

    static func record(original: URL, unwrapped: URL, source: SourceApp, routedTo: String) {
        let fields: [String: String] = [
            "ts": ISO8601DateFormatter().string(from: Date()),
            "host": unwrapped.host() ?? "",
            "wasUnwrapped": original == unwrapped ? "false" : "true",
            "source": source.bundleID ?? "unknown",
            "sourceName": source.name ?? "unknown",
            "frontmost": source.frontmostBundleID ?? "unknown",
            "routedTo": routedTo,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: fields),
              var line = String(data: data, encoding: .utf8)
        else { return }
        line += "\n"

        // Best-effort: logging must never interfere with opening the link.
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: Data(line.utf8))
        } else {
            try? Data(line.utf8).write(to: fileURL)
        }
    }
}
