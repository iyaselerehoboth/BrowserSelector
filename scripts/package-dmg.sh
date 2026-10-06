#!/bin/bash
# Build a universal local-sharing DMG, including corresponding GPL source.
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_ROOT="$PWD"
PACKAGE_WORK="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_WORK"' EXIT
OUTPUT="$PROJECT_ROOT/dist"
mkdir -p "$OUTPUT"
export DEVELOPER_DIR="${XCODE:-/Applications/Xcode.app}/Contents/Developer"

xcodebuild -project BrowserSelector.xcodeproj -scheme BrowserSelector \
    -configuration Release -derivedDataPath "$PACKAGE_WORK/dd" \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
    build > "$PACKAGE_WORK/build.log" 2>&1 \
    || { tail -50 "$PACKAGE_WORK/build.log"; exit 1; }

STAGE="$PACKAGE_WORK/BrowserSelector"
mkdir -p "$STAGE"
ditto "$PACKAGE_WORK/dd/Build/Products/Release/BrowserSelector.app" "$STAGE/BrowserSelector.app"
codesign --force --sign - --identifier com.rehob.BrowserSelector "$STAGE/BrowserSelector.app"
codesign --verify --strict "$STAGE/BrowserSelector.app"
PACKAGE_ARCHS="$(xcrun lipo -archs "$STAGE/BrowserSelector.app/Contents/MacOS/BrowserSelector")"
[[ " $PACKAGE_ARCHS " == *" arm64 "* && " $PACKAGE_ARCHS " == *" x86_64 "* ]] || { echo "Missing universal architecture: $PACKAGE_ARCHS"; exit 1; }
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/LICENSE.txt"

# Package the current working source, including uncommitted feature changes.
python3 - "$PROJECT_ROOT" "$STAGE/BrowserSelector-Source.zip" <<'PY'
import pathlib, subprocess, sys, zipfile
root = pathlib.Path(sys.argv[1])
paths = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root).decode().split('\0')
source_dirs = {'BrowserSelector', 'BrowserSelector.xcodeproj', 'Tests', 'scripts', 'docs', 'images', 'spike', '.github'}
source_files = {'Package.swift', 'README.md', 'LICENSE', '.gitignore', 'PROJECT_CONTEXT.md'}
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(set(paths)):
        if not name:
            continue
        path = pathlib.Path(name)
        if path.parts[0] not in source_dirs and name not in source_files:
            continue
        if any(part in {'xcuserdata', '.DS_Store', '.git'} for part in path.parts):
            continue
        if (root / path).is_file():
            archive.write(root / path, 'BrowserSelector-Source/' + name)
PY
cat > "$STAGE/Install.txt" <<'INSTALL'
BrowserSelector — macOS 13 or later, Apple Silicon and Intel

1. Drag BrowserSelector.app to the Applications shortcut.
2. Eject this disk image and open BrowserSelector from Applications.
3. Choose Make default in BrowserSelector Preferences to use the link picker.
4. Chrome, Chromium, Edge, and Brave profiles appear automatically.
5. Safari profiles require Safari 17+, English menus, and Accessibility access.
   Enable Safari profile selection in Preferences → Browsers, grant access in
   System Settings → Privacy & Security → Accessibility, then refresh profiles.

This personal-sharing build is ad-hoc signed and is not Apple-notarized.
If macOS blocks it, only if you trust its sender and this build, go to
System Settings → Privacy & Security and choose Open Anyway after attempting
launch. Apple’s guidance: https://support.apple.com/102445
No developer tools are required to run the app.

Source code and the GPL-3.0 license are included. BrowserSelector-Source.zip
contains the corresponding working source used for this build, including its
build scripts. This app descends from Browserino / LinkRouter; see README.md
and LICENSE in the source archive for license and upstream credits.
INSTALL

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$STAGE/BrowserSelector.app/Contents/Info.plist")
DMG="$OUTPUT/BrowserSelector-$VERSION-universal.dmg"
hdiutil create -volname BrowserSelector -srcfolder "$STAGE" -ov -format UDZO "$DMG"
hdiutil verify "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"
printf 'Share: %s\n' "$DMG"
