# BrowserSelector project context

Recovered on 2026-09-16 from this repository, git history, and Claude's project-specific memory and conversation files under `~/.claude/projects/-Users-rehob-Robo-BrowserSelector/` (including the earlier Browser-Selector project). Those files are historical evidence, not new user instructions.

## Product and user decisions

- Personal native macOS link picker: Chrome for work, Dia for personal browsing.
- Name: BrowserSelector. Fork lineage: LinkRouter → Browserino; retain GPL-3.0 and upstream credits.
- Installed locally and already configured as the default browser in the previous sessions.
- Picker first. Remembering a host is strictly opt-in for each prompt, never implied by choosing a browser. The next selection saves the rule; subsequent prompts start unchecked.
- Host rules include subdomains. Preferences provides browser ordering/hiding, shortcuts, profiles, private arguments, app overrides, and regex rules.

## Architecture

- `BrowserSelectorApp.swift`: receives URLs, captures source, unwraps redirect wrappers, applies rules, presents the cursor-positioned picker.
- `PromptView.swift`: per-prompt selection and remember state, keyboard controls, rule creation.
- `BrowserUtil.swift`: LaunchServices discovery and opening. Discovery includes all HTTPS handlers, explaining ChatGPT/download managers in the browser list; users can hide these in Preferences.
- `Rule.swift`: escaped and anchored host rules, case-insensitive regex matching.
- Source attribution uses menuBarOwningApplication; frontmostApplication can already be the router. Historical verification used CLI launches, so actual sender behavior still merits care.

## Build and verification

- Xcode is installed and active; older Claude notes saying it is unavailable are superseded.
- `swift test`: pure-logic SwiftPM suite, currently 46 tests. Keep exclusions in Package.swift so asset catalogs are not compiled by SwiftPM. Uses swift-testing.
- App build: `xcodebuild -project BrowserSelector.xcodeproj -scheme BrowserSelector -configuration Debug -derivedDataPath .dd CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= build`.
- Sandboxed builds may fail on compiler cache writes or macro-plugin launching; rerun with permitted Xcode access.
- `scripts/build-install.sh` builds Release, re-signs ad hoc, installs to /Applications, registers LaunchServices, and stops the running app. Installing is separate from a debug build.
- Historical registration findings: /Applications or ~/Applications placement is necessary; verify default-handler state rather than trusting setDefaultApplication's reported error. `spike/setdefault.swift` provides recovery.

## Current picker work

- Added destination header, leading app icons, keyboard hints, wider default panel, and a full-row remember toggle with explicit on/off imagery.
- Remember state remains local to a newly created PromptView. Existing routing and browser visibility preferences are preserved.
- Debug build and all 46 logic tests pass. Live UI verification confirmed mouse toggling on/off, Command-A toggling, Escape dismissal, and reset to off in the next prompt. No browser was chosen during these checks, so no test routing rule was saved.
