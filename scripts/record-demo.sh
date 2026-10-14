#!/bin/sh
# Footage for the CAC demo video: records each DemoReelUITests clip as a video
# and exports its stills, from demo data on an iPhone 17 Pro Max simulator.
# Output: docs/video/assets/rec/<clip>.mp4 and docs/video/assets/stills/<name>.png
#
#   sh scripts/record-demo.sh                 # every clip
#   sh scripts/record-demo.sh test04EarnAndMoveUp test11ParentPhone
set -eu

DEVICE="${DEVICE:-iPhone 17 Pro Max}"
REC="docs/video/assets/rec"
STILLS="docs/video/assets/stills"
WORK="$(mktemp -d)"
mkdir -p "$REC" "$STILLS"

UDID=$(xcrun simctl list devices available | grep "$DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

DEST="platform=iOS Simulator,id=$UDID"
xcodebuild build-for-testing -project DiabetesCare.xcodeproj -scheme DiabetesCare -destination "$DEST" \
  -derivedDataPath "$WORK/build" -quiet

[ $# -gt 0 ] || set -- $(grep -oE 'func (test[0-9]+[A-Za-z]+)' DiabetesCareUITests/DemoReelUITests.swift | sed 's/func //')
for CLIP in "$@"; do
  echo "Recording $CLIP"
  xcrun simctl io "$UDID" recordVideo --codec h264 --force "$REC/$CLIP.mp4" >/dev/null 2>&1 &
  RECORDER=$!
  sleep 1
  TEST_RUNNER_DEMO_REEL=1 xcodebuild test-without-building -project DiabetesCare.xcodeproj -scheme DiabetesCare \
    -destination "$DEST" -derivedDataPath "$WORK/build" -parallel-testing-enabled NO \
    -only-testing:"DiabetesCareUITests/DemoReelUITests/$CLIP" -resultBundlePath "$WORK/$CLIP.xcresult" -quiet || echo "  $CLIP had a failed step; footage kept"
  kill -INT "$RECORDER"; wait "$RECORDER" 2>/dev/null || true
  xcrun xcresulttool export attachments --path "$WORK/$CLIP.xcresult" --output-path "$WORK/$CLIP-stills" >/dev/null 2>&1 || true
  /usr/bin/python3 - "$WORK/$CLIP-stills" "$STILLS" <<'PY'
import json, os, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
path = os.path.join(src, "manifest.json")
if os.path.exists(path):
    for test in json.load(open(path)):
        for a in test.get("attachments", []):
            name = a.get("suggestedHumanReadableName", "").split("_")[0]
            # Keep the stills the clips name; skip XCTest's own failure screenshots and logs.
            if not name or " " in name or "`" in name:
                continue
            shutil.move(os.path.join(src, a["exportedFileName"]), os.path.join(dst, name + ".png"))
PY
done
xcrun simctl status_bar "$UDID" clear
echo "Videos in $REC, stills in $STILLS"
