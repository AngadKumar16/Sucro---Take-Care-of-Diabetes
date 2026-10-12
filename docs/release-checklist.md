# Release checklist

Steps that need a person, an Apple account or a decision. Code-side prep is done.

## Before the first upload
- [ ] **Name.** Search App Store Connect (My Apps › + › New App) for "DiabetesCare". It is generic and may be taken. Fallbacks: "DiabetesCare Log", "Sucro: Diabetes Log". The home-screen name is `INFOPLIST_KEY_CFBundleDisplayName`.
- [ ] **Bundle ID** `com.AngadKumar16.DiabetesCare`: register it in Certificates, Identifiers & Profiles with the HealthKit and Time Sensitive Notifications capabilities. It can't change after the first upload.
- [ ] **Support address.** `AppInfo.supportEmail` is `support@sucroapp.com`. Confirm the domain exists, or change it.
- [ ] **Privacy policy.** Host `docs/privacy-policy.md` at a public URL (GitHub Pages works) and enter the URL in App Store Connect.
- [ ] **App Privacy.** Answer the questions as in `docs/app-privacy-labels.md` ("Data Not Collected").
- [ ] **Review notes.** Paste `docs/app-review-notes.md`.
- [ ] **Category.** Medical or Health & Fitness. Medical apps get extra review scrutiny; the disclaimer and "not for dosing" wording support either.
- [ ] **Clinician review** of `Resources/Glossary.json`, the Learn guides, and the low/ketone advice text.
- [ ] **Screenshots** for 6.9" iPhone and 13" iPad (Today, Log, Trends, Learn, Site History). Run with `-demoData` in a Debug build.

## Apple requests
- [ ] **Critical Alerts entitlement.** Submit the text in `docs/critical-alerts-request.md`. Approval takes weeks; ship without it and add it later.

## Later
- [ ] Translations: add languages to `Resources/Localizable.xcstrings`. For the Learn tab, add `<lang>.lproj/Glossary.json` (the loader is already locale-aware).
- [ ] Dexcom web API (direct CGM data without Apple Health), which needs Dexcom developer approval.
