#!/bin/sh
# Watch still for the CAC demo video: pairs an Apple Watch simulator with the iPhone 17 Pro Max,
# installs both apps, launches the phone with demo data (it sends the glance to the watch over
# WatchConnectivity) and screenshots the watch app to docs/video/assets/stills/watch-glance.png.
set -eu

PHONE="${PHONE:-iPhone 17 Pro Max}"
WATCH="${WATCH:-Apple Watch Series 11 (46mm)}"
WORK="$(mktemp -d)"
udid() { xcrun simctl list devices available | grep "$1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'; }
P=$(udid "$PHONE"); W=$(udid "$WATCH")
xcrun simctl pair "$W" "$P" >/dev/null 2>&1 || true
xcrun simctl boot "$P" 2>/dev/null || true
xcrun simctl boot "$W" 2>/dev/null || true
xcrun simctl bootstatus "$W" >/dev/null

xcodebuild build -project DiabetesCare.xcodeproj -scheme DiabetesCare -destination "platform=iOS Simulator,id=$P" \
  -derivedDataPath "$WORK/build" -quiet
xcrun simctl install "$P" "$WORK/build/Build/Products/Debug-iphonesimulator/DiabetesCare.app"
xcrun simctl install "$W" "$WORK/build/Build/Products/Debug-watchsimulator/DiabetesCareWatch.app"
xcrun simctl launch "$W" com.AngadKumar16.DiabetesCare.watchkitapp >/dev/null
sleep 3
xcrun simctl launch --terminate-running-process "$P" com.AngadKumar16.DiabetesCare -uiTesting -demoData -stage kid >/dev/null
sleep 12
xcrun simctl io "$W" screenshot docs/video/assets/stills/watch-glance.png
