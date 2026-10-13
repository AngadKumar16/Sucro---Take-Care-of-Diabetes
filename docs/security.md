# Security

Health data about a child is some of the most sensitive data there is. DiabetesCare's approach is to hold as little as possible in as few places as possible, and lock down the few paths it does use.

## Nothing to breach
- **No server, no account, no password database.** There is nothing of ours to hack, and no data of yours on it. The app has no analytics, crash-reporting, advertising or tracking SDKs (`PrivacyInfo.xcprivacy`: `NSPrivacyTracking` false).
- **Stays on the phone.** The log lives in the app's private Core Data store, inside the iOS sandbox, encrypted at rest by iOS Data Protection with the device passcode.

## Family sharing
- **End-to-end encrypted.** Every reading, carb, insulin dose, note, profile and help request goes into CloudKit `encryptedValues` (`Services/Family/FamilyRecordCodec.swift`). The keys stay in the users' iCloud Keychains, so only the invited family can decrypt it: not us, not Apple.
- **Private and read-only.** A zone-wide `CKShare` with `publicPermission = .none`: no link sharing, only people invited by name. Family can read, never change the log.
- **Least data.** Only the last 30 days go out; never photos; notes only at the Kid stage (`FamilyDiff`).
- **Off by default**, and turning it off on a kid's or teen's phone needs the grown-up passcode. **See What Family Sees** shows exactly what is shared.

## Grown-up passcode
- Stored only as a **salted SHA-256 hash** (16 random bytes from `SecRandomCopyBytes`) in the **Keychain**, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: never in plain text, never in backups, never leaves the device (`Services/ParentLock.swift`).
- **5 wrong tries → 30 s lockout.** Unlocks for 5 minutes and relocks when the app goes to the background.
- All permission rules live in one function, `CareStage.access(to:completed:)`, and every view goes through one gate (`ParentGate`). One place to check, no back door in a single screen. Unit tests cover every stage × feature pair.
- Honest limit: four digits on the kid's own phone is a speed bump for a kid, not protection against an attacker with the unlocked phone. The device passcode is what protects the data.

## Network
- Only two network paths exist, both optional and off until the user turns them on: family sharing (above) and barcode lookup.
- Barcode lookup sends **only the barcode digits** over HTTPS to Open Food Facts. Input is filtered to 6–14 digits before it goes into a URL, so nothing else can be injected. The camera image never leaves the phone.
- HTTPS only (App Transport Security is not relaxed anywhere).

## Things the user controls
- Exports (PDF report, CSV, Back Up Now) only happen when the user taps them and picks where the file goes.
- Daily backups are saved in the app's Documents/Backups so the user can see them in Files; they are protected by the phone's encryption like the rest of the app's files.
- Apple Health access is asked per data type and can be revoked in Settings at any time.

## Testing
- 147 unit tests, including the passcode (only a hash is stored, lockout, relaunch), the permission table, and a CloudKit record round trip with batching limits.
- 60 UI tests drive the gated flows as a kid, a teen and a parent.
