#!/bin/bash
# Builds Paperboy.app into ./build. Pass --install to copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

# Command Line Tools ship the macOS 27 SDK without the SwiftUIMacros plugin (only Xcode has it),
# so @State fails to expand. Fall back to the newest macOS 26 SDK when building without Xcode.
if [[ -z "${SDKROOT:-}" && "$(xcode-select -p)" == *CommandLineTools* ]]; then
    SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.*.sdk 2>/dev/null | sort -V | tail -1)
    [[ -n "$SDK" ]] && export SDKROOT="$SDK"
fi

swift build -c release
APP=build/Paperboy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Paperboy "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Paperboy || true
    rm -rf /Applications/Paperboy.app
    cp -R "$APP" /Applications/
    open /Applications/Paperboy.app
    echo "Installed to /Applications/Paperboy.app"
fi
