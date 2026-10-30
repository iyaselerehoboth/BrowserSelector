import AppKit
import SwiftUI

struct RulesTab: View {
    @AppStorage("rules") private var rules: [Rule] = []
    @State private var selection: Int?
    @State private var adding = false

    private func destination(_ rule: Rule) -> String {
        let name = Bundle(url: rule.app)?.appDisplayName ?? rule.app.deletingPathExtension().lastPathComponent + " (missing)"
        guard let directory = rule.profileDirectory else { return name }
        let profile = Bundle(url: rule.app)?.bundleIdentifier.flatMap {
            BrowserUtil.profiles(for: $0).first { $0.directory == directory }?.name
        } ?? directory
        return "\(name) · \(profile)"
    }

    private var editing: Bool {
        adding || selection.map { rules.indices.contains($0) } == true
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 780
            HStack(spacing: 0) {
                if !compact || !editing {
                    sidebar
                        .frame(width: compact ? geometry.size.width : min(330, geometry.size.width * 0.4))
                }
                if !compact { Divider() }
                if !compact || editing {
                    VStack(alignment: .leading, spacing: 0) {
                        if compact {
                            Button {
                                selection = nil
                                adding = false
                            } label: {
                                Label("All rules", systemImage: "chevron.left")
                            }
                            .padding([.top, .horizontal], 16)
                        }
                        editor
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onChange(of: selection) { _ in if selection != nil { adding = false } }
    }

    private var sidebar: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Website rules").font(.title2.bold())
                    Spacer()
                    Button { adding = true; selection = nil } label: {
                        Label("Add rule", systemImage: "plus")
                    }
                }
                Text("Choose where each website opens.")
                    .foregroundStyle(.secondary)
                List(selection: $selection) {
                    ForEach(rules.indices, id: \.self) { index in
                        let rule = rules[index]
                        HStack(spacing: 10) {
                            Image(systemName: rule.website == nil ? "curlybraces" : "globe")
                                .font(.title2).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rule.website?.host ?? rule.regex)
                                    .fontWeight(.medium).lineLimit(1).truncationMode(.middle)
                                Text(destination(rule)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                Text(rule.website.map { $0.includeSubdomains ? "Includes subdomains" : "Exact domain only" } ?? "Advanced regex")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(nsImage: NSWorkspace.shared.icon(forFile: rule.app.path))
                                .resizable().frame(width: 24, height: 24)
                        }
                        .padding(.vertical, 8)
                        .tag(index)
                    }
                }
                .listStyle(.sidebar)
                Text("\(rules.count) rules").font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editor: some View {
            Group {
                if adding {
                    RuleForm(rule: nil, onCancel: { adding = false }, onSave: {
                        rules.append($0)
                        adding = false
                        selection = rules.count - 1
                    }, onDelete: {})
                    .id("new")
                } else if let index = selection, rules.indices.contains(index) {
                    RuleForm(rule: rules[index], onCancel: { selection = nil }, onSave: {
                        rules[index] = $0
                    }, onDelete: {
                        rules.remove(at: index)
                        selection = nil
                    })
                    .id(index)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.branch").font(.largeTitle).foregroundStyle(.secondary)
                        Text(rules.isEmpty ? "Add your first website rule" : "Select a website rule").font(.title3)
                        Text("Matching links open automatically in the browser and profile you choose.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 300)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
    }
}
