#!/bin/sh
# Turns on iCloud family sharing. Run once, from the repo root, after the
# paid Apple Developer account has the iCloud container
# iCloud.com.AngadKumar16.DiabetesCare and Push Notifications set up for
# com.AngadKumar16.DiabetesCare (see docs/release-checklist.md).
#
#   sh scripts/enable-icloud.sh
#
# It changes three things, all visible in `git diff` and undone with
# `git checkout -- DiabetesCare.xcodeproj DiabetesCare/Services/Family`:
#   1. The app target signs with DiabetesCare-CloudKit.entitlements
#      (iCloud + CloudKit container + push).
#   2. The app target merges Config/DiabetesCare-iCloud-Info.plist
#      (CKSharingSupported, remote-notification background mode).
#   3. FamilyCloud.containerID is set, which switches the code on.
set -eu

CONTAINER="iCloud.com.AngadKumar16.DiabetesCare"
PROJECT="DiabetesCare.xcodeproj/project.pbxproj"
TRANSPORT="DiabetesCare/Services/Family/CloudKitFamilyTransport.swift"

[ -f "$PROJECT" ] || { echo "Run from the repo root." >&2; exit 1; }

if grep -q '"DiabetesCare/DiabetesCare-CloudKit.entitlements"' "$PROJECT"; then
  echo "Entitlements already switched."
else
  sed -i '' 's#CODE_SIGN_ENTITLEMENTS = "DiabetesCare/DiabetesCare.entitlements";#CODE_SIGN_ENTITLEMENTS = "DiabetesCare/DiabetesCare-CloudKit.entitlements";#' "$PROJECT"
  echo "Signing with DiabetesCare-CloudKit.entitlements."
fi

if grep -q 'INFOPLIST_FILE = Config/DiabetesCare-iCloud-Info.plist;' "$PROJECT"; then
  echo "Info.plist additions already merged."
else
  # Only the app target's configurations carry the entitlements setting.
  awk '
    /CODE_SIGN_ENTITLEMENTS = "DiabetesCare\/DiabetesCare-CloudKit.entitlements";/ { print; print "\t\t\t\tINFOPLIST_FILE = Config/DiabetesCare-iCloud-Info.plist;"; next }
    { print }
  ' "$PROJECT" > "$PROJECT.tmp" && mv "$PROJECT.tmp" "$PROJECT"
  echo "Merging Config/DiabetesCare-iCloud-Info.plist."
fi

if grep -q "static let containerID: String? = \"$CONTAINER\"" "$TRANSPORT"; then
  echo "FamilyCloud.containerID already set."
else
  sed -i '' "s#static let containerID: String? = nil#static let containerID: String? = \"$CONTAINER\"#" "$TRANSPORT"
  echo "FamilyCloud.containerID = $CONTAINER."
fi

echo
echo "Done. In Xcode: pick your paid team under Signing & Capabilities, then"
echo "run the two-device test in docs/release-checklist.md."
