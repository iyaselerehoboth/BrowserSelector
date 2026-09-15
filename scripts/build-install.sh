#!/bin/bash
# Build BrowserSelector and install it to /Applications.
#
# Notes that are not obvious and cost time to rediscover:
#  - DEVELOPER_DIR points at Xcode without `sudo xcode-select -s`, so this
#    needs no admin password even when the active toolchain is Command Line
#    Tools.
#  - The project inherits upstream's DEVELOPMENT_TEAM and "Don't Code Sign".
#    Both are overridden here: an ad-hoc signature is what a locally run app
#    needs, and no Apple Developer Program membership is involved.
#  - xcodebuild leaves a *linker-signed* binary whose signing identifier is
#    "BrowserSelector" rather than the bundle id. Re-signing fixes that.
#  - The bundle must end up in /Applications or ~/Applications. LaunchServices
#    silently ignores a bundle anywhere else — it never appears in the default
#    browser list, with no error.
set -euo pipefail

XCODE="${XCODE:-/Applications/Xcode.app}"
BUNDLE_ID="com.rehob.BrowserSelector"
DEST="${DEST:-/Applications}"
WORK="$(mktemp -d)"
DD="$WORK/dd"
LOG="$WORK/build.log"

export DEVELOPER_DIR="$XCODE/Contents/Developer"

echo "==> building (Release, ad-hoc signed)"
xcodebuild -project BrowserSelector.xcodeproj \
           -scheme BrowserSelector \
           -configuration Release \
           -derivedDataPath "$DD" \
           CODE_SIGN_IDENTITY="-" \
           CODE_SIGN_STYLE=Manual \
           DEVELOPMENT_TEAM="" \
           build > "$LOG" 2>&1 \
  || { echo "BUILD FAILED — tail of log:"; tail -40 "$LOG"; exit 1; }

APP="$DD/Build/Products/Release/BrowserSelector.app"

echo "==> re-signing ad-hoc with the correct identifier"
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"

echo "==> installing to $DEST"
pkill -x BrowserSelector 2>/dev/null || true
rm -rf "$DEST/BrowserSelector.app"
cp -R "$APP" "$DEST/"

LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -f "$DEST/BrowserSelector.app"

echo
echo "installed: $DEST/BrowserSelector.app"
codesign -dv "$DEST/BrowserSelector.app" 2>&1 | grep -E 'Identifier=|Signature='
echo
echo "Next: open it once, then System Settings -> Desktop & Dock -> Default web browser."
echo "To back out: cd spike && swiftc -o setdefault setdefault.swift && ./setdefault '/Applications/Google Chrome.app'"
