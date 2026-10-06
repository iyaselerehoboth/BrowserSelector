# BrowserSelector

A native macOS URL router written in Swift and SwiftUI. It registers as an HTTP(S) handler, applies routing rules, and presents a browser/profile picker when no rule matches.

This README is for contributors and maintainers. User-facing setup and feature information lives in [the landing page](website/index.html). See [website deployment](docs/website-deployment.md) to publish it on GitHub Pages.

## Development requirements

- macOS 13 or later to run the app.
- Full Xcode.app to build the macOS target; Command Line Tools alone cannot compile its asset catalog and SwiftUI previews.
- A Swift toolchain supporting `swift-testing` to run the Foundation-only test target.
- Safari 17+, English menus, and Accessibility authorization for live Safari profile routing tests.

Clone the repository and open `BrowserSelector.xcodeproj`, or build from the command line:

```bash
xcodebuild -project BrowserSelector.xcodeproj -scheme BrowserSelector \
  -configuration Debug -derivedDataPath .dd \
  CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" build
```

The app requires compiled asset symbols and a real Xcode target; standalone `swiftc -typecheck` does not validate it. Signing overrides let you build locally without configuring an Apple developer team.

## Architecture

| Area | Responsibility |
| --- | --- |
| `BrowserSelectorApp.swift` | Receive URLs, capture source context, unwrap supported redirects, apply rules, present the picker. |
| `Models/BrowserUtil.swift` | Discover installed URL handlers and launch browser destinations. |
| `Models/BrowserProfile.swift` | Parse Chromium profile metadata, construct launch arguments, and parse Safari profile menu names. Foundation-only. |
| `Models/SafariProfiles.swift` | Discover and open Safari profile windows through Accessibility. |
| `Models/Rule.swift` | Persist regex routing rules with an optional profile destination; decode older rules without that field. |
| `Views/Prompt/` | Browser/profile selection, keyboard navigation, and opt-in website remembering. |
| `Views/Preferences/` | Browser visibility/order, shortcuts, rules, settings, and debug routing tools. |
| `Tests/` | SwiftPM tests for pure routing and parsing logic. |
| `scripts/` | Local Release installation and universal DMG packaging. |
| `website/` | Standalone user-facing static site; no build dependencies. |

Preferences and rules use local app settings. Profile discovery reads Chromium `Local State` metadata at standard macOS locations and confirms the profile directory exists. Launch arguments pass each value separately. Browser-default rows retain their existing shortcuts.

Safari uses the File menu’s named window actions, confirms a new focused window, then enters the URL in that window’s address field. It caches profile names for later launches. It does not read Safari history/cookies, request Full Disk Access, use AppleScript, or modify Safari website-routing preferences.

## Behavior to preserve

- Remembering is opt-in for each picker prompt. “Always use my choice” starts unchecked; selecting a destination alone never saves a rule.
- A remembered website includes its subdomains. Rules may carry a profile destination, and old rules remain valid.
- Removed or unreadable Chromium profiles fall back to the browser default.
- Missing Safari permissions, renamed/removed profiles, and unconfirmed windows produce an error and leave the link unopened.
- Safari profile identity is its menu name; renamed profiles must be selected again in rules. Chromium uses directory IDs.
- Named Safari profiles do not support private mode. Other browsers use their configured private-mode argument when Shift is held.
- Firefox profiles and custom Chromium user-data locations are outside the current implementation.

## Validation

```bash
swift test
```

The suite currently contains 53 tests and compiles only pure logic. Keep non-source items and AppKit-dependent files in `Package.swift` exclusions so SwiftPM does not invoke asset compilation. If `TestingMacros` fails to resolve, verify the active Xcode toolchain in Xcode → Settings → Locations → Command Line Tools.

For live checks, run a Debug app and open **Preferences → Browsers → Test routing…**. The sheet supports an HTTP(S) URL, a browser/profile destination, private mode, profile refresh, and opening the real picker. These controls are excluded from Release builds. Verify the actual URL and receiving profile in the browser; an opening request alone is not proof of success.

Safari and Chrome live routing was verified on 2026-10-06. The [implementation and validation record](docs/browser-profiles-plan.md) describes coverage and remaining cases, including cold starts, revoked permissions, profile changes, and full picker interaction. Unit tests do not cover macOS Accessibility behavior.

## Build and install locally

```bash
./scripts/build-install.sh
```

This builds Release, signs the app ad hoc with the bundle identifier, replaces `/Applications/BrowserSelector.app`, and registers it with LaunchServices. It stops a running BrowserSelector first. Installing a new signature may require renewing Accessibility authorization.

Open the installed app and use **Preferences → General → Make default**. Confirm default browser registration before testing incoming links. The install script sets `DEVELOPER_DIR` to Xcode without changing the system toolchain setting.

## Package for sharing

```bash
./scripts/package-dmg.sh
```

The script builds both `arm64` and `x86_64`, verifies the app signature and architectures, and creates `dist/BrowserSelector-<version>-universal.dmg` with a SHA-256 file. The DMG includes the app, an Applications shortcut, installation notes, GPL license, and corresponding working source archive. Generated artifacts are ignored by Git.

These packages are ad-hoc signed and **not notarized**. A public distribution should use your own Developer ID signing/notarization setup. The source archive includes working-tree changes, so package from a reviewed tree when producing a release.

Download the universal DMG and checksum from [GitHub Releases](https://github.com/iyaselerehoboth/BrowserSelector/releases). The inherited `release.yml` targets `main` and references the upstream Homebrew tap; it is not configured for this fork’s `master` branch. Do not activate that workflow without replacing its signing/release settings and removing the upstream tap deployment.

## Landing page

The static site uses HTML, CSS, and a small browser-only picker demonstration. Preview it with:

```bash
python3 -m http.server 8000 --directory website
```

Open `http://localhost:8000`. The Pages workflow uploads **only `website/`**, keeping development notes and app source outside the deployed artifact. See [deployment instructions](docs/website-deployment.md) for repository visibility requirements and download configuration.

## Contributing

Keep routing changes small and document their fallback behavior. Add meaningful pure-logic tests when changing parsing, rules, or launch arguments; build the app for SwiftUI/AppKit changes. Browser integration changes also need a live check on the affected browser. Include the tested macOS/browser versions and any remaining limitations in the change description.

Avoid committing local account metadata, browsing history, personal URLs, or generated app/DMG files. Preserve the GPL license and upstream attribution.

## Recovery

If a broken build is left as the default handler, the `spike/` harness can restore Chrome:

```bash
cd spike
swiftc -o setdefault setdefault.swift
./setdefault "/Applications/Google Chrome.app"
```

Verify the handler with `urlForApplication(toOpen:)`; `NSWorkspace.setDefaultApplication` can report an error despite changing the handler.

## License and attribution

GPL-3.0; see [LICENSE](LICENSE).

This is a fork of [LinkRouter](https://github.com/indranandjha1993/LinkRouter) by [Indranand Jha](https://github.com/indranandjha1993), based on [Browserino](https://github.com/AlexStrNik/Browserino) by [Aleksandr Strizhnev](https://github.com/AlexStrNik) and its contributors. Browserino was inspired by [Browserosaurus](https://github.com/will-stone/browserosaurus). Consider [supporting Browserino’s original author](https://alexstrnik.gumroad.com/l/browserino).
