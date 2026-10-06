# Browser profile selection

## First release

- Read profile names, account labels, and stable directory IDs from Chromium's Local State metadata, checking that each profile directory still exists.
- Support Chrome (including beta/dev/canary), Chromium, Edge, and Brave at their standard macOS data locations.
- Keep each browser's existing default row and shortcut. Add named profile rows with mouse and arrow/Return selection; Shift retains private mode.
- Store an optional profile directory on rules. Existing rules decode as browser-default destinations. Remembering remains opt-in.
- Let users choose profiles in the rule editor and see the directory in the rule list.
- Recheck the profile at launch. If removed or unreadable, open the link using the browser default instead of creating a new empty profile.

## Validation

Test metadata parsing, malformed and missing metadata, missing directories, separate launch arguments, private mode, and old/new rule serialization. Build the complete macOS app. Verify real browser routing with multiple running profiles before distribution.

## Follow-up

Add a separate adapter for Firefox once its macOS profile discovery and supported launch mechanism are verified. Add per-profile hiding, shortcuts, and custom user-data locations if needed.

## Safari adapter

Implemented an opt-in Accessibility adapter using Safari’s File → New [Profile] Window actions. It traverses nested menus, caches names for cold launches, starts Safari when a profile is selected, confirms a newly created focused window, and enters each HTTP(S) URL in that window’s identified address field. This avoids Safari’s external-link website profile overrides.

Preferences provides the enable switch, permission instructions, and launch/refresh button. Missing permission, removed/renamed profiles, unsupported menus, and failed window creation produce an error rather than a wrong-profile fallback. Safari profile selection does not support private windows. Names are the persisted identity for this adapter; Chromium keeps its directory IDs.

Current scope: Safari 17+, English menus. No Safari databases, Full Disk Access, clipboard writes, AppleScript, or changes to Safari website routing preferences.

Validation completed: 53 Swift tests pass and the full Debug app builds. Live menu inspection confirmed the local address-field and File-menu accessibility identifiers. Live profile routing is now verified; see the test record below. Release validation must cover Safari cold/running, nested and top-level profile menus, multiple existing windows, permission denied/revoked, profile rename/removal, multiple URLs, and focus changes during opening.

## Live Safari test — 2026-10-06

With the user’s approval, enabled Safari profile selection, temporarily showed its picker row, and authorized the debug build in Accessibility settings. Safari had Personal and Default profiles available by test time; no additional profile was created by the agent.

Used Debug-only per-profile buttons calling `BrowserUtil.openURL`, the same opening function invoked by picker selections and rules. Routed `https://example.com/?browserselector-live-test=safari` to Default, Personal, then Default while Personal was last active. All three loads succeeded. Safari’s address field showed the exact URL and the toolbar profile identifier matched each requested profile. Distinct window UUIDs confirmed new windows rather than reuse of the other profile’s tab.

Observed windows: Default `41661832-0F77-4E0C-91B7-E8C52D68EF55`, Personal `7AB2CA66-67EA-4AFB-9E0B-8FE58665FED9`, Default `936F8442-9CAC-42CC-B37F-0F9D29E8ED64`.

Restored Safari’s original hidden picker row after testing. Safari profile selection and the authorized Accessibility grant remain enabled. The installed app was not replaced. No website rule was saved. The transient picker panel was not reliably exposed by the UI tool, so this validates live profile discovery and opening, not a complete mouse/keyboard picker test. Debug controls are excluded from Release builds.

## Live Chrome test — 2026-10-06

Verified all three discovered profiles using Debug-only buttons calling the same `BrowserUtil.openURL` path as picker selections and saved rules. Started with Rehoboth active, then routed `https://example.com/?browserselector-live-test=chrome` to Office, babbangona.com, and Rehoboth while the other profiles were open.

All three loaded the exact URL. Chrome’s window titles identified the receiving profiles as `Rehoboth (Office)`, `Tech (babbangona.com)`, and `Rehoboth`. This confirms profile-specific command-line delivery to the already-running Chrome process rather than ordinary most-recent-profile routing.

The babbangona.com profile displayed an unrelated pending extension prompt on startup. Dismissed it without enabling or removing the extension. Closed the three verified test tabs after testing; no Chrome profile settings or saved BrowserSelector rules were changed. The installed BrowserSelector app was not replaced. The final Debug build succeeded. Full picker interaction, private-mode delivery, and multi-URL delivery remain separate release checks.

## Debug test interface cleanup

Replaced the temporary per-profile test buttons with one Test routing… link and a separate sheet. The sheet supports a custom HTTP(S) URL, installed-browser and discovered-profile selection, private mode, refresh, direct opening, and picker opening. Verified the layout in the running app and confirmed invalid/non-web URLs disable both opening actions. Debug build succeeds; the entire test interface is guarded by DEBUG.
