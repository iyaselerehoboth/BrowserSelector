# Phase 0 spike — verified on macOS 26.6.2, 2026-09-14

Proves a locally built, ad-hoc-signed, non-notarized app can become the
system default browser and route links.

- `setdefault.swift` — sets http+https handler. **Your escape hatch.**
  `swiftc -o setdefault setdefault.swift && ./setdefault "/Applications/Google Chrome.app"`
- `probe_app.swift` — minimal router: receives the URL, logs source
  attribution, forwards to Chrome.
- `roundtrip.jsonl` — captured output from the verified run.

## Findings

1. App must live in `/Applications` or `~/Applications`. `/tmp` is ignored
   by LaunchServices.
2. `setDefaultApplication` reports `https: The file couldn't be opened.`
   on EVERY call, but the change applies anyway. Verify with
   `urlForApplication(toOpen:)`, never trust the error.
3. `frontmostApplication` returns the ROUTER ITSELF, not the sender.
   `menuBarOwningApplication` correctly identifies the source app.
