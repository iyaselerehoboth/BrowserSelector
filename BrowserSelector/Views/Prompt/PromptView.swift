//
//  PromptView.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]

    @AppStorage("copy_closeAfterCopy") private var closeAfterCopy: Bool = false
    @AppStorage("copy_alternativeShortcut") private var alternativeShortcut: Bool = false
    @AppStorage("apps_atTop") private var appsAtTop: Bool = true
    @AppStorage("rules") private var rules: [Rule] = []

    let urls: [URL]

    @State private var opacityAnimation = 0.0
    @State private var selected = 0

    /// Opt-in only, and deliberately not persisted. Choosing a browser must
    /// never imply "and remember this" — a fresh PromptView is constructed for
    /// every prompt, so this starts off each time the picker appears.
    @State private var alwaysForHost = false
    @FocusState private var focused: Bool

    var appsForUrls: [App] {
        urls.flatMap { url in
            return apps.filter { app in
                url.matchesHost(app.host)
            }
        }
        .filter {
            // Skip stale entries for uninstalled apps: their rows are not
            // rendered, so they would desync keyboard selection indexes.
            !browsers.contains($0.app) && Bundle(url: $0.app) != nil
        }
    }

    var visibleBrowsers: [URL] {
        browsers.filter { !hiddenBrowsers.contains($0) && Bundle(url: $0) != nil }
    }

    private enum PromptEntry {
        case app(App)
        case browser(URL)
    }

    private var orderedEntries: [PromptEntry] {
        let appEntries = appsForUrls.map(PromptEntry.app)
        let browserEntries = visibleBrowsers.map(PromptEntry.browser)
        return appsAtTop ? appEntries + browserEntries : browserEntries + appEntries
    }

    private func openSelected(isIncognito: Bool) {
        guard orderedEntries.indices.contains(selected) else {
            return
        }

        switch orderedEntries[selected] {
        case .app(let app):
            openUrlsInApp(app: app)
        case .browser(let browser):
            openBrowser(browser, isIncognito: isIncognito)
        }
    }

    private var promptHost: String? {
        urls.first?.host()
    }

    /// Persists a host rule, but only because the user ticked the box.
    private func rememberIfRequested(_ target: URL) {
        guard alwaysForHost, let host = promptHost else { return }

        let rule = Rule.forHost(host, app: target)
        guard !rules.contains(where: { $0.regex == rule.regex }) else { return }

        rules.append(rule)
    }

    private func openBrowser(_ browser: URL, isIncognito: Bool) {
        rememberIfRequested(browser)
        BrowserUtil.openURL(urls, app: browser, isIncognito: isIncognito)
    }

    func openUrlsInApp(app: App) {
        rememberIfRequested(app.app)

        let urls =
            if app.schemeOverride.isEmpty {
                urls
            } else {
                urls.map {
                    let url = NSURLComponents.init(
                        url: $0,
                        resolvingAgainstBaseURL: true
                    )
                    url!.scheme = app.schemeOverride

                    return url!.url!
                }
            }

        BrowserUtil.openURL(
            urls,
            app: app.app,
            isIncognito: false
        )
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !appsForUrls.isEmpty && appsAtTop {
                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                if let bundle = Bundle(url: app.app) {
                                    PromptItem(
                                        browser: app.app,
                                        urls: urls,
                                        bundle: bundle,
                                        shortcut: bundle.bundleIdentifier.flatMap { shortcuts[$0] }
                                    ) {
                                        openUrlsInApp(app: app)
                                    }
                                    .id(index)
                                    .buttonStyle(
                                        SelectButtonStyle(
                                            selected: selected == index
                                        )
                                    )
                                }
                            }
                            
                            Divider()
                        }
                        
                        ForEach(Array(visibleBrowsers.enumerated()), id: \.offset) {
                            index, browser in
                            if let bundle = Bundle(url: browser) {
                                PromptItem(
                                    browser: browser,
                                    urls: urls,
                                    bundle: bundle,
                                    shortcut: bundle.bundleIdentifier.flatMap { shortcuts[$0] }
                                ) {
                                    openBrowser(
                                        browser,
                                        isIncognito: NSEvent.modifierFlags.contains(.shift)
                                    )
                                }
                                .id(index + (appsAtTop ? appsForUrls.count : 0))
                                .buttonStyle(
                                    SelectButtonStyle(
                                        selected: selected == index + (appsAtTop ? appsForUrls.count : 0)
                                    )
                                )
                            }
                        }

                        if !appsForUrls.isEmpty && !appsAtTop {
                            Divider()

                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                if let bundle = Bundle(url: app.app) {
                                    PromptItem(
                                        browser: app.app,
                                        urls: urls,
                                        bundle: bundle,
                                        shortcut: bundle.bundleIdentifier.flatMap { shortcuts[$0] }
                                    ) {
                                        openUrlsInApp(app: app)
                                    }
                                    .id(visibleBrowsers.count + index)
                                    .buttonStyle(
                                        SelectButtonStyle(
                                            selected: selected == visibleBrowsers.count + index
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
                .focusable()
                .focusEffectDisabledCompat()
                .focused($focused)
                .onMoveCommand { command in
                    if command == .up {
                        selected = max(0, selected - 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                    } else if command == .down {
                        selected = min(max(orderedEntries.count - 1, 0), selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                    }
                }
                .background {
                    Button(action: {
                        openSelected(isIncognito: false)
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.defaultAction)

                    Button(action: {
                        openSelected(isIncognito: true)
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.return, modifiers: [.shift])

                    Button(action: {
                        NSApplication.shared.keyWindow?.close()
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.cancelAction)

                    Button(action: {
                        alwaysForHost.toggle()
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(KeyEquivalent("a"), modifiers: [.command])
                }
                .onAppear {
                    focused.toggle()
                    withAnimation(.interactiveSpring(duration: 0.3)) {
                        opacityAnimation = 1
                    }
                }
                .scrollEdgeEffectDisabledCompat()
            }

            Divider()

            if let host = urls.first?.host() {
                HStack(spacing: 8) {
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(urls.first?.absoluteString ?? "", forType: .string)

                        if closeAfterCopy {
                            NSApplication.shared.keyWindow?.close()
                        }
                    }) {
                        Text(
                            host
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(
                        KeyEquivalent("c"),
                        modifiers: alternativeShortcut ? [.command] : [.command, .option]
                    )
                    .toolTip(urls.first?.absoluteString ?? "")

                    Spacer(minLength: 8)

                    Toggle(isOn: $alwaysForHost) {
                        Text("Always")
                    }
                    .toggleStyle(.checkbox)
                    .toolTip("Always open \(host) in the browser you pick next, skipping this prompt (⌘A)")
                }
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(BlurredView())
        .opacity(opacityAnimation)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    PromptView(urls: [])
}
