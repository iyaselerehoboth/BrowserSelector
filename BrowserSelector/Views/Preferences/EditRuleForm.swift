import AppKit
import SwiftUI

struct RuleForm: View {
    var rule: Rule?
    var onCancel: () -> Void
    var onSave: (Rule) -> Void
    var onDelete: () -> Void

    @AppStorage("browsers") private var browsers: [URL] = []
    @State private var advanced = false
    @State private var website = ""
    @State private var includeSubdomains = true
    @State private var regex = ""
    @State private var testURL = ""
    @State private var app: URL?
    @State private var profileDirectory: String?
    @State private var importing = false
    @State private var deleting = false

    private var profiles: [BrowserProfile] {
        guard let id = app.flatMap({ Bundle(url: $0)?.bundleIdentifier }) else { return [] }
        return BrowserUtil.profiles(for: id)
    }
    private var choices: [URL] {
        var result = browsers.filter { Bundle(url: $0) != nil }
        if let app, !result.contains(app) { result.append(app) }
        return result
    }
    private var draft: Rule? {
        guard let app else { return nil }
        if advanced {
            guard !regex.isEmpty, (try? Regex(regex)) != nil else { return nil }
            return Rule(regex: regex, app: app, profileDirectory: profileDirectory)
        }
        guard let host = Rule.normalizedWebsite(website) else { return nil }
        return Rule.forHost(host, app: app, profileDirectory: profileDirectory, includeSubdomains: includeSubdomains)
    }
    private var appName: String {
        app.flatMap { Bundle(url: $0)?.appDisplayName } ?? app?.deletingPathExtension().lastPathComponent ?? "Choose a browser"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(rule == nil ? "New website rule" : (rule?.website?.host ?? "Advanced rule"))
                            .font(.title2.bold())
                        Text("Open this website automatically.").foregroundStyle(.secondary)
                    }
                    Picker("Rule type", selection: $advanced) {
                        Text("Website").tag(false)
                        Text("Advanced regex").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: advanced) { value in
                        if value, let host = Rule.normalizedWebsite(website) {
                            regex = Rule.forHost(host, app: app ?? URL(fileURLWithPath: "/"), includeSubdomains: includeSubdomains).regex
                        }
                    }
                    if advanced {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Regular expression").fontWeight(.medium)
                            TextField("URL pattern", text: $regex).font(.system(.body, design: .monospaced))
                            Text("Matches the full URL, ignoring case.").font(.caption).foregroundStyle(.secondary)
                            if !regex.isEmpty && (try? Regex(regex)) == nil {
                                Text("Enter a valid regular expression.").font(.caption).foregroundStyle(.red)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website").fontWeight(.medium)
                            TextField("example.com", text: $website)
                            Toggle("Include subdomains", isOn: $includeSubdomains)
                            Text(includeSubdomains ? "Also matches subdomains of this website." : "Matches only this exact domain.")
                                .font(.caption).foregroundStyle(.secondary)
                            if !website.isEmpty && Rule.normalizedWebsite(website) == nil {
                                Text("Enter a domain such as example.com, without https:// or a path.")
                                    .font(.caption).foregroundStyle(.red)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open with").fontWeight(.medium)
                        Picker("Browser", selection: Binding(get: { app }, set: { app = $0; profileDirectory = nil })) {
                            Text("Choose a browser").tag(nil as URL?)
                            ForEach(choices, id: \.self) { url in
                                Text(Bundle(url: url)?.appDisplayName ?? url.deletingPathExtension().lastPathComponent).tag(Optional(url))
                            }
                        }.labelsHidden()
                        Button("Choose another application…") { importing = true }.font(.caption)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile").fontWeight(.medium)
                        Picker("Profile", selection: $profileDirectory) {
                            Text("Browser default").tag(nil as String?)
                            ForEach(profiles) { Text($0.label).tag(Optional($0.directory)) }
                            if let directory = profileDirectory, !profiles.contains(where: { $0.directory == directory }) {
                                Text("\(directory) (unavailable)").tag(Optional(directory))
                            }
                        }.labelsHidden()
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try a link").fontWeight(.medium)
                        TextField("https://example.com/page", text: $testURL)
                        if !testURL.isEmpty {
                            let validURL = URL(string: testURL).map { ["http", "https"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil } ?? false
                            let matches = validURL && (draft?.matches(testURL) ?? false)
                            Label(validURL ? (matches ? "Matches this rule" : "Does not match this rule") : "Enter a complete HTTP or HTTPS URL", systemImage: matches ? "checkmark.circle.fill" : "info.circle")
                                .foregroundStyle(matches ? Color.green : Color.secondary)
                            if matches {
                                Text("Opens in \(appName)\(profileDirectory.map { directory in ", \(profiles.first { $0.directory == directory }?.name ?? directory) profile" } ?? "")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Text("Preview only. This does not open the link.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .padding(24)
            }
            Divider()
            HStack {
                if rule != nil {
                    Button("Delete rule", role: .destructive) { deleting = true }
                }
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Save changes") { if let draft { onSave(draft) } }
                    .buttonStyle(.borderedProminent).disabled(draft == nil)
            }.padding(20)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.application]) { result in
            if case .success(let url) = result { app = url; profileDirectory = nil }
        }
        .confirmationDialog("Delete this rule?", isPresented: $deleting) {
            Button("Delete rule", role: .destructive, action: onDelete)
        } message: { Text("Links for this website will use the remaining rules or show the browser picker.") }
        .onAppear {
            advanced = rule != nil && rule?.website == nil
            website = rule?.website?.host ?? ""
            includeSubdomains = rule?.website?.includeSubdomains ?? true
            regex = rule?.regex ?? ""
            app = rule?.app
            profileDirectory = rule?.profileDirectory
            testURL = rule?.website.map { "https://\($0.host)/" } ?? ""
        }
    }
}
