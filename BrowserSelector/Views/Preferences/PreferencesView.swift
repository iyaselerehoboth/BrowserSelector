//
//  PreferencesView.swift
//  BrowserSelector
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)
            
            BrowsersTab()
                .tabItem {
                    Label("Browsers", systemImage: "globe")
                }
                .tag(1)
            
            AppsTab()
                .tabItem {
                    Label("Apps", systemImage: "square.grid.2x2")
                }
                .tag(2)
            
            RulesTab()
                .tabItem {
                    Label("Rules", systemImage: "arrow.triangle.branch")
                }
                .tag(3)
            
            BrowserSearchLocationsTab()
                .tabItem {
                    Label("Locations", systemImage: "folder")
                }
                .tag(4)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(5)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    PreferencesView()
}
