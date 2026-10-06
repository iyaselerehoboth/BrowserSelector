![BrowserSelector](images/browserselector.png?v2)

**BrowserSelector** routes every link you click into the right browser. Set it
as the macOS default browser and a picker appears at the cursor; choose with
the mouse, arrow keys, or a per-browser shortcut, or let a rule route it
silently.

Built to keep work in Chrome and everything else in Dia on the same machine.

## Features

- Native SwiftUI — instant popup, tiny footprint, no Electron
- Per-browser keyboard shortcuts
- Regex rules that route matching URLs with no prompt
- Browser profile support
- **Unwraps redirect wrappers** before matching — Outlook SafeLinks, Google
  `/url`, LinkedIn, Facebook, Reddit. Without this, every rule written against
  a real host silently fails on work mail, because the link arrives as
  `*.safelinks.protection.outlook.com`
- **Records the sending app** for each link, so source-based rules ("anything
  from Slack → Chrome") can be designed against real data
- macOS 13+, Apple Silicon and Intel

## In action

| The picker | Preferences |
|:---:|:---:|
| <img src="images/screenshot-prompt.png" width="380" alt="The picker — choose a browser for the clicked link"> | <img src="images/screenshot-preferences.png" width="500" alt="Preferences — General tab"> |

## Build and install

```bash
./scripts/build-install.sh
```

Builds Release, signs ad-hoc, installs to `/Applications`, and registers with
LaunchServices. Then open it once and pick it under **System Settings →
Desktop & Dock → Default web browser**.

Building needs **Xcode.app**; Command Line Tools alone is not enough. The
script sets `DEVELOPER_DIR` itself, so it works without
`sudo xcode-select -s` and needs no admin password. No Apple Developer Program
membership and no notarization are required for a build you run yourself.

Three things the script handles that are easy to get wrong:

- The project inherits upstream's `DEVELOPMENT_TEAM` and `"Don't Code Sign"`;
  both are overridden to an ad-hoc signature.
- `xcodebuild` emits a *linker-signed* binary whose signing identifier is
  `BrowserSelector` rather than the bundle id, so it is re-signed.
- The bundle must land in `/Applications` or `~/Applications`. **LaunchServices
  silently ignores a bundle anywhere else** — it never appears as a browser
  option, with no error of any kind.

## Development

```bash
swift test          # 35 tests, no Xcode required
```

The SwiftPM package compiles only the pure logic (rules, host matching, URL
unwrapping) so the suite runs on Command Line Tools alone. Tests use
**swift-testing**, not XCTest — XCTest ships inside Xcode.app.

Two traps worth knowing:

- Every non-source entry under the target path must stay listed in
  `Package.swift`'s `exclude:`, or SwiftPM tries to run `actool` on the asset
  catalog. Xcode supplies `actool`, so this only bites on a machine with just
  Command Line Tools — the exclusions are kept so the package stays buildable
  there.
- `swift test` used to fail intermittently with
  `plugin for module 'TestingMacros' not found` (~1 run in 3). That was
  Command Line Tools failing to resolve the macro plugin; it stops once Xcode
  is the active toolchain (`xcode-select -p` should print
  `/Applications/Xcode.app/Contents/Developer`, settable via Xcode → Settings
  → Locations → Command Line Tools).

To check the **app** target, build it — 9s cold, under a second warm:

```bash
xcodebuild -project BrowserSelector.xcodeproj -scheme BrowserSelector \
  -configuration Debug -derivedDataPath .dd \
  CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" build
```

Standalone `swiftc -typecheck` does not work on the app target, for two
reasons that are not worth fighting: `#Preview` blocks parse as stray
top-level expressions outside a real target build, and asset-catalog symbols
like `NSImage.menuIcon` only exist once the catalog is compiled.

### Recovery

`spike/` holds the harness used to verify default-browser registration. If a
broken build is left as the system default and links stop opening:

```bash
cd spike && swiftc -o setdefault setdefault.swift && ./setdefault "/Applications/Google Chrome.app"
```

Note that `NSWorkspace.setDefaultApplication` reports
`https: The file couldn't be opened.` even when it succeeds — verify with
`urlForApplication(toOpen:)` rather than trusting the error.

## Credits

A personal fork of [**LinkRouter**](https://github.com/indranandjha1993/LinkRouter)
by [Indranand Jha](https://github.com/indranandjha1993), which is itself a fork
of [**Browserino**](https://github.com/AlexStrNik/Browserino) by
[Aleksandr Strizhnev](https://github.com/AlexStrNik) — full credit for the
original design and implementation belongs to him and the Browserino
contributors. If you find this useful, consider
[supporting the original author](https://alexstrnik.gumroad.com/l/browserino).

Browserino was in turn inspired by
[Browserosaurus](https://github.com/will-stone/browserosaurus).

Licensed GPL-3.0, as required by its upstreams.

### Browser profiles

The picker automatically lists named profiles for Chrome, Chromium, Microsoft Edge, and Brave at their standard macOS data locations, including supported preview channels. Choose a profile by clicking its row or using arrow keys and Return. Hold Shift to use the browser’s configured private-mode argument. The original browser row and shortcut continue to use the browser default.

“Always use my choice” remembers the selected profile for the website and its subdomains. You can also choose a profile when adding or editing a rule in Preferences. Profiles are refreshed whenever the picker opens; removed or unreadable Chromium profiles fall back to the browser default. Firefox and custom user-data locations currently use ordinary browser selection.

#### Safari profiles

Safari profile selection is opt-in in **Preferences → Browsers → Enable Safari profile selection**. Allow BrowserSelector in **System Settings → Privacy & Security → Accessibility**, open Safari, then use **Open Safari and refresh**. Create profiles first in Safari Settings → Profiles if none are listed.

This adapter requires Safari 17 or later and English Safari menus. It reads the named profile window actions from Safari’s File menu, including nested submenus, and caches profile names so saved destinations remain available when Safari is closed. Each selected link opens a new window for that profile and navigates directly in its address field. It uses neither Full Disk Access nor AppleScript Automation, and does not read Safari history or cookies or change Safari website-routing settings.

Safari exposes names through these menu actions, so renamed profiles must be selected again in saved rules. If permission is missing, the profile is unavailable, or the new window cannot be confirmed, BrowserSelector shows an error and leaves the link unopened. Named profile rows do not support private mode; the ordinary Safari row retains its existing behavior.

Validation: the app builds and all 53 logic tests pass. Live routing on 2026-10-06 succeeded for Default → Personal → Default, with the URL and profile confirmed from Safari’s accessibility state. Debug-only buttons exercise the same profile-opening function used by the picker. Cold starts, denied/revoked permission, nested menus, and full picker interaction still need release validation.

Live Chrome validation on 2026-10-06 also passed for all three local profiles (Office, babbangona.com, and Rehoboth), with the receiving profile and exact URL verified in Chrome. Debug-only test controls use the same opening function as the picker.

Debug builds expose a single **Test routing…** link in Browsers preferences. Its sheet provides a URL field, browser/profile selectors, private mode, profile refresh, and actions for direct routing or the picker. Release builds exclude the entire test interface.
