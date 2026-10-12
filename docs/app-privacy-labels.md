# App Privacy answers (App Store Connect › App Privacy)

**Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app.**

Why that's accurate (Apple's definition: "collect" means sent off the device in a way you or partners can access):
- All entries, settings, photos and backups stay on the device, or go wherever the user explicitly sends a file.
- HealthKit data is read and written on device only.
- There are no analytics, crash-reporting, advertising or networking SDKs. The only network use is optional Family sharing through the user's own iCloud (CloudKit private and shared databases). Data in a user's iCloud that the developer can't access isn't "collected" under Apple's definition.

The result is **"Data Not Collected."**

Revisit this if any of the following is added: crash reporting (for example Sentry or Crashlytics), analytics, an account or sync server of our own, CloudKit's **public** database, a Dexcom web API integration, or support uploads.

Privacy manifest: `DiabetesCare/PrivacyInfo.xcprivacy`. It declares no tracking, no collected data, and one required-reason API: UserDefaults with reason CA92.1, which covers app-only preferences.
