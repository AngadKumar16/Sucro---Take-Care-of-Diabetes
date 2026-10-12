# App Privacy answers (App Store Connect › App Privacy)

**Do you or your third-party partners collect data from this app?** → **No, we do not collect data from this app.**

Why that's accurate (Apple's definition: "collect" means sent off the device in a way you or partners can access):
- All entries, settings, photos and backups stay on the device, or go wherever the user explicitly sends a file.
- HealthKit data is read and written on device only.
- There are no analytics, crash-reporting, advertising or networking SDKs, and the app makes no network requests.

The result is **"Data Not Collected."**

Revisit this if any of the following is added: crash reporting (for example Sentry or Crashlytics), analytics, an account or sync server, a Dexcom web API integration, or support uploads.

Privacy manifest: `Sucro - Take Care of Diabetes/PrivacyInfo.xcprivacy`. It declares no tracking, no collected data, and one required-reason API: UserDefaults with reason CA92.1, which covers app-only preferences.
