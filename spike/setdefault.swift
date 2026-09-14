import AppKit

// usage: setdefault <path-to-.app>   — sets it as handler for http+https
let args = CommandLine.arguments
guard args.count == 2 else { print("usage: setdefault <app>"); exit(2) }
let appURL = URL(fileURLWithPath: args[1])
let ws = NSWorkspace.shared
let group = DispatchGroup()
var failures: [String] = []

for scheme in ["http", "https"] {
    group.enter()
    ws.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { err in
        if let err { failures.append("\(scheme): \(err.localizedDescription)") }
        group.leave()
    }
}
_ = group.wait(timeout: .now() + 20)
if failures.isEmpty {
    print("OK -> \(appURL.lastPathComponent)")
} else {
    print("FAILED: \(failures.joined(separator: "; "))")
    exit(1)
}
