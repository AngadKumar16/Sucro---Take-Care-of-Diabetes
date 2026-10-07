# DiabetesCare — Planning Guide

Status audit of the codebase (repo folder still named `Sucro - Take Care of Diabetes`), written 2026-10-07 for handoff to Claude Code.
Based on reading the source. **The app was not built or run for this audit** — step 0 below is to confirm it compiles and tests pass.

## Snapshot

- iOS 26, SwiftUI + Core Data (`SucroDataModel`), Swift 5, Xcode 16 synchronized folders (new files in the source tree are added to the target automatically).
- ~9.1k lines across 76 Swift files. Last commit 2026-06-20.
- Architecture: `Views/` → `ViewModels/` (ObservableObject) → `Services/` singletons (`DataService`, `NotificationService`, ...) → Core Data.
- Navigation: 3 main tabs (Home, Log, Monitor) + a "More" sheet holding a second TabView (Insights, Reports, Devices, Settings).
- Rebrand done today: home-screen name is **DiabetesCare** (`INFOPLIST_KEY_CFBundleDisplayName`), and the Health/Bluetooth permission strings say DiabetesCare. Target, scheme, folders, bundle ID (`com.AngadKumar16.Sucro---Take-Care-of-Diabetes`) and repo name still say Sucro.
- `Resources/MedicalTerms.json` copied in from the old DiabetesCare prototype: 216 glossary terms (`name`, `description`, `broadCategory`, `narrowCategory`, `isPremium`, `contentURL`). **Not wired to any view yet.** All `contentURL`s are fake (`yourserver.com`).

## What works

| Area | Status |
|---|---|
| Manual logging: glucose, carbs, insulin, activity, site change | Works. Saves to Core Data and mirrors to Apple Health (write-only). mmol/L input is converted and stored as mg/dL. |
| Edit / delete / add notes to timeline events | Works (`DraftOperation`, edit views, `DataService.delete/addNote`). |
| Home dashboard: latest glucose, today totals, IOB, mini timeline, recent cards, site snapshot, quick actions, meal/bolus presets | Works off local data. |
| Monitor tab: readings by date range, average, min–max | Works. |
| Insights: stats (avg, SD, CV, TIR), weekday patterns, carb→spike correlations | Computes from real data (see bugs below). |
| Reports + export (PDF / PNG / CSV via share sheet) | Works; no-data case handled. |
| Settings: unit, target range, notifications, dark mode, auto backup, export, clear all data | Persisted in UserDefaults via `SettingsStore`; dark mode, unit and target range drive the UI. |
| Site-change reminders | Local notification scheduled on site change (rotation days per body site). |
| Auto backup | Daily CSV of glucose readings to app `Documents/Backups` on launch. |
| Tests | Swift Testing unit tests (settings persistence, unit conversion, Core Data persistence, clear-all, date-range fetch, draft edit, report stats) + XCUITests for main flows (`-uiTesting` launch arg skips HealthKit prompt). |

## What doesn't work / is fake

### Not real (UI exists, nothing behind it)
1. **CGM connection.** `DeviceMonitorService` creates a `CBCentralManager` but never scans, never discovers services, and all peripheral delegate methods are empty. No glucose ever arrives from a device. Side effect: Bluetooth permission prompt fires at launch for no reason.
2. **Devices tab.** Hard-coded catalog (Dexcom G6, Omnipod 5, Libre 3, t:slim) with fake battery levels. "Connect" only appends the name to a settings array.
3. **Devices toggles** `autoSyncEnabled`, `backgroundMonitoringEnabled`, `lowBatteryAlertsEnabled` are saved but never read anywhere.
4. **Apple Health import.** `HealthKitManager.fetchGlucoseReadings` exists but is never called — the app only writes to Health, never reads. (This is the cheapest real path to CGM data: Dexcom/Libre apps write to Health.)
5. **"Battery" on Home** is the *phone's* battery (`UIDevice`), not the CGM/pump.
6. **Glossary** (`MedicalTerms.json`) has no UI.
7. `BodyMapView` taps just `print`. `NoteInputView` preview prints (real usage is fine).

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
13. **Backup** only covers glucose (no carbs/insulin/activity/sites) and stays on-device (lost if app is deleted). No restore.
14. **CI is broken.** `.github/workflows/swift.yml` runs `swift build` / `swift test`, but there's no `Package.swift`. Needs `xcodebuild test -scheme ... -destination 'platform=iOS Simulator,...'`.
15. Dead code: `App/ContentView.swift` (Xcode template, unused). Hundreds of `print` error handlers — swallow errors silently from the user's perspective.
16. `.windsurf/plans/home_page_feature_gap_analysis.md` is stale (says ~15% done; most of that list is now built).

## Plan (suggested order)

### Phase 0 — Baseline (do first)
- [ ] Open in Xcode, build for an iOS 26 simulator, run unit + UI tests. Record failures.
- [ ] Fix CI to use `xcodebuild` (bug 14).
- [ ] Delete `ContentView.swift`, the duplicate `MonitorViewModel` (bug 11), and the stale windsurf plan.

### Phase 1 — Correctness & safety (before anyone else uses it)
- [ ] Alert dedupe: one notification per crossing event, with cooldown; stable identifiers (bug 3).
- [ ] Separate "CGM data stale" from "phone offline"; base staleness on time since last reading (bugs 1, 2).
- [ ] Explicit threshold settings and one source of truth for low/high/urgent (bug 9).
- [ ] Fix trend calc: sort by timestamp, rate in mg/dL/min, only compute when readings are ≤15 min apart (bugs 5, 6).
- [ ] Single IOB implementation + unit tests; label it "estimate" in UI (bug 8).
- [ ] Merge reminder services (bug 10).
- [ ] Replace `fatalError` in persistence with a recoverable error screen (bug 12).
- [ ] In-app disclaimer: not a medical device, not for dosing decisions.

### Phase 2 — Real data in
- [ ] Read glucose from Apple Health (`HKObserverQuery` + anchored query, background delivery), dedupe against Health samples the app itself wrote. Set `trend` from rate of change.
- [ ] Rework Devices tab around what's real: "Apple Health source: connected / last reading X min ago". Remove fake catalog and unused toggles (or implement them).
- [ ] Only init `CBCentralManager` when the user opts into a device flow, or remove BLE until there is a real integration. (Direct Dexcom/Libre BLE is proprietary; Dexcom has a web API — investigate later.)

### Phase 3 — Features
- [ ] Glossary/Learn screen from `MedicalTerms.json` (search, category filter). Drop or fix `contentURL`s; decide what `isPremium` means.
- [ ] Full backup/restore (all entities, JSON) to Files/iCloud Drive.
- [ ] Body map: make taps select a site; rotation history.

### Phase 4 — Ship
- [ ] Full rename if desired: target/scheme/folders → DiabetesCare; bundle ID must be final **before** first App Store upload.
- [ ] Check App Store name availability ("DiabetesCare" is generic).
- [ ] Request critical-alerts entitlement from Apple (bug 4), privacy policy, HealthKit review notes, App Privacy labels.

## Key files

- Entry: `App/Sucro___Take_Care_of_DiabetesApp.swift` → `Views/AppNavigationView.swift`
- Data: `Core/Persistence.swift`, `Models/CoreData/SucroDataModel.xcdatamodeld`, `Services/DataService.swift`
- Math: `Utilities/GlucoseCalculator.swift`
- Alerts: `Services/AlertService.swift`, `Services/NotificationService.swift`, `Services/RealReminderService.swift`
- Devices: `Services/DeviceMonitorService.swift`, `Views/Secondary/DevicesView.swift`
- Health: `Core/HealthKitManager.swift`
- Settings: `Services/SettingsStore.swift`
