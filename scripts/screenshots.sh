#!/bin/sh
# App Store screenshots from demo data, on a 6.9" iPhone and a 13" iPad.
# Output: docs/screenshots/<device>/*.png
#
#   sh scripts/screenshots.sh                      # both devices
#   sh scripts/screenshots.sh "iPad Pro 13-inch (M4)"   # one device
set -eu

OUT="docs/screenshots"
RESULTS="$(mktemp -d)/screens"

[ $# -gt 0 ] || set -- "iPhone 17 Pro Max" "iPad Pro 13-inch (M4)"
for DEVICE in "$@"; do
  UDID=$(xcrun simctl list devices available | grep "$DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  xcrun simctl boot "$UDID" 2>/dev/null || true
  # Let first-boot system banners come and go before shooting.
  xcrun simctl bootstatus "$UDID" >/dev/null
  sleep 20
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  SCREENSHOTS=1 TEST_RUNNER_SCREENSHOTS=1 xcodebuild test -project DiabetesCare.xcodeproj -scheme DiabetesCare \
    -destination "platform=iOS Simulator,id=$UDID" -parallel-testing-enabled NO \
    -only-testing:DiabetesCareUITests/ScreenshotUITests -resultBundlePath "$RESULTS-$UDID.xcresult" -quiet
  DIR="$OUT/$(echo "$DEVICE" | sed 's/[()]//g; s/ /-/g')"
  rm -rf "$DIR"; mkdir -p "$DIR"
  xcrun xcresulttool export attachments --path "$RESULTS-$UDID.xcresult" --output-path "$DIR"
  # Name files after the attachment names.
  /usr/bin/python3 - "$DIR" <<'PY'
import json, os, sys
d = sys.argv[1]
manifest = json.load(open(os.path.join(d, "manifest.json")))
for test in manifest:
    for a in test.get("attachments", []):
        name = a.get("suggestedHumanReadableName", "").split("_")[0] or a["exportedFileName"]
        os.rename(os.path.join(d, a["exportedFileName"]), os.path.join(d, name + ".png"))
os.remove(os.path.join(d, "manifest.json"))
PY
  xcrun simctl status_bar "$UDID" clear
done
echo "Screenshots in $OUT"
