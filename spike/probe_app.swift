import AppKit

let logURL = URL(fileURLWithPath: "/private/tmp/claude-501/-Users-rehob-Robo-Browser-Selector/8dad0c04-9ff3-4e38-87e5-190c4d70d73a/scratchpad/roundtrip.jsonl")
let chromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")

func append(_ line: String) {
    let data = (line + "\n").data(using: .utf8)!
    if let fh = try? FileHandle(forWritingTo: logURL) {
        defer { try? fh.close() }
        _ = try? fh.seekToEnd()
        try? fh.write(contentsOf: data)
    } else {
        try? data.write(to: logURL)
    }
}

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ note: Notification) {
        // 'GURL'/'GURL' — kInternetEventClass / kAEGetURL
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(event:reply:)),
            forEventClass: AEEventClass(0x4755524C),
            andEventID: AEEventID(0x4755524C)
        )
        append("{\"event\":\"launched\",\"ts\":\"\(Date().ISO8601Format())\"}")
    }

    @objc func handleURLEvent(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        // keyDirectObject '----'
        guard let raw = event.paramDescriptor(forKeyword: AEKeyword(0x2D2D2D2D))?.stringValue,
              let url = URL(string: raw) else { return }

        // Source attribution must be read BEFORE anything steals focus.
        let ws = NSWorkspace.shared
        let front = ws.frontmostApplication
        let menubar = ws.menuBarOwningApplication

        let fields: [String: String] = [
            "ts": Date().ISO8601Format(),
            "url": raw,
            "host": url.host() ?? "",
            "frontmost": front?.bundleIdentifier ?? "nil",
            "frontmostName": front?.localizedName ?? "nil",
            "menuBarOwning": menubar?.bundleIdentifier ?? "nil",
        ]
        let json = "{" + fields.sorted { $0.key < $1.key }
            .map { "\"\($0.key)\":\"\($0.value)\"" }.joined(separator: ",") + "}"
        append(json)

        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        ws.open([url], withApplicationAt: chromeURL, configuration: cfg) { _, err in
            append("{\"event\":\"forwarded\",\"ok\":\(err == nil)}")
        }
    }
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
