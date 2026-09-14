import AppKit

/// Which application a link came from.
///
/// macOS does not tell a URL handler who sent the URL, so this is inferred.
/// Measured on macOS 26.6.2: `frontmostApplication` returns **this app**, not
/// the sender, and is useless here. `menuBarOwningApplication` returns the
/// real sender. Both are recorded so the assumption stays falsifiable against
/// real traffic rather than the two synthetic cases it was verified on.
struct SourceApp: Equatable {
    let bundleID: String?
    let name: String?
    /// What `frontmostApplication` claimed, kept only to validate the choice above.
    let frontmostBundleID: String?

    /// Must be called before anything activates this app, or the snapshot is
    /// of ourselves.
    static func capture() -> SourceApp {
        let workspace = NSWorkspace.shared
        let source = workspace.menuBarOwningApplication
        return SourceApp(
            bundleID: source?.bundleIdentifier,
            name: source?.localizedName,
            frontmostBundleID: workspace.frontmostApplication?.bundleIdentifier
        )
    }
}
