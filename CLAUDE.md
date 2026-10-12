# DiabetesCare (repo: Sucro - Take Care of Diabetes)

iOS 26 SwiftUI + Core Data diabetes logging app. Project, target, module and bundle ID (`com.AngadKumar16.DiabetesCare`) are all **DiabetesCare**; only the repo folder and the Core Data model (`SucroDataModel`, kept so existing stores open) still say Sucro.

- Read `PLANNING.md` first: it lists what works, what's fake, known bugs, and the phased plan.
- Build/test: `xcodebuild test -project DiabetesCare.xcodeproj -scheme DiabetesCare -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` (adjust simulator name; Health UI tests need one simulator, not clones).
- Errors go through `Log` (OSLog), not `print`. User-facing strings returned as `String` use `String(localized:)`.
- Xcode 16 synchronized folders: new files under the source folder join the target automatically; don't hand-edit `project.pbxproj` to add files.
- Glucose is stored in mg/dL everywhere; convert only for display via `SettingsStore`.
- Stage rules (kid/teen/adult) live only in `CareStage.access(to:completed:)`; views gate actions with `ParentGate.run(_:)`. Never gate safety info.
- iCloud family sharing stays off until `FamilyCloud.containerID` is set (needs the paid account; see `docs/release-checklist.md`). Never create a `CKContainer` outside `CloudKitFamilyTransport`.
- UI test launch args: `-uiTesting` (Adult, no passcode), `-stage kid|teen` (passcode 1234), `-resetSetup`, `-resetData`, `-demoData`.
- Do not add Co-Authored-By or Claude-Session trailers to commits.
