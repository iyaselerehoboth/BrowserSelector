import AppKit
import ApplicationServices

/// Safari has no profile launch argument. Use its own New Profile Window menu
/// and navigate in the window we just created, bypassing external-link rules.
enum SafariProfiles {
    static var enabled: Bool { UserDefaults.standard.bool(forKey: "safariProfilesEnabled") }
    static var hasPermission: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
    }

    private static func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else { return nil }
        return value
    }

    private static func children(_ element: AXUIElement) -> [AXUIElement] {
        attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? []
    }

    private static func descendants(_ element: AXUIElement, depth: Int = 0) -> [AXUIElement] {
        guard depth < 6 else { return [] }
        return children(element).flatMap { [$0] + descendants($0, depth: depth + 1) }
    }

    private static var runningSafari: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first
    }

    private static func profileItems(_ application: AXUIElement) -> [(BrowserProfile, AXUIElement)] {
        guard let value = attribute(application, kAXMenuBarAttribute), CFGetTypeID(value) == AXUIElementGetTypeID() else { return [] }
        let menu = unsafeBitCast(value, to: AXUIElement.self)
        guard let fileMenu = descendants(menu).first(where: {
            attribute($0, kAXIdentifierAttribute) as? String == "SafariFileMenu"
        }) else { return [] }
        return descendants(fileMenu).compactMap { element in
            guard attribute(element, kAXRoleAttribute) as? String == kAXMenuItemRole,
                  let title = attribute(element, kAXTitleAttribute) as? String,
                  let profile = SafariProfileMenu.profile(title: title) else { return nil }
            return (profile, element)
        }
    }

    static func discover() -> [BrowserProfile] {
        guard enabled else { return [] }
        let cached = UserDefaults.standard.stringArray(forKey: "safariProfileNames") ?? []
        guard hasPermission, let safari = runningSafari else {
            return cached.map(SafariProfileMenu.profile(name:))
        }
        let application = AXUIElementCreateApplication(safari.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.3)
        let profiles = profileItems(application).map { $0.0 }
        // An inaccessible menu should not erase saved destinations.
        if !profiles.isEmpty {
            UserDefaults.standard.set(profiles.map(\.name), forKey: "safariProfileNames")
            return profiles
        }
        return cached.map(SafariProfileMenu.profile(name:))
    }

    static func showError(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Couldn’t open the Safari profile"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func open(_ urls: [URL], app: URL, profile: String, isIncognito: Bool) {
        guard !isIncognito else {
            showError("Safari private windows do not belong to a named profile. Choose the ordinary Safari row to open with your configured private argument.")
            return
        }
        guard enabled, hasPermission else {
            showError("Enable Safari profiles in Preferences → Browsers and allow BrowserSelector in System Settings → Privacy & Security → Accessibility, then try the link again.")
            return
        }
        guard urls.allSatisfy({ ["https", "http"].contains($0.scheme?.lowercased() ?? "") }) else {
            showError("Safari profile selection supports HTTP and HTTPS links.")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: app, configuration: configuration) { safari, error in
            DispatchQueue.main.async {
                guard error == nil, let safari else {
                    showError("Safari could not be started. The link was not opened.")
                    return
                }
                Task { @MainActor in
                    for url in urls {
                        guard await openInNewWindow(url, safari: safari, profile: profile) else { return }
                    }
                }
            }
        }
    }

    @MainActor
    private static func openInNewWindow(_ url: URL, safari: NSRunningApplication, profile: String) async -> Bool {
        let application = AXUIElementCreateApplication(safari.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.3)
        var target: AXUIElement?
        for _ in 0..<20 {
            target = profileItems(application).first { $0.0.directory == profile }?.1
            if target != nil { break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard let target else {
            showError("The selected profile is unavailable. Open Safari and check its File menu. This version supports English Safari menu titles; renamed profiles must be selected again.")
            return false
        }
        let oldWindows = attribute(application, kAXWindowsAttribute) as? [AXUIElement] ?? []
        guard AXUIElementPerformAction(target, kAXPressAction as CFString) == .success else {
            showError("Safari’s profile window could not be opened. The link was not opened.")
            return false
        }
        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard let value = attribute(application, kAXFocusedWindowAttribute), CFGetTypeID(value) == AXUIElementGetTypeID() else { continue }
            let window = unsafeBitCast(value, to: AXUIElement.self)
            guard !oldWindows.contains(where: { CFEqual($0, window) }),
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == safari.processIdentifier else { continue }
            // Focus the address field in this confirmed new window. No clipboard
            // or AppleScript Automation permission is needed.
            guard sendKey(37, command: true, to: safari.processIdentifier) else { break } // Command-L
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == safari.processIdentifier,
                  let current = attribute(application, kAXFocusedWindowAttribute), CFEqual(current, window),
                  let focused = attribute(application, kAXFocusedUIElementAttribute), CFGetTypeID(focused) == AXUIElementGetTypeID() else { break }
            let field = unsafeBitCast(focused, to: AXUIElement.self)
            guard attribute(field, kAXRoleAttribute) as? String == kAXTextFieldRole,
                  attribute(field, kAXIdentifierAttribute) as? String == "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD",
                  AXUIElementSetAttributeValue(field, kAXValueAttribute as CFString, url.absoluteString as CFString) == .success,
                  sendKey(36, command: false, to: safari.processIdentifier) else { break } // Return
            return true
        }
        showError("Safari did not make the new profile window ready. The link was not opened; try again from the picker.")
        return false
    }

    private static func sendKey(_ code: CGKeyCode, command: Bool, to pid: pid_t) -> Bool {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
              let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else { return false }
        if command { down.flags = .maskCommand; up.flags = .maskCommand }
        down.postToPid(pid)
        up.postToPid(pid)
        return true
    }
}
