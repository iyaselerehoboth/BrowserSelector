//
//  PromptItem.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct PromptItem: View {
    var browser: URL
    var urls: [URL]
    var bundle: Bundle
    var shortcut: String?
    var profileLabel: String? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(
                    nsImage: NSWorkspace.shared.icon(
                        forFile: bundle.bundlePath
                    )
                )
                .resizable()
                .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(bundle.appDisplayName)
                        .font(.system(size: 13, weight: .medium))
                    if let profileLabel {
                        Text(profileLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(profileLabel)
                    }
                }
                
                Spacer()
                
                if let shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .frame(minWidth: 4)
                        .opacity(0.5)
                        .padding(5)
                        .background(
                            Color.secondary.opacity(0.2)
                        )
                        .cornerRadius(4)
                }

            }
            .padding(8)
        }
        .if(shortcut?.lowercased().first != nil) {
            let key = KeyEquivalent(shortcut!.lowercased().first!)
            return $0.keyboardShortcut(key, modifiers: [.shift])
                .background {
                    Button(action: action) {}
                        .opacity(0)
                        .keyboardShortcut(key, modifiers: [])
                }
        }
    }
}
