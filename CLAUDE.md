# DiabetesCare (repo: Sucro - Take Care of Diabetes)

iOS 26 SwiftUI + Core Data diabetes logging app. Project, target, module and bundle ID (`com.AngadKumar16.DiabetesCare`) are all **DiabetesCare**; only the repo folder and the Core Data model (`SucroDataModel`, kept so existing stores open) still say Sucro.

- Targets: `DiabetesCare` (app), `DiabetesCareWidgetsExtension` (`DiabetesCareWidgets/`), `DiabetesCareWatch` + `DiabetesCareWatchComplications` (embedded; the scheme needs the watchOS simulator runtime: `xcodebuild -downloadPlatform watchOS`), tests. `Shared/` is compiled into app, widgets and watch; app-only code in shared files sits behind `#if !WIDGET_EXTENSION` or `#if os(iOS)`. New targets were added by editing `project.pbxproj` (synchronized folders, so files inside them need no edits).
- Read `PLANNING.md` first: it lists what works, what's fake, known bugs, and the phased plan.
- Build/test: `xcodebuild test -project DiabetesCare.xcodeproj -scheme DiabetesCare -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` (adjust simulator name; Health UI tests need one simulator, not clones).
- Errors go through `Log` (OSLog), not `print`. User-facing strings returned as `String` use `String(localized:)`.
- Xcode 16 synchronized folders: new files under the source folder join the target automatically; don't hand-edit `project.pbxproj` to add files.
- Glucose is stored in mg/dL everywhere; convert only for display via `SettingsStore`.
- Stage rules (kid/teen/adult) live only in `CareStage.access(to:completed:)`; views gate actions with `ParentGate.run(_:)`. Never gate safety info.
- iCloud family sharing stays off until `FamilyCloud.containerID` is set (needs the paid account; see `docs/release-checklist.md`). Never create a `CKContainer` outside `CloudKitFamilyTransport`.
- UI test launch args: `-uiTesting` (Adult, no passcode; hides tips and toasts), `-stage kid|teen` (passcode 1234), `-resetSetup`, `-resetData` (also empties supplies), `-demoData` (Maya, teen), `-demoFamily` (parent's phone with a waiting help request, Debug only), `-toasts` (show undo toasts in a UI test).
- Outside-the-app entry points go through `AppRouter` (`diabetescare://` URLs, notification `userInfo["route"]`, Spotlight ids). After data changes, `GlanceWriter` updates widgets, the Live Activity and the watch; don't reload widgets elsewhere.
- Scripts: `sh scripts/enable-icloud.sh` (after enrollment), `sh scripts/screenshots.sh`, `swift scripts/make-app-icon.swift <appiconset>` (`--alternates <xcassets>` for the icon picker), `python3 scripts/make-food-db.py <FNDDS csv dir> DiabetesCare/Resources/Foods.json`, `sh scripts/embed-watch.sh`, `sh scripts/record-demo.sh` (demo-video footage from `DemoReelUITests`).
- Core Data: add a new model version for schema changes (current: `SucroDataModel 2`); entity classes are hand-written in `Models/Domain/`. New entities go in `BackupArchive` as optional fields.
- Do not add Co-Authored-By or Claude-Session trailers to commits.
