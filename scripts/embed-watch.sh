#!/bin/sh
# Embeds the Apple Watch app (DiabetesCareWatch + its complications) in the
# iPhone app. Off by default because Xcode refuses to build or test a scheme
# with an embedded watch app unless the watchOS simulator runtime is
# installed. Run once, from the repo root, after:
#
#   xcodebuild -downloadPlatform watchOS
#   sh scripts/embed-watch.sh
#
# Undo with `git checkout -- DiabetesCare.xcodeproj`. The watch targets
# build on their own either way:
#   xcodebuild build -project DiabetesCare.xcodeproj -target DiabetesCareWatch -sdk watchsimulator
set -eu
PROJECT="DiabetesCare.xcodeproj/project.pbxproj"
[ -f "$PROJECT" ] || { echo "Run from the repo root." >&2; exit 1; }

if grep -q 'AC0000000000000000000014 /\* Embed Watch Content \*/,' "$PROJECT"; then
  echo "Watch app already embedded."
  exit 0
fi

# Add the copy phase after the widgets' embed phase, and the dependency
# after the widgets' dependency, in the app target only.
awk '
  /AB000000000000000000000C \/\* Embed Foundation Extensions \*\/,/ && !phase { print; print "\t\t\t\tAC0000000000000000000014 /* Embed Watch Content */,"; phase = 1; next }
  /AB000000000000000000000F \/\* PBXTargetDependency \*\/,/ && !dep { print; print "\t\t\t\tAC0000000000000000000017 /* PBXTargetDependency */,"; dep = 1; next }
  { print }
' "$PROJECT" > "$PROJECT.tmp" && mv "$PROJECT.tmp" "$PROJECT"
echo "Embedded DiabetesCareWatch in DiabetesCare."
