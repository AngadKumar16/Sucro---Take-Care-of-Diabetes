# DiabetesCare

A diabetes log for iPhone that grows with you.

My mom has type 1 diabetes. Watching her manage it every day made us think about kids who get diagnosed young: at first a parent does everything, and years later that kid has to do it all alone. Most diabetes apps are built for one adult. DiabetesCare is built for the years in between.

Made by Angad Kumar and Abhay for the 2026 Congressional App Challenge.

<p>
  <img src="docs/screenshots/iPhone-17-Pro-Max/04-KidToday.png" width="200" alt="Kid's Today screen">
  <img src="docs/screenshots/iPhone-17-Pro-Max/02-YourPath.png" width="200" alt="Your Path: Kid to Teen to Adult">
  <img src="docs/screenshots/iPhone-17-Pro-Max/03-Quiz.png" width="200" alt="Skill quiz">
  <img src="docs/screenshots/iPhone-17-Pro-Max/07-ParentPhone.png" width="200" alt="Parent's phone">
</p>

## How it grows

| | Kid | Teen | Adult |
|---|---|---|---|
| Who's in charge | A grown-up | The teen, with a parent watching | You |
| Logging insulin | Needs the grown-up passcode (until skills unlock it) | Open | Open |
| Changing ranges, clearing data | Passcode | Passcode | Open |
| Family alerts | Lows, highs, missing data, help requests | Urgent only | Urgent low only |

Kids move up by learning. Your Path has six skills: four short quizzes tied to the Learn guides (Know Your Ranges, Treat a Low, Read the Numbers, Time in Range) and two habits the app notices in the log (logging 7 days in a row, treating a low and checking again). Skills unlock things, and when a kid has them all a grown-up approves the move to Teen. Safety info like the low steps and Get Help is never locked.

## What it does

### Logging

Glucose, carbs, insulin, ketones, activity and site changes. Each one has a tool that looks like the real thing: a kitchen scale for carbs, a pen you dial for insulin, a body map for sites. Carb lookup covers 5,371 foods from the USDA's FNDDS database with household portions, plus an optional barcode scanner. CGM readings come in from Apple Health.

### Today

The latest reading with its trend arrow, active insulin (an estimate), what's coming up next, streaks, a short story of your day, and a plant that grows as you learn. You can tag a day as sick, stressed, sports, travel and more. A sick day opens a checklist with your last ketone check.

### Help when you're low

A kid taps Get Help: find a grown-up, have 15 g of fast sugar, and a 15-minute recheck timer starts on the Lock Screen and in the Dynamic Island. Call and Text buttons reach their grown-up with the latest reading.

### Trends

Time in range, your typical day (an AGP chart), how much you rise after meals and after specific foods, tagged days compared with ordinary ones, and activity and sleep from Health. A weekly recap shows up on Sunday evening, and a PDF report for the doctor includes the questions you saved for the visit.

### Outside the app

Home and Lock Screen widgets, including a "Feeling off?" widget that logs 15 g of sugar in one tap. Siri and Shortcuts, Control Center buttons, Spotlight search for glossary terms, and an Apple Watch app with complications.

### Family

The person with diabetes shares read-only with their family. A parent's phone shows their readings and gets alerts tuned to the stage: lows and help requests for a kid, only urgent ones for a teen. A parent answers a help request with "On my way" in one tap.

### Everyday things

Supply counts with reorder reminders, insulin expiry reminders, a school and sitter card as a PDF, a 134-term glossary with plain-language guides, daily backups you can restore, alternate app icons, and Dynamic Type throughout.

## Privacy

Your health data is never sold, never used for ads and never sent to us. There is no account and no server. It stays on your phone, and the only people who ever see it are the family members you invite. Family sharing is end-to-end encrypted in your own iCloud (CloudKit `encryptedValues`), so not even Apple can read it. App Store privacy label: Data Not Collected. See [docs/privacy-policy.md](docs/privacy-policy.md).

## Security

- No server, no account, no password database: nothing of ours to breach. No analytics, ads or tracking SDKs.
- Data on the phone is encrypted at rest by iOS. Family sharing is end-to-end encrypted, private (`publicPermission = .none`) and read-only.
- The grown-up passcode is kept only as a salted SHA-256 hash in the Keychain (this device only), with a lockout after 5 wrong tries.
- Every permission rule lives in one function, `CareStage.access(to:completed:)`, behind one gate, covered by unit tests.
- Only two optional network paths, both HTTPS: family sharing and a barcode lookup that sends nothing but the barcode digits.

More detail: [docs/security.md](docs/security.md).

**Not for dosing.** DiabetesCare is a log and a learning tool. It doesn't calculate insulin doses or replace advice from your care team.

## Ready to launch

Family sharing runs on iCloud (CloudKit) and is end-to-end encrypted. The whole path is built: publishing changes from the teen's phone, the CloudKit record layout, share invitations, stage-based alerts on the parent's phone, and help replies. Unit tests run every step through a stand-in transport, and **See What Family Sees** in Settings › Family shows exactly what a parent gets. It switches on with one script (`sh scripts/enable-icloud.sh`) when the app goes to the App Store. The steps are in [docs/release-checklist.md](docs/release-checklist.md).

## What's next

For the app:

- Put it on the App Store and TestFlight with family sharing on, and test it with families and teens who live with type 1.
- Have a diabetes educator review the guides, quizzes and glossary.
- Spanish first (the glossary already loads a file per language), then more languages.
- Direct CGM connections, a caregiver dashboard on iPad, and an Android version.
- Modes for type 2 and gestational diabetes. Stages and skills fit any condition where someone slowly takes over their own care.

For reach:

- Schools. The school card is already in the app; a view for school nurses comes next.
- Clinics. A pediatric diabetes team could hand DiabetesCare to a family on the day their kid is diagnosed, and the PDF report brings the same numbers to every visit.
- Diabetes camps and groups like Breakthrough T1D, where kids already practice doing things on their own.
- It stays free. There's no server, so one more family costs us nothing.
- The code is public on GitHub, so other developers can build on the stage rules and the family sharing.

A kid diagnosed at six will be managing diabetes alone at eighteen. We want the app to be there for all twelve of those years.

## Build and run

Needs Xcode 26 and the iOS 26 and watchOS 26 simulator runtimes (`xcodebuild -downloadPlatform watchOS`).

```sh
open DiabetesCare.xcodeproj   # scheme DiabetesCare, run on an iPhone simulator
```

Tests:

```sh
xcodebuild test -project DiabetesCare.xcodeproj -scheme DiabetesCare \
  -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO
```

Demo launch arguments (Debug builds; Edit Scheme › Run › Arguments):

| Argument | What it does |
|---|---|
| `-demoData` | Sample data for Maya, a teen, with a few skills done |
| `-demoData -stage kid` | Maya as a kid (grown-up passcode 1234) |
| `-demoFamily` | A parent's phone following Maya, with a sample urgent-low alert |
| `-resetSetup` | Show the "Who's using DiabetesCare?" setup again |

## Built with

SwiftUI, Core Data, HealthKit, WidgetKit, ActivityKit, App Intents, WatchKit/WatchConnectivity, CloudKit (family sharing), TipKit, VisionKit, Swift Testing and XCUITest.

Project notes and history: [PLANNING.md](PLANNING.md).
