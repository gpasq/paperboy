#!/bin/bash
# Builds Paperboy.app into ./build. Pass --install to copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

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
