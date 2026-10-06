//
//  BrowsersTab.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("privateArgs") private var privateArgs: [String: String] = [:]
    @AppStorage("safariProfilesEnabled") private var safariProfilesEnabled = false
    @State private var safariHasPermission = SafariProfiles.hasPermission
    @State private var safariProfileCount = 0

    #if DEBUG
    @State private var routingTestPresented = false
    #endif

    private func refreshSafari() {
        safariHasPermission = SafariProfiles.hasPermission
        safariProfileCount = SafariProfiles.discover().count
    }

    private func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    private func privateArg(for key: String) -> Binding<String> {
        return .init(
            get: { self.privateArgs[key, default: ""] },
            set: { self.privateArgs[key] = $0 })
    }

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, browser in
                    if let bundle = Bundle(url: browser) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(
                                    .system(size: 16)
                                )
                                .frame(width: 30, alignment: .leading)

                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)

                            Spacer()
                                .frame(width: 8)

                            Text(bundle.appDisplayName)
                                .font(
                                    .system(size: 14)
                                )

                            Spacer()
                                .frame(width: 32)

                            TextField(
                                "Private argument",
                                text: privateArg(for: bundle.bundleIdentifier!)
                            )
                            .font(
                                .system(size: 14).monospaced()
                            )

                            Spacer()
                                .frame(width: 32)

                            ShortcutButton(
                                browserId: bundle.bundleIdentifier!
                            )

                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                if let idx = hiddenBrowsers.firstIndex(of: browser) {
                                    hiddenBrowsers.remove(at: idx)
                                } else {
                                    hiddenBrowsers.append(browser)
                                }
                            }) {
                                Image(
                                    systemName: hiddenBrowsers.contains(browser)
                                        ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .onAppear {
                if browsers.isEmpty {
                    browsers = BrowserUtil.loadBrowsers(
                        oldBrowsers: browsers
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Enable Safari profile selection", isOn: $safariProfilesEnabled)
                    .onChange(of: safariProfilesEnabled) { enabled in
                        if enabled { SafariProfiles.requestPermission() }
                        refreshSafari()
                    }
                if safariProfilesEnabled {
                    Text(safariHasPermission
                         ? "Open Safari to refresh profiles. \(safariProfileCount) profiles available."
                         : "Allow BrowserSelector in System Settings → Privacy & Security → Accessibility, then return here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Safari 17 or later, with English menus. Each link opens a new profile window. Renamed profiles need to be selected again in saved rules.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Open Safari and refresh") {
                            guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") else { return }
                            NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { refreshSafari() }
                            }
                        }
                        if !safariHasPermission {
                            Button("Accessibility Settings") {
                                SafariProfiles.requestPermission()
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .onAppear(perform: refreshSafari)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                refreshSafari()
            }

            #if DEBUG
            HStack {
                Spacer()
                Button("Test routing…") { routingTestPresented = true }
                    .font(.caption)
                    .buttonStyle(.link)
            }
            .padding(.horizontal, 10)
            .sheet(isPresented: $routingTestPresented) {
                RoutingTestSheet(browsers: browsers)
            }
            #endif

            Text(
                "Drag and drop to reorder. Press record to assign a shortcut. Click on eye to hide unwanted browsers from prompt. Profiles for Chrome, Chromium, Edge, and Brave appear automatically in the picker."
            )
            .font(.subheadline)
            .foregroundStyle(.primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    PreferencesView()
}

#if DEBUG
/// Developer tools stay in a single sheet rather than adding per-profile
/// controls to the browser settings. Uses the production routing paths.
private struct RoutingTestSheet: View {
    let browsers: [URL]
    @Environment(\.dismiss) private var dismiss
    @State private var browser: URL?
    @State private var profileDirectory: String?
    @State private var profiles: [BrowserProfile] = []
    @State private var urlText = "https://example.com/?browserselector-live-test=routing"
    @State private var privateMode = false
    @State private var status: String?

    private var installedBrowsers: [URL] {
        browsers.filter { Bundle(url: $0) != nil }
    }

    private var testURL: URL? {
        guard let url = URL(string: urlText),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    private func refreshProfiles() {
        profiles = browser.flatMap { Bundle(url: $0)?.bundleIdentifier }
            .map { BrowserUtil.profiles(for: $0) } ?? []
        if !profiles.contains(where: { $0.directory == profileDirectory }) {
            profileDirectory = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test routing").font(.title2.bold())
            Text("Open a test link, then check the browser’s address bar and profile. Test controls are available only in Debug builds.")
                .foregroundStyle(.secondary)
            Form {
                TextField("Test URL:", text: $urlText)
                Picker("Browser:", selection: $browser) {
                    Text("Choose a browser").tag(nil as URL?)
                    ForEach(installedBrowsers, id: \.self) { app in
                        Text(Bundle(url: app)?.appDisplayName ?? app.lastPathComponent)
                            .tag(Optional(app))
                    }
                }
                Picker("Profile:", selection: $profileDirectory) {
                    Text("Browser default").tag(nil as String?)
                    ForEach(profiles) { profile in
                        Text(profile.label).tag(Optional(profile.directory))
                    }
                }
                Toggle("Private mode", isOn: $privateMode)
            }
            if testURL == nil {
                Text("Enter a valid HTTP or HTTPS URL.")
                    .font(.caption).foregroundStyle(.red)
            }
            if browser?.lastPathComponent == "Safari.app" && profiles.isEmpty {
                Text("For Safari profiles, enable profile selection, grant Accessibility access, and open Safari before refreshing.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let status {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Refresh profiles", action: refreshProfiles)
                    .disabled(browser == nil)
                Button("Open picker") {
                    guard let url = testURL, let delegate = NSApp.delegate as? AppDelegate else { return }
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        delegate.application(NSApp, open: [url])
                    }
                }
                .disabled(testURL == nil)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Open test link") {
                    guard let url = testURL, let browser else { return }
                    status = "Open requested. Verify the URL and selected profile in the browser."
                    BrowserUtil.openURL([url], app: browser, isIncognito: privateMode,
                                        profileDirectory: profileDirectory)
                }
                .disabled(testURL == nil || browser == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560)
        .onAppear {
            browser = installedBrowsers.first
            refreshProfiles()
        }
        .onChange(of: browser) { _ in
            profileDirectory = nil
            status = nil
            refreshProfiles()
        }
    }
}
#endif
