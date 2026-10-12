# Critical Alerts entitlement request

Request at: https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/

**App:** DiabetesCare (bundle ID `com.AngadKumar16.DiabetesCare`)

**Why the app needs Critical Alerts**

DiabetesCare reads continuous glucose monitor (CGM) readings from Apple Health and alerts people with diabetes when their blood glucose drops dangerously low (below a threshold they set, 55 mg/dL by default).

Severe hypoglycemia can cause confusion, seizures, loss of consciousness and death. It often happens during sleep. Many people keep their phone on silent or in a Focus mode at night, so the alert has to sound even then.

**How we limit use**
- Critical alerts are only for **urgent low** glucose. Ordinary lows, highs and reminders use time-sensitive or normal notifications.
- Each alert is sent once per crossing below the threshold, with a 30-minute cooldown, and never for readings older than 15 minutes.
- The user can turn alerts off in Settings, and the system's per-app Critical Alerts switch applies.
- The app is free of advertising and tracking. Alerts never contain marketing.

**Once approved:** add `com.apple.developer.usernotifications.critical-alerts` to the entitlements. Use `.critical` interruption level with `UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)` for urgent lows only, in `NotificationService`. Request `.criticalAlert` in the authorization options.
