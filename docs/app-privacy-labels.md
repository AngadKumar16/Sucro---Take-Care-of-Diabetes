# App Privacy answers (App Store Connect › App Privacy)

**Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app.**

Why that's accurate (Apple's definition: "collect" means sent off the device in a way you or partners can access):
- All entries, settings, photos and backups stay on the device, or go wherever the user explicitly sends a file.
- HealthKit data is read and written on device only.
- There are no analytics, crash-reporting, advertising or networking SDKs. Network use: optional Family sharing through the user's own iCloud (CloudKit private and shared databases), and the optional barcode lookup, which sends only a product barcode to Open Food Facts (a third party) and receives nutrition facts. A product barcode isn't data about the user, isn't linked to them, and neither we nor Open Food Facts can tie it to a person, so it isn't "collected" user data. Data in a user's iCloud that the developer can't access isn't "collected" under Apple's definition.
- Widgets, the Live Activity, Siri and the watch app read a summary from an App Group container on the device, or over Watch Connectivity; nothing leaves the user's devices.

The result is **"Data Not Collected."**

Revisit this if any of the following is added: crash reporting (for example Sentry or Crashlytics), analytics, an account or sync server of our own, CloudKit's **public** database, a Dexcom web API integration, or support uploads.

Privacy manifests: `DiabetesCare/PrivacyInfo.xcprivacy` (no tracking, no collected data, UserDefaults with reasons CA92.1 for app-only preferences and 1C8F.1 for the App Group shared with the widgets), plus one each in `DiabetesCareWidgets/`, `DiabetesCareWatch/` and `DiabetesCareWatchWidgets/` (UserDefaults, 1C8F.1).
