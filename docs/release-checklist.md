# Release checklist

Steps that need a person, an Apple account or a decision. Code-side prep is done.

## Before the first upload
- [ ] **Name.** Search App Store Connect (My Apps › + › New App) for "DiabetesCare". It is generic and may be taken. Fallbacks: "DiabetesCare Log", "Sucro: Diabetes Log". The home-screen name is `INFOPLIST_KEY_CFBundleDisplayName`.
- [ ] **Bundle ID** `com.AngadKumar16.DiabetesCare`: register it in Certificates, Identifiers & Profiles with the HealthKit, Time Sensitive Notifications and App Groups capabilities. It can't change after the first upload.
- [ ] **Extensions.** Register `com.AngadKumar16.DiabetesCare.Widgets` (App Groups) and the App Group `group.com.AngadKumar16.DiabetesCare` for the app and the widgets. For the watch: `com.AngadKumar16.DiabetesCare.watchkitapp` and `….watchkitapp.Complications` with the App Group `group.com.AngadKumar16.DiabetesCare.watch`. Automatic signing creates these once a team is chosen.
- [x] **Apple Watch app** embedded (`sh scripts/embed-watch.sh`) with its icon. Building the scheme needs the watchOS simulator runtime (`xcodebuild -downloadPlatform watchOS`), including on CI.
- [ ] Watch on a real paired watch: glance updates, "Had 15 g Sugar" starts the phone's countdown.
- [ ] **Support address.** `AppInfo.supportEmail` is `support@sucroapp.com`. Confirm the domain exists, or change it.
- [ ] **Privacy policy.** Host `docs/privacy-policy.md` at a public URL (GitHub Pages works) and enter the URL in App Store Connect.
- [ ] **App Privacy.** Answer the questions as in `docs/app-privacy-labels.md` ("Data Not Collected").
- [ ] **Review notes.** Paste `docs/app-review-notes.md`.
- [ ] **Category.** Medical or Health & Fitness. Medical apps get extra review scrutiny; the disclaimer and "not for dosing" wording support either.
- [ ] **Clinician review** of `Resources/Glossary.json`, the Learn guides, and the low/ketone advice text.
- [x] **App icon** (light, dark, tinted) in `Resources/Assets.xcassets/AppIcon.appiconset`; regenerate with `swift scripts/make-app-icon.swift DiabetesCare/Resources/Assets.xcassets/AppIcon.appiconset`.
- [x] **Screenshots** for 6.9" iPhone and 13" iPad in `docs/screenshots/` (`sh scripts/screenshots.sh` to redo). Upload them in App Store Connect.

## Turn on iCloud family sharing
Family sharing is built but switched off, because iCloud needs a paid Apple Developer account. Until then **See What Family Sees** works and nothing touches CloudKit.
- [ ] **Enroll** in the Apple Developer Program ($99/year). Under 18, a parent or guardian has to enroll (as an individual) and add you to the team.
- [ ] In Certificates, Identifiers & Profiles, add the **iCloud** (CloudKit) and **Push Notifications** capabilities to `com.AngadKumar16.DiabetesCare`, and create the container `iCloud.com.AngadKumar16.DiabetesCare`.
- [ ] From the repo root: `sh scripts/enable-icloud.sh`. It switches the entitlements to `DiabetesCare-CloudKit.entitlements`, merges `Config/DiabetesCare-iCloud-Info.plist` (`CKSharingSupported`, remote-notification background mode) and sets `FamilyCloud.containerID`. Commit the result.
- [ ] Xcode › target › Signing & Capabilities: choose the paid team and let Xcode refresh the profile (iCloud and Push should show as on).
- [ ] Test with two devices on different Apple Accounts: teen phone › Settings › Family › Share with Family › send invite; parent phone › open invite › appears in Family. Log a 50 mg/dL reading on the teen phone; the parent phone should get "Urgent Low" within a minute or two, app closed. Log 65: no alert at Teen, alert at Kid. Kid › Get Help › Tell My Grown-Up should notify the parent.
- [ ] In the CloudKit Console, deploy the schema (record types Entry, Profile, Help, Reply) to Production before the App Store build.
- [ ] Two-device test of help replies: kid › Get Help › Tell My Grown-Up; parent › Family › Maya › "On my way!"; the kid's Get Help screen shows the reply within ~10 s and a notification arrives.

## Apple requests
- [ ] **Critical Alerts entitlement.** Submit the text in `docs/critical-alerts-request.md`. Approval takes weeks; ship without it and add it later.

## Later
- [ ] Food database: regenerate with `python3 scripts/make-food-db.py <FNDDS csv folder> DiabetesCare/Resources/Foods.json` when USDA publishes a new FNDDS release (instructions in the script).
- [ ] Translations: add languages to `Resources/Localizable.xcstrings`. For the Learn tab, add `<lang>.lproj/Glossary.json` (the loader is already locale-aware).
- [ ] Dexcom web API (direct CGM data without Apple Health), which needs Dexcom developer approval.
