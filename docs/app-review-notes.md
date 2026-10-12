# App Review Notes (paste into App Store Connect › App Review Information)

DiabetesCare is a diabetes logbook. **It is not a medical device and gives no dosing advice.** A safety notice must be accepted before first use, and it can be read again in Settings › Safety Information.

## HealthKit
- **Read:** Blood Glucose only. Readings that CGM apps (Dexcom, Libre and others) save to Apple Health show up in the app's Log and Trends. The app uses an observer query with background delivery so that low and high glucose alerts are timely.
- **Write:** Blood Glucose, Dietary Carbohydrates, Insulin Delivery, Workouts and Active Energy, from the entries the user logs by hand. Samples the app wrote itself are skipped when reading, so nothing is counted twice.
- Health data stays on the device. There is no server, no account and no analytics.

## Testing without a CGM
1. Accept the safety notice and allow Apple Health.
2. On Today, tap the reading card and log a glucose value, for example 65 mg/dL. A low-glucose card with treatment steps appears.
3. Alternatively, add a Blood Glucose sample in the Health app (Browse › Blood Glucose › Add Data). It appears in Log within a few seconds, tagged "Apple Health". Settings › Devices & Apple Health shows "Receiving".
4. Settings › Back Up Now / Restore from Backup shows the JSON backup.

## Notifications
Time-sensitive notifications are used for glucose alerts (crossing below Low, below Urgent Low, or above Urgent High). Each alert fires once per crossing, with a 30-minute cooldown. Reminders cover site changes and a glucose check 2 hours after a rapid-acting dose.

## Background modes
HealthKit background delivery only.
