//
//  AboutTab.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct AboutTab: View {
    @State private var didCopyDiagnostics = false

    private static let upstreamURL = URL(
        string: "https://github.com/AlexStrNik/Browserino"
    )!

    // Info.plist keys are read defensively: a missing key should not be able
    // to crash the About tab.
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    private var defaultBrowserIdentifier: String {
        guard let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!),
              let identifier = Bundle(url: url)?.bundleIdentifier else {
            return "none"
        }

        return identifier
    }

    /// Everything needed to tell whether an install actually took. The default
    /// browser identifier is the useful line: LaunchServices ignores a bundle
    /// outside /Applications silently, and this is the only visible symptom.
    private func diagnostics() -> String {
        [
            "BrowserSelector \(version) (\(build))",
            "Bundle: \(Bundle.main.bundleIdentifier ?? "unknown")",
            "Path: \(Bundle.main.bundlePath)",
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Default browser: \(defaultBrowserIdentifier)",
        ].joined(separator: "\n")
    }

    private func copyDiagnostics() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diagnostics(), forType: .string)

        didCopyDiagnostics = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            didCopyDiagnostics = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                .resizable()
                .frame(width: 128, height: 128)

            Spacer()
                .frame(height: 16)

            Text("BrowserSelector")
                .font(.system(size: 28, weight: .semibold))

            Text("Version \(version) (\(build))")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 20)

            Text("Routes every link you click into the right browser.")
                .font(.callout)

            Text("Forked and modified by Iyasele Rehoboth · 2026")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 24)

            HStack(spacing: 12) {
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                }) {
                    Text("Reveal in Finder")
                }

                Button(action: copyDiagnostics) {
                    Text(didCopyDiagnostics ? "Copied" : "Copy Diagnostics")
                }
            }

            Spacer()

            // GPL-3.0 requires this credit to stay.
            Button(action: {
                NSWorkspace.shared.open(Self.upstreamURL)
            }) {
                Text("Based on Browserino by Aleksandr Strizhnev — GPL-3.0")
            }
            .buttonStyle(.link)
            .font(.footnote)
            .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AboutTab()
}
