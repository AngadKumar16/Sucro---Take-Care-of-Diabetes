# DiabetesCare — Planning Guide

Status of the codebase (repo folder still named `Sucro - Take Care of Diabetes`). First written 2026-10-07 as an audit; Phases 0–4 are done (2026-10-12); Phase 6 (widgets, Live Activity, Siri, watch, carb lookup, stories and more) on 2026-10-13. Phase 5 ("Grows with you", for the Congressional App Challenge): weeks 1–3 of app work are done; iCloud family sharing is built and waits only on the paid developer account. What's left that needs a person or Apple: see `docs/release-checklist.md`.

## Snapshot

- iOS 26, SwiftUI + Core Data (`SucroDataModel`, name kept so existing stores open), Swift 5, Xcode 16 synchronized folders (new files in the source tree are added to the target automatically).
- Architecture: `Views/` → `ViewModels/` (ObservableObject) → `Services/` singletons (`DataService`, `NotificationService`, ...) → Core Data.
- Navigation: 5 tabs (Today, Log, Trends, Learn, Settings), `sidebarAdaptable` on iPad. Reports opens from the Share Report button on Trends. Devices, Help and Safety Information are pushed from Settings. A caregiver's phone gets 3 tabs instead (Family, Learn, Settings).
- First launch: safety notice → "Who's using DiabetesCare?" (Kid / Teen / Adult / Parent or caregiver) → app. `RootView` routes; `SettingsStore.careStage` + `appRole` hold the answer.
- Name: **DiabetesCare** everywhere — `DiabetesCare.xcodeproj`, scheme/target/module `DiabetesCare`, folders `DiabetesCare/`, `DiabetesCareTests/`, `DiabetesCareUITests/`, bundle ID `com.AngadKumar16.DiabetesCare` (renamed 2026-10-12; the old ID's installs don't carry over). Only the repo folder and `SucroDataModel` still say Sucro.
- `Resources/Glossary.json`: 134 curated glossary terms (`id`, `name`, `aliases`, `category`, `summary`, `details`, `related`, `inApp`) behind the Learn tab. Replaced the prototype's `MedicalTerms.json` (216 terms, about half off-topic, fake URLs, unused `isPremium`). Content is general information, written in plain language, and should get a clinician review before release.

## What works

| Area | Status |
|---|---|
| Manual logging: glucose, carbs, insulin, activity, site change | Works. Saves to Core Data and mirrors to Apple Health (write-only). mmol/L input is converted and stored as mg/dL. |
| Edit / delete / add notes to timeline events | Works (`DraftOperation`, edit views, `DataService.delete/addNote`). |
| Home dashboard: latest glucose, today totals, IOB, mini timeline, recent cards, site snapshot, quick actions, meal/bolus presets | Works off local data. |
| Monitor tab: readings by date range, average, min–max | Works. |
| Insights: stats (avg, SD, CV, TIR), weekday patterns, carb→spike correlations | Computes from real data (see bugs below). |
| Reports + export (PDF report, print; glucose CSV from Settings) | Works; no-data case handled. There is no PNG export. |
| Settings: unit, thresholds, insulin action time, notifications, appearance, backup/restore, export, clear all data | Persisted in UserDefaults via `SettingsStore`. |
| Site changes | Body-map picker (add and edit), reminders from rotation days, Site History (rest per site, days worn), Sites filter in Log. |
| Backup / restore | Daily JSON backup of every entry (photos included) + settings to `Documents/Backups`, newest 7 kept, visible in Files. Back Up Now (save anywhere) and Restore (add missing or replace all). |
| iPad | Today and Trends use two columns at regular width; Log keeps a readable width. |
| Tests | Swift Testing unit tests (settings persistence, unit conversion, Core Data persistence, clear-all, date-range fetch, draft edit, report stats) + XCUITests for main flows (`-uiTesting` launch arg skips HealthKit prompt). |

## What doesn't work / is fake

Everything in this section has been fixed; kept as a record. Fixes are noted in the phases below.

### Not real (UI exists, nothing behind it)
1. **CGM connection.** `DeviceMonitorService` creates a `CBCentralManager` but never scans, never discovers services, and all peripheral delegate methods are empty. No glucose ever arrives from a device. Side effect: Bluetooth permission prompt fires at launch for no reason.
2. **Devices tab.** Hard-coded catalog (Dexcom G6, Omnipod 5, Libre 3, t:slim) with fake battery levels. "Connect" only appends the name to a settings array.
3. **Devices toggles** `autoSyncEnabled`, `backgroundMonitoringEnabled`, `lowBatteryAlertsEnabled` are saved but never read anywhere.
4. **Apple Health import.** `HealthKitManager.fetchGlucoseReadings` exists but is never called — the app only writes to Health, never reads. (This is the cheapest real path to CGM data: Dexcom/Libre apps write to Health.)
5. **"Battery" on Home** is the *phone's* battery (`UIDevice`), not the CGM/pump.
7. ~~`BodyMapView` taps just `print`.~~ Stale by 2026-10: `BodyMap` taps select a site. Edit Site Change now uses it too.

### Bugs / logic problems
1. **"Device offline" alert = phone has no internet.** `isConnected` comes from `NWPathMonitor` and is fed into `AlertService` as device connectivity.
2. **Fake sync freshness.** `startSyncTimer` sets `lastSyncTime = Date()` every minute if the last sync was <5 min ago, so "last sync" never ages.
3. **Critical-alert spam.** `AlertService.checkForCriticalAlerts` runs on every `HomeViewModel.fetchLatestData()` and schedules a new notification each time (UUID identifier, no dedupe). A single low reading re-notifies on every refresh.
4. **Critical alerts aren't critical.** `.interruptionLevel = .critical` / `.defaultCritical` need Apple's `com.apple.developer.usernotifications.critical-alerts` entitlement (must be requested from Apple). Not in entitlements → delivered as normal notifications.
5. **Trend is never set on manual readings.** `GlucoseReading.trend` is only nil/preview data, so trend arrows and the "glucose trending up → check ketones" suggestion never fire.
6. **`calculateTrend` is order-dependent.** Uses `prefix(3)` first vs last; `calculateTrends` passes unsorted day groups → sign can be inverted. Also returns `.stable` for exactly 2 readings despite the `>= 2` guard. Percent-change thresholds are not how CGM trend arrows are defined (mg/dL per minute).
7. **TIR is count-based** and `calculateTimeSpan` assumes ascending order; sparse manual logs give misleading percentages/hours.
8. **IOB** is a linear 4-hour decay, duplicated in `DataService.calculateIOB` and `GlucoseCalculator.calculateIOB`. Fine as a display estimate; not fine for any dosing advice. Pick one implementation; consider an exponential curve with user-set DIA.
9. **Threshold inconsistency.** Low alert fires at `targetLow` (e.g. 70) but colors use `urgentLow = targetLow - 20`. `urgentHigh = targetHigh + 70` is arbitrary. Define explicit settings: low, target low/high, urgent low/high.
10. **Two reminder systems** (`RealReminderService` and `NotificationService`) both request notification permission and schedule notifications. Consolidate.
11. **Duplicate `MonitorViewModel`.** Created in `SucroApp` (injected as env object) and again in `MainTabView`. Only one is used per view — remove the app-level one or share it.
12. **Crashes on store failure.** `Persistence.swift` `fatalError`s if Core Data fails to load; fine in dev, not in a release health app.
13. ~~**Backup** only covers glucose and stays on-device. No restore.~~ Fixed in Phase 3.
14. **CI is broken.** `.github/workflows/swift.yml` runs `swift build` / `swift test`, but there's no `Package.swift`. Needs `xcodebuild test -scheme ... -destination 'platform=iOS Simulator,...'`.
15. ~~Dead code; `print` error handlers swallow errors.~~ Fixed: dead code removed in Phase 0; all 42 `print`s replaced by `Log` (OSLog categories data/health/notifications/backup/export) on 2026-10-12, and failed deletes, notes and site saves now show an alert.
16. `.windsurf/plans/home_page_feature_gap_analysis.md` is stale (says ~15% done; most of that list is now built).

## Plan (suggested order)

### Phase 0 — Baseline (done 2026-10-07)
- [x] Open in Xcode, build for an iOS 26 simulator, run unit + UI tests. Record failures. *(Before any change: all 10 unit and 13 UI tests passed on iPhone 17 / iOS 26.0.)*
- [x] Fix CI to use `xcodebuild` (bug 14). *(`.github/workflows/swift.yml` now runs `build-for-testing` + `test-without-building` on `macos-26` with Xcode 26 and picks an available iPhone simulator.)*
- [x] Delete `ContentView.swift`, the duplicate `MonitorViewModel` (bug 11), and the stale windsurf plan. *(Also removed the unused `OptionalBinding.swift` and its project exceptions, which caused a build warning. The app-level `MonitorViewModel` is the one kept: the full-screen Monitor opened from Home needs it, and the Monitor tab now shares it.)*

### Phase 1 — Correctness & safety (done 2026-10-07)
- [x] Alert dedupe: one notification per crossing event, with cooldown; stable identifiers (bug 3). *(`GlucoseAlertPolicy` in `Services/AlertService.swift`: notifies when a reading crosses into low / urgent low / urgent high, 30 min cooldown per kind, low → urgent low always notifies, readings older than 15 min never notify. State persists in UserDefaults. Notifications are time-sensitive (entitlement added) with ids `alert.glucose.<kind>`.)*
- [x] Separate "CGM data stale" from "phone offline"; base staleness on time since last reading (bugs 1, 2). *(Network status no longer feeds alerts. A "no recent readings" warning is scheduled 20 min after the last reading, only when recent readings look like a CGM stream, so fingerstick-only users never see it. Fake sync timer removed. Home shows the reading's real age and greys it out after 15 min. Phone battery removed from Home.)*
- [x] Explicit threshold settings and one source of truth for low/high/urgent (bug 9). *(Settings has Urgent Low / Low / High / Urgent High steppers (default 55/70/180/250), always kept in order. `GlucoseThresholds.zone(for:)` drives colors, banner, alerts and stats. Insights now uses the user's range instead of a hard-coded 70–180.)*
- [x] Fix trend calc: sort by timestamp, rate in mg/dL/min, only compute when readings are ≤15 min apart (bugs 5, 6). *(`GlucoseCalculator.trend(samples:)`: least-squares rate over the last 15 min, needs ≥5 min span and no gap >15 min; arrows at 1 and 2 mg/dL/min. Set on each new reading. Day/weekday patterns use a separate `direction(samples:)`.)*
- [x] Single IOB implementation + unit tests; label it "estimate" in UI (bug 8). *(`GlucoseCalculator.insulinOnBoard`, Loop/OpenAPS exponential curve with 75 min peak and a user-set insulin action time (3–6 h, default 4). Counts rapid-acting doses including entries older builds saved as "Rapid Acting". Home shows "x U active (estimate)".)*
- [x] Merge reminder services (bug 10). *(`RealReminderService` removed. `NotificationService` is the only code touching `UNUserNotificationCenter`; `ReminderService` plans site-change and post-dose glucose-check reminders from the data with stable ids, so refreshes don't duplicate and snooze/complete stick. The 1-minute "missed reading" spam is gone.)*
- [x] Replace `fatalError` in persistence with a recoverable error screen (bug 12). *(`PersistenceController` publishes `loadError`; `StoreErrorView` offers Try Again or Erase and Start Over.)*
- [x] In-app disclaimer: not a medical device, not for dosing decisions. *(Shown before first use, must be accepted; rereadable from More → Help → Safety Information. Help is now a tab in More, which also makes the Emergency Medical ID reachable.)*

Also fixed along the way: Quick Bolus said "Deliver Bolus" (it only logs) and sent a bogus "HIGH GLUCOSE 0" notification for doses over 10 U; it now says "Log Bolus" and asks to confirm doses over 10 U. Long-acting doses were sent to Apple Health as boluses. The full-screen Monitor opened from Home had no way to close it. Insulin type labels were inconsistent between the Add and Edit forms.

### HIG usability pass (done 2026-10-07)
- [x] One 5-tab bar instead of tabs + More sheet; Monitor and Insights merged into Trends (one shared `TimeRange`).
- [x] Every add/edit form shares `EntryForm` + `EntryFields`: Time field (backdating), autofocus, range validation, locale-aware number parsing, discard check, success haptic. Edit exists for every entry type; edit pickers read legacy lowercase values (`MealType/DeliveryMethod/SiteLocation(stored:)`).
- [x] Log tab: list of the day with All filter, prev/next day, + menu, tap to edit, swipe to delete.
- [x] Today: fixed event markers (were all drawn at one x), target band, empty states, context menus instead of custom swipe, site due date, Log Meal presets as a system menu.
- [x] System text styles everywhere (Dynamic Type), grouped backgrounds that work in dark mode, Settings/Reports/Devices as Form/List, Appearance System/Light/Dark (migrates old dark mode switch).
- [x] Devices is an honest stub (Apple Health status + "no direct connection yet"); fake catalog, battery and dead toggles removed.
- [x] iPad layout (2026-10-12): Today splits into glucose (reading, thread, quick actions) and activity (logged in view, plan, sites) columns at regular width; Trends puts chart beside time in range and insights beside weekly patterns; Log caps at 720 pt. Compact width (iPhone, Split View) is unchanged.

### Feature sweep (done 2026-10-08)
Every feature driven in the simulator through UI tests (`FeatureFlowUITests`, `HealthImportUITests`, launched with `-resetData` for an empty store). Bugs found and fixed:
- **Stale screens after edits elsewhere.** Refetching returns the same managed objects, which Observation treats as unchanged, so a note added on Today didn't appear in Log, and a reading edited in Log still showed its old value on Today. Log, Today and Trends now refetch on `NSManagedObjectContextObjectsDidChange`. Log rows redraw through a `revision` counter, the Today hero observes its reading (`@ObservedObject`), the Today chart takes plain `GlucoseSample` values, and the site card is `CurrentSiteRow` observing its `SiteChange`.
- **Active insulin hidden with no glucose reading.** A dose logged before any reading didn't show "x U active (estimate)". The empty hero now shows it (`InsulinOnBoardLabel`).
- **Health observer dead on first launch** (see Phase 2).
- **Site photos were write-only.** The photo picked on Change Site was saved but nothing ever showed it again. `SitePhotoSection` is now shared by Change Site and Edit Site Change (Today › Recent Activity › Details › Edit), so a saved photo can be seen, replaced and removed. Loads go through `.task(id:)` so a quick second pick cancels the first, a failed load says so, and photos are downscaled to 1600 px JPEG (`SitePhoto.encode`) instead of storing 12 MP originals in Core Data.
- **Photo picker and Health deletions tested end to end.** `testSitePhotoCanBeAddedSeenAndRemoved` picks a simulator sample photo in the system picker, saves, reopens the site change and removes it. `testGlucoseDeletedInHealthIsRemoved` adds a reading in the Health app, waits for it in Log, deletes it in Health (Show All Data › swipe › Delete) and checks it leaves the Log. The Health UI helpers now survive a fresh simulator (search index not built yet, onboarding buttons with no label) and Health reopening on a pushed page or modal. Test readings use random in-range values (101–169) and are deleted afterwards. Run these UI tests with `-parallel-testing-enabled NO`: Health permission and data live per simulator, and clones start without them.
Covered: add/edit/delete carbs, insulin, activity, glucose; Log filters and day navigation; Quick Bolus; site change; details → add note; low/high banners and their actions (carbs form, ketone advice); post-dose glucose check → mark done; mmol/L display; daily backup; Devices; Health import. Earlier suites cover safety notice, thresholds, large-bolus confirm, Learn, Help, appearance, Clear All, export and Reports.

### Phase 2 — Real data in (done 2026-10-07)
- [x] Read glucose from Apple Health (`HKObserverQuery` + anchored query, background delivery), dedupe against Health samples the app itself wrote. Set `trend` from rate of change. *(`HealthGlucoseImporter` registers the observer at launch and enables `.immediate` background delivery (entitlement added). The anchored query skips samples from `HKSource.default()`, so mirrored manual readings never come back. The first sync reads the last 30 days. Imported readings keep the Health UUID as `id` with `source = "health"` (no model change), so re-deliveries are skipped and deletions in Health carry over. Writes are batch insert/delete on a background context, merged into the view context. Trend is computed per sample over the stored + new trace (`HealthGlucoseImport.trends`). Alerts are re-evaluated after each import. Clear All Data resets the anchor and re-reads the 30 days. In the Log, Health readings without a note are kept out of All (shown under Glucose) so a CGM's ~288 readings a day don't bury meals and doses. The value and time of an imported reading are read-only; context and notes can still be edited.)*
- [x] Rework Devices around what's real: "Apple Health source: connected / last reading X min ago". *(Devices › Glucose from Apple Health: status (Waiting / Receiving / No Recent Readings, refreshed every minute), last reading, time, source app, Check Now / pull to refresh, Connect Apple Health if the permission sheet was never shown, setup footer. "What You Log" keeps the write status. The Bluetooth usage string was removed. Help and the no-readings troubleshooting copy were updated.)*
- Verified end to end 2026-10-08: `HealthImportUITests` adds a Blood Glucose sample in the Health app on the simulator and checks it shows up in Log (tagged Apple Health) and as "Receiving" in Devices. This found a bug: the observer query started before the user answered the permission sheet died for good, so nothing came in until relaunch. `HealthGlucoseImporter.refresh()` now re-creates the observer after the permission sheet and every time the app comes to the foreground, and syncs.
- [x] Only init `CBCentralManager` when the user opts into a device flow, or remove BLE until there is a real integration. *(`DeviceMonitorService` was deleted after Phase 1: nothing used it, and its only effects were the fake phone-battery/network status and the launch-time Bluetooth prompt. A real integration starts fresh. The Bluetooth usage string in the build settings can go too if BLE is dropped for good.)* (Direct Dexcom/Libre BLE is proprietary; Dexcom has a web API — investigate later.)

### Phase 3 — Features
- [x] Glossary/Learn tab *(2026-10-07: search by name/alias/definition, Start Here, 9 topics, A–Z with section index, saved terms, related links, share. Inline links from Trends stat tiles, Settings footers and the ketone sheet. Reports moved into a Trends sheet to make room. Still to do: clinician review of the wording; localization.)*
- [x] Full backup/restore *(2026-10-12: `BackupArchive` (versioned JSON, every entity, site photos, main settings) + `BackupStore` (batch insert, merge by id or replace) in `Services/BackupArchive.swift`; `BackupService` writes the daily file and prunes to 7; Files app sharing on (`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`) so backups can be moved to iCloud Drive. Settings › Back Up Now (`.fileExporter`) / Restore from Backup (`.fileImporter` → Add Missing Entries / Replace All Data). Health readings keep their id and source, so Health deletions still carry over after a restore. Tests: `BackupTests`.)*
- [x] Body map + rotation history *(2026-10-12: taps already selected a site. `SitePicker` is shared by Change Site and Edit Site Change. Today › Your sites › History opens `SiteHistoryView`: map, rest per site, every change with days worn vs rotation days (amber when overdue), photo thumbnail, edit/delete. Log lists site changes with a Sites filter. Math in `SiteRotation`, tested in `SiteRotationTests`; flow in `testSiteHistoryListsChangesAndEditsWithTheBodyMap`.)*
- [x] Localization groundwork *(2026-10-12: `Resources/Localizable.xcstrings`; String-returning UI helpers use `String(localized:)`. English only. Xcode fills the catalog on build in the IDE. For the glossary, add `<lang>.lproj/Glossary.json`; the loader is already locale-aware.)*

### Phase 4 — Ship
- [x] Full rename → DiabetesCare, bundle ID `com.AngadKumar16.DiabetesCare` *(2026-10-12; CI and CLAUDE.md updated; all unit tests and all 42 UI tests pass on iPhone 17 / iOS 26. `-resetData` now also resets thresholds, Safety UI tests use it, and the stale "tapping the reading opens Trends" test was updated: tapping it returns the thread to now).*
- [x] Privacy manifest `DiabetesCare/PrivacyInfo.xcprivacy` (no tracking, no collected data, UserDefaults CA92.1). HealthKit read access narrowed to blood glucose.
- [x] Drafts in `docs/`: privacy policy, App Review notes, App Privacy answers ("Data Not Collected"), critical-alerts request text, release checklist.
- [ ] **Manual** (see `docs/release-checklist.md`): check App Store name availability, register the bundle ID, host the privacy policy, confirm the support email, submit the critical-alerts request (bug 4), clinician review of the glossary and advice text, screenshots.


## Phase 5 — "Grows with you" (Congressional App Challenge 2026)

### Why
Entry for the Congressional App Challenge (deadline ~late Oct / early Nov 2026; check congressionalappchallenge.us for the exact date, video length cap and rules). Team: Angad & Abhay. Story: Angad's mom has type 1 diabetes. Without a differentiator the app reads as "another diabetes logger" (mySugr, Glucose Buddy). The business canvas defines it: **the app grows with the user**. Kid (parent in charge, everything goes to the parent) → Teen (teen logs, parent sees, fewer alerts) → Adult (full control, share with family or doctor). Vision: every kid with diabetes grows confident caring for themselves. Values: privacy (nothing comes to us; COPPA), simplicity, free.

Judges are mostly non-technical and mostly watch the demo video, so the order of work is story → video → real users → README → polish. No paid Apple Developer account yet, so iCloud is built but switched off, and everything else must be demoable and honest without it.

### Week 1 — Stages, parent lock, skills (done 2026-10-12)
- [x] `Models/Domain/CareStage.swift`: `CareStage` (kid/teen/adult), `Feature` (logInsulin, quickBolus, changeSite, editThresholds, editInsulinSettings, turnOffNotifications, clearData, restoreBackup, changeStage, stopSharing), `FeatureAccess` (open / parent / hidden), `AppRole` (selfCare / caregiver). `CareStage.access(to:completed:)` is the only place the rules live:
  - Kid: Quick Bolus hidden; insulin, site change, insulin settings, ranges, notifications off, clear, restore, stage, stop sharing need the grown-up passcode.
  - Teen: logs everything alone; ranges, notifications off, clear, restore, stage, stop sharing need the passcode.
  - Adult: all open.
  - Safety info (low card, ketone advice, Help, Safety) is never gated.
- [x] `SettingsStore`: `careStage` (nil until chosen; unset counts as Adult), `appRole`, `completedSkills`, `familySharingEnabled`, `stage`, `hasChosenSetup`, `access(to:)`, `complete(_:)`.
- [x] `Services/ParentLock.swift`: 4-digit grown-up passcode, salted SHA-256 in the Keychain (`WhenUnlockedThisDeviceOnly`), unlocks for 5 min, locks when the app goes to the background, 30 s lockout after 5 wrong tries. A speed bump for a kid, not real security.
- [x] `Views/Growth/ParentGate.swift`: one gate at the root; `gate.run(feature) { … }` runs, asks for the passcode, or does nothing. `PasscodeView` (friendly keypad; create twice / approve).
- [x] `Views/Growth/SetupView.swift`: first-launch "Who's using DiabetesCare?" with optional first name; Kid/Teen create the passcode. Also from Settings › Growing Up › Change Who It's For (gated).
- [x] Kid Today: `KidHelpCard` ("Feeling off?" → Check Glucose / Get Help). `KidHelpView`: find a grown-up, 15 g fast sugar (logs it and starts the 15-min recheck), check again, emergency line, **Tell My Grown-Up** (help request to family when sharing is on). No Quick Bolus key; Change Site gated.
- [x] Gates wired: Today quick actions and site card, Log › Add Insulin (lock icon when it'll ask), Settings ranges + insulin action time ("Unlock to Change"), notifications off, Restore, Clear All Data, Change Who It's For, Stop Sharing.
- [x] `Models/Domain/Skill.swift`: 6 skills. 4 quizzes tied to the Learn guides (Know Your Ranges, Treat a Low, Read the Numbers, Time in Range), 3 questions each, all right to pass, wording matches the guides. 2 habits read from the log (`SkillHabits`): Steady Logger (7 days in a row of entries you logged; CGM imports don't count) and Low, Treated, Checked (low → carbs within 20 min → back above Low within 40 min). `Services/SkillProgress.swift` marks habits done (on Your Path and when the app becomes active).
- [x] Skill unlocks (kid): Know Your Ranges + Treat a Low → log insulin without the passcode; Steady Logger → log site changes. Skills never open Quick Bolus or the risky settings.
- [x] Moving up: kid → teen needs the 4 quizzes; teen → adult needs all 6; the grown-up approves with the passcode. Reaching Adult removes the passcode.
- [x] `Views/Growth/SkillPathView.swift` ("Your Path"): Kid → Teen → Adult ladder, next-stage card with progress and Move Up, skill rows with what each opens. Reached from Learn (top row) and Settings › Growing Up. `SkillQuizView` one question at a time with the reason after each answer, link to the guide, retake any time. No dosing content anywhere.

### Week 2 — Family sharing (built 2026-10-12; iCloud part untested until enrollment)
- [x] Design: **one-way, read-only**. The person with diabetes publishes; family follows. Not `NSPersistentCloudKitContainer`: the local store and model stay as they are, and a follower's data never mixes with their own log.
- [x] `Services/Family/FamilyModels.swift`: `FamilyChangeSet` (profile, entries as `BackupArchive`, deleted ids, help requests), `FamilyProfile` (name, stage, ranges, unit, skills), `FamilyHelpRequest`, `FamilyPerson`.
- [x] `FamilyDiff`: what's shared (last 30 days; never photos; notes only at Kid) and what changed since the last publish, by a SHA-256 fingerprint per entry. Fingerprints are saved only after a successful send.
- [x] `FamilyStore`: builds the shareable archive; applies a change set to a follower's store (edits replace, deletions go) with batch requests; one SQLite store per followed person in Application Support/Family.
- [x] `FamilyTransport` protocol. `LoopbackFamilyTransport` (in memory, ordered log, tokens) for tests and the preview. `CloudKitFamilyTransport`: zone "Family" in the private DB, records `Entry` (kind + JSON payload), `Profile`, `Help`; zone-wide `CKShare` (read only, private); follower reads the shared DB with `recordZoneChanges` and change tokens; `CKDatabaseSubscription` (silent push) wakes the parent's phone.
- [x] `FamilyService`: publishes 3 s after any save to the main store (debounced, so a CGM import goes as one batch) and on becoming active; follower refresh pulls every followed person, applies, and runs `CaregiverAlertPolicy`; help requests; start/stop sharing; unfollow; `makePreview()` runs the real publish → fetch → apply path through the loopback into a temp store.
- [x] `CaregiverAlertPolicy`: kid → low, urgent low, urgent high, no recent CGM data, help requests; teen → urgent low/high only; adult → urgent low only. Reuses `GlucoseAlertPolicy` crossing + cooldown, so one low is one alert. `NotificationService.deliverFamilyAlert` ("Maya: Urgent Low"), one identifier per person and kind.
- [x] `AppDelegate` (`App/AppDelegate.swift`): scene delegate accepts iCloud invitations; silent pushes refresh followed people.
- [x] Views: `FamilySettingsView` (Share with Family / Invite / Stop Sharing, what's shared, **See What Family Sees**, people you follow), `CaregiverView` (latest reading in their ranges, last 12 h chart, today's time in range / lows / carbs / insulin, what was logged, their path), `FamilyHomeView` + `CaregiverTabView` for a caregiver's phone, `CloudSharingSheet` (`UICloudSharingController`).
- [x] Switched off until enrollment: `FamilyCloud.containerID = nil` → no `CKContainer` is ever made (it crashes without the entitlement). Family settings say so plainly; the preview works. `DiabetesCare/DiabetesCare-CloudKit.entitlements` is ready. Steps in `docs/release-checklist.md` › Turn on iCloud family sharing.
- [x] Docs: privacy policy (family sharing, children), App Review notes (stages, passcode, family sharing, background modes), App Privacy (still "Data Not Collected": the user's own iCloud).
- [ ] **After enrollment:** turn it on and run the two-device test in the checklist (teen + parent Apple Accounts, urgent-low alert with the app closed, help request, stop sharing).

### Week 3 — App work without the developer account (done 2026-10-12)
- [x] **CloudKit layout tested without iCloud.** `Services/Family/FamilyRecordCodec.swift` (pure) turns change sets into `CKRecord`s and back; `CloudKitFamilyTransport` only does I/O. Tests caught a real bug: batches capped saves and deletes separately, so one request could carry 700 items (CloudKit allows 400). Batches now cap both together at 350. A failed record now fails the publish, so the fingerprints aren't saved and everything is resent next time.
- [x] **Get Help works without iCloud.** Settings › Family › Grown-Up to Call (name and phone; changing it needs the passcode, `Feature.editGrownUpContact`). Get Help shows Call and Text buttons (`tel:` / `sms:` with "I need help. My glucose is …", the reading only if under 30 minutes old). `Models/Domain/GrownUpContact.swift`. The phone pad got a keyboard Done button.
- [x] **Gaps closed.** The overdue-site banner went straight to Change Site; it now goes through the gate. A kid could edit or delete insulin and site entries from Log or Today details without the passcode; `ParentGate.runEditing` now gates them (the details sheet closes first so the passcode can show). A habit skill earned shows a "Skill Learned" toast with a haptic and a VoiceOver announcement (`SkillProgress.Snapshot.newlyEarned`, checked by Today on appear and when the app becomes active). A "Ready for Teen/Adult" card on Today links to Your Path, and can be dismissed once per stage.
- [x] **Accessibility.** The passcode keypad scales with Dynamic Type (`@ScaledMetric`, capped so 3 keys fit) and scrolls; the stage ladder stacks into a list at large text sizes.
- [x] **Demo mode (Debug only).** `-demoData` now also sets up Maya (teen, 3 quiz skills, grown-up contact "Mom", passcode 1234); add `-stage kid` to show her as a kid. `-demoFamily` turns the phone into her parent's: demo data goes through the real publish → loopback → apply path into a followed store, and a sample "Maya: Urgent Low" notification fires 10 s after launch. The parent screen says "Sample data for a demo".
- [x] **App icon.** The `AppIcon` set was empty, which would block any upload. A green field with a cream glucose drop growing a sprout (grows with you), light/dark/tinted at 1024 px with no alpha. Drawn by `scripts/make-app-icon.swift`.
- [x] **Screenshots.** `ScreenshotUITests` (skipped unless `SCREENSHOTS=1`) + `scripts/screenshots.sh`: status bar set to 9:41, a wait out of first-boot banners, and export to `docs/screenshots/iPhone-17-Pro-Max/` and `docs/screenshots/iPad-Pro-13-inch-M4/`: Today, Your Path, Quiz, Kid Today, Get Help, Trends, What Family Sees, Parent's phone.
- [x] **Turning iCloud on is one command.** `sh scripts/enable-icloud.sh`: switches the app target to `DiabetesCare-CloudKit.entitlements`, merges `Config/DiabetesCare-iCloud-Info.plist` (`CKSharingSupported`, remote-notification background mode) and sets `FamilyCloud.containerID`. It's idempotent and undone with `git checkout`. Checked on a copy of the repo: it builds (unsigned) and the merged Info.plist has both keys. Signing and running need the paid team.
- [ ] **After enrollment:** `sh scripts/enable-icloud.sh` → pick the team → the two-device test in `docs/release-checklist.md`.

### Later (not app work)
- [ ] Demo video (under the CAC cap): mom's story → Kid → skill unlock → Teen → What Family Sees / parent alert (`-demoFamily`) → privacy, free → next steps. Say plainly in the video if iCloud sharing isn't live yet.
- [ ] README with screenshots from `docs/screenshots/`.
- [ ] Interviews with families or teens with T1D; TestFlight once enrolled.
- [ ] Clinician review of the quiz questions, glossary and guides.
- [ ] A caregiver acknowledging a help request back to the kid (needs a write path); Android; doctor sharing beyond the PDF.

### Testing Phase 5
- Unit (`GrowthTests`, `FamilySharingTests`): stage × feature table, skill unlocks, readiness, quizzes well-formed, settings persistence, passcode (hash only, lockout, relaunch), gate, habit rules, publish → fetch → apply round trip with edit and delete, 30-day window, photos/notes stripping, diff, caregiver alerts per stage, help requests once, stale data for kids only.
- Unit (`FamilyRecordCodecTests`): CloudKit records round trip for every kind, naming, batching ≤ 350 combined, bad records skipped. `GrowthTests` also covers the grown-up contact (number cleanup, tel/sms links, gate) and `runEditing`.
- UI (`GrowthWeek3UITests`): a kid sets the grown-up contact (passcode) and Get Help shows Call/Text; `-demoFamily` shows Maya on a parent's phone.
- UI (`GrowthFlowUITests`): setup as kid sets the passcode and simplifies Today; kid needs the passcode for ranges (wrong code rejected); two quizzes open insulin logging; See What Family Sees shows shared readings (`-demoData`); caregiver phone shows the Family tab.
- Launch arguments: `-stage kid|teen` (grown-up passcode 1234, locked), `-resetSetup` (shows the setup screen), `-demoData` (Maya, teen), `-demoFamily` (parent's phone).
- The template launch test rotates the simulator to landscape; its tearDown now puts it back, which was breaking later tests in full runs. `HealthImportUITests` drives the Health app and is sometimes flaky in a full run; rerun it alone. Plain `-uiTesting` starts as Adult with no passcode, so older tests are unchanged.

## Phase 6 — Alive and more functional (done 2026-10-13)

33 features from the idea list in `~/.claude/plans/` (none needs dosing logic; safety info is never gated). All unit tests (`AliveFeatureTests`) and UI tests (`AliveFlowUITests`) pass on iPhone 17 / iOS 26.

### Outside the app
- [x] **Widgets** (`DiabetesCareWidgets/`, new extension target): Glucose (small, medium with a 3 h sparkline, Lock Screen circular/rectangular/inline) and "Feeling Off?" (kid) whose **+15 g button** logs fast sugar without opening the app. Both read `GlanceSnapshot` (`Shared/Glance.swift`) from the App Group `group.com.AngadKumar16.DiabetesCare`; `Services/GlanceWriter.swift` rewrites it after every store save (debounced) and reloads widgets.
- [x] **Live Activity** for treating a low (`Shared/LowTreatmentAttributes.swift`, `Services/LowTreatmentService.swift`): 15-minute recheck countdown on the Lock Screen and Dynamic Island, updated with the next reading, ends when back above Low. Started from Today, Get Help, the widget, Siri or the watch.
- [x] **Siri / Shortcuts** (`App/Intents/`): Check My Glucose (spoken + snippet), Log Carbs, Log Glucose, Log Insulin (confirms; refuses at Kid, same rule as `CareStage`), Get Help, Show My Week, Explain a Term (`GlossaryTermEntity`, indexed). `LogFastSugarIntent` and `OpenRouteIntent` live in `Shared/SharedIntents.swift` so the widget can name them; their work runs in the app (`#if !WIDGET_EXTENSION`).
- [x] **Controls**: Log Carbs, Log Glucose, Get Help for Control Center / Lock Screen / Action button.
- [x] **Spotlight** (`Services/SpotlightIndexer.swift`): glossary terms and guides, never the log.
- [x] **Apple Watch** (`DiabetesCareWatch/`, `DiabetesCareWatchWidgets/`): glance with sparkline and recheck timer, log fast sugar / glucose / carbs with the Digital Crown, low steps; complications. Snapshot over WatchConnectivity (`Services/WatchBridge.swift`). Embedded in the iPhone app (`scripts/embed-watch.sh`, run 2026-10-13 after installing the watchOS 26 simulator runtime, which the scheme now needs). Watch icon in `DiabetesCareWatch/Assets.xcassets`. Launches on an Apple Watch Series 11 simulator; phone ↔ watch messaging needs a paired simulator or devices to check.
- `App/AppRouter.swift`: one place for "open this" from widgets (`diabetescare://` URLs), notifications (`userInfo["route"]`), Spotlight, Siri and controls.

### Feels alive
- [x] Hero reading: number rolls, zone color animates, trend arrow bounces, a halo breathes while fresh and the color drains as it ages. Reduce Motion respected.
- [x] Today: next-up line (recheck countdown, next reminder, site due, streak), streak chips (days logging, days without an urgent low, sites on time; a broken streak reads "Fresh start today"), last-night card (morning), day story (yesterday until 5 p.m., then today). Math in `Models/Domain/Story.swift`, fetches in `Services/StoryService.swift`.
- [x] Milestone celebrations (3/7/14/30… days) with falling leaves (`Views/Alive/Celebration.swift`), once per milestone.
- [x] **The plant** (`Views/Alive/SproutView.swift`): seed → bloom from skills, guide stickers and streaks; on Your Path and on a kid's/teen's Today.
- [x] TipKit hints (`Views/Alive/Tips.swift`); hidden in UI tests.
- [x] Weekly recap (`Views/Alive/WeeklyRecapView.swift`): time in range vs last week, steadiest day, days logged, each day in a sentence, shareable image; Sunday 6 p.m. notification.
- [x] Undo toast after logging and deleting (`Views/Alive/Toast.swift`), with the haptic language: success saved, warning for a low/high or high ketones, light tap for delete/undo. Off in UI tests unless `-toasts`.
- [x] Stage palette (`Views/Alive/StagePalette.swift`): brighter green and a warm wash for a kid, teal for a teen, calm for an adult.
- [x] Alternate app icons (Garden, Sunrise, Ocean, Berry, Midnight): `swift scripts/make-app-icon.swift --alternates DiabetesCare/Resources/Assets.xcassets`; Settings › Everyday › App Icon.

### Logging
- [x] **Carb lookup** (`Models/Food/`, `Views/Food/`): 5,371 USDA FNDDS foods with household portions bundled as `Resources/Foods.json` (780 KB, built by `scripts/make-food-db.py`), recent and "My Foods", add your own. Optional **barcode scan** (VisionKit) → Open Food Facts, off until turned on; only the barcode is sent. Picks add up in Add Carbs.
- [x] Meal photos on carb entries (add, edit, thumbnail in Log; never shared with family).
- [x] **Core Data model version 2** (`SucroDataModel 2`, lightweight migration): `KetoneReading` and `ContextTag`. Both are in backups (optional fields, so older backups still read) and never shared with family.
- [x] Ketones: blood (mmol/L) or urine strip, level explained (`KetoneZone`), Log filter, timeline. Log filters became scrolling chips (seven kinds).
- [x] Day tags on Today (sick, stressed, sports, period, party, travel); **Sick** shows a sick-day checklist with the latest ketone check.
- [x] Supplies, open-insulin expiry and doctor questions (`Services/KitStore.swift`, `Views/Kit/`): counts with reorder reminders, site changes use up sets/pods/reservoirs, expiry reminder at 9 a.m. on the day, questions added to the PDF report. In backups.

### Trends
- [x] Your Typical Day (AGP: median, 25–75 %, 5–95 % by half hour; `Models/Domain/AGP.swift`), also a PDF report page.
- [x] After Meals: rise after each meal and by food (`MealImpact`).
- [x] Chart scrub lists meals/doses within 45 minutes; event marks along the top.
- [x] Your Days: glucose on tagged days vs the rest (`TagInsights`).
- [x] Activity & Sleep (opt-in Health reads: steps, workouts, sleep, menstrual flow; `Services/HealthContextReader.swift`) with findings like lower nights after workouts.

### Family and growth
- [x] **Help replies**: a parent answers "I need help" with On my way / Calling you / Got it; the kid's Get Help shows it and a notification arrives. `FamilyTransport.sendReply/fetchReplies`, `Reply` records in the same zone. The CloudKit share now offers read-write (only replies are written; the app never edits entries from a follower). Loopback-tested; iCloud path untested until enrollment.
- [x] School & sitter card (PDF): low signs, rule of 15, emergency, ranges, grown-up contact, notes.
- [x] Guide stickers on Your Path.
- [x] Doctor visit questions in the report.

### Not done / limits
- Day story: Apple's on-device model (Foundation Models) rewords the template warmly for the stage (`Services/StoryWriter.swift`), only where Apple Intelligence is available; the reworded text is kept only if every number survives and nothing reads like advice (`isFaithful`, tested), otherwise the template shows. Toggle: Settings › Everyday › Friendlier Day Stories; off in UI tests.
- iCloud help replies untested on two devices (needs the paid account).

## Key files

Paths are relative to `DiabetesCare/`.


- Entry: `App/DiabetesCareApp.swift` → `Views/Navigation/RootView.swift` → `MainTabView.swift`
- Data: `Core/Persistence.swift`, `Models/CoreData/SucroDataModel.xcdatamodeld`, `Services/DataService.swift`
- Math: `Utilities/GlucoseCalculator.swift`
- Alerts: `Services/AlertService.swift`, `Services/NotificationService.swift`, `Services/ReminderService.swift`, `Models/Domain/GlucoseThresholds.swift`
- Devices: `Views/Secondary/DevicesView.swift`
- Glossary: `Models/Glossary/Glossary.swift` (load + search), `Resources/Glossary.json`, `Views/Learn/`
- Forms: `Views/Components/EntryForm.swift`, `Views/Components/EntryFields.swift`, `Views/Components/EditViews/EntryEditorView.swift`
- Health: `Core/HealthKitManager.swift` (writes, permissions), `Services/HealthGlucoseImporter.swift` (observer + anchored query), `Services/HealthGlucoseStore.swift` (Core Data batch writes), `Services/HealthGlucoseImport.swift` (pure dedupe/trend)
- Settings: `Services/SettingsStore.swift`
- Backup: `Services/BackupArchive.swift` (format + Core Data), `Services/BackupService.swift` (daily file, restore), `Services/BackupDocument.swift`
- Sites: `Views/Components/BodyMap.swift`, `Views/Components/SitePicker.swift`, `Views/Secondary/SiteHistoryView.swift`, `Models/Domain/SiteRotation.swift`
- Logging: `Utilities/Log.swift`
- Stages and skills: `Models/Domain/CareStage.swift`, `Models/Domain/Skill.swift`, `Services/ParentLock.swift`, `Services/SkillProgress.swift`, `Views/Growth/` (setup, passcode, gate, path, quiz, kid help)
- Family sharing: `Services/Family/` (models, diff, store, record codec, transports, alert policy, `FamilyService`), `Views/Family/`, `App/AppDelegate.swift`, `DiabetesCare-CloudKit.entitlements`, `Config/DiabetesCare-iCloud-Info.plist`
- Scripts: `scripts/enable-icloud.sh`, `scripts/screenshots.sh`, `scripts/make-app-icon.swift` (`--alternates`), `scripts/make-food-db.py`, `scripts/embed-watch.sh`
- Ship docs: `docs/`
- Outside the app: `Shared/` (snapshot, Live Activity attributes, shared intents, watch messages; compiled into app, widgets and watch), `DiabetesCareWidgets/`, `DiabetesCareWatch/`, `DiabetesCareWatchWidgets/`, `App/AppRouter.swift`, `App/Intents/`, `Services/GlanceWriter.swift`, `Services/WatchBridge.swift`, `Services/LowTreatmentService.swift`, `Services/SpotlightIndexer.swift`
- Alive and everyday: `Views/Alive/`, `Views/Kit/`, `Views/Food/`, `Views/Trends/`, `Models/Domain/Story.swift`, `Models/Domain/AGP.swift`, `Models/Food/`, `Services/StoryService.swift`, `Services/KitStore.swift`, `Services/HealthContextReader.swift`
