# DiabetesCare (repo: Sucro - Take Care of Diabetes)

iOS 26 SwiftUI + Core Data diabetes logging app. User-facing name is **DiabetesCare**; code, target and bundle ID still use "Sucro".

- Read `PLANNING.md` first: it lists what works, what's fake, known bugs, and the phased plan.
- Build/test: `xcodebuild test -project "Sucro - Take Care of Diabetes.xcodeproj" -scheme "Sucro - Take Care of Diabetes" -destination 'platform=iOS Simulator,name=iPhone 17'` (adjust simulator name).
- Xcode 16 synchronized folders: new files under the source folder join the target automatically; don't hand-edit `project.pbxproj` to add files.
- Glucose is stored in mg/dL everywhere; convert only for display via `SettingsStore`.
- Do not add Co-Authored-By or Claude-Session trailers to commits.
