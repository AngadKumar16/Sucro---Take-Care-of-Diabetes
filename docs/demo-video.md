# Demo video shot list

Target length: under the CAC cap (check congressionalappchallenge.us; it has been 3 minutes). Times below add up to about 2:55.

Built around the CAC judging rubric (30 points): Ideology, Impact and Structure (concept), Function, Code and UI (technology). The rubric scores the video on **explaining the code**, so shot 9 is not optional.

Record the simulator with `xcrun simctl io booted recordVideo --codec h264 take1.mp4` (Ctrl-C to stop). Set the status bar first: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100`. Launch arguments go in Edit Scheme › Run › Arguments.

| # | Time | Rubric | Screen / launch args | Say |
|---|---|---|---|---|
| 1 | 0:00–0:20 | Ideology | You on camera, or photos (with permission) | My mom has type 1 diabetes. Kids diagnosed young start with a parent doing everything, and one day have to do it all alone. Most apps are built for one adult. |
| 2 | 0:20–0:30 | Impact | Setup screen, `-resetSetup` | DiabetesCare grows with you: a kid, a teen, an adult, or the parent. |
| 3 | 0:30–0:50 | Function, UI | Kid Today → Get Help, `-demoData -stage kid` | A kid gets a simpler screen. Feeling off? Get Help walks them through it: find a grown-up, 15 g of sugar, a recheck timer on the Lock Screen, one tap to call Mom. |
| 4 | 0:50–1:00 | Function | Log › Add Insulin asks for passcode | Risky things need a grown-up's passcode. Safety info never does. |
| 5 | 1:00–1:20 | Impact | Your Path → Treat a Low quiz → skill unlocked → Move Up (1234), plant grows | Kids earn independence by learning. Each skill unlocks something, and when they're ready a grown-up approves the move to Teen. |
| 6 | 1:20–1:35 | Function | `-demoFamily`: parent's phone, "Maya: Urgent Low" | The parent sees readings and gets alerts, fewer as the kid grows. |
| 7 | 1:35–2:00 | Impact | Settings › Family › See What Family Sees, then a lock graphic | **Privacy.** Your health information is never shared with anyone outside your family, ever. We don't have a server, an account or ads, and we never get a copy. It stays on your phone, and only the family you invite can see it. Even that is end-to-end encrypted, so not even Apple can read it. And you can see exactly what your family sees. |
| 8 | 2:00–2:10 | UI | Quick cuts: widget, Live Activity, watch | It lives outside the app too. |
| 9 | 2:10–2:40 | Code | Xcode: `CareStage.swift` `access(to:completed:)`, then `FamilyRecordCodec.swift` `encryptedValues`, then the test run passing | Built in SwiftUI. Every rule about who can do what lives in one function, so a kid can never get around it. Family data is encrypted before it leaves the phone. 147 unit tests and 60 UI tests check it. |
| 10 | 2:40–2:55 | Structure | You on camera | Free. Family sharing over iCloud is built and turns on when we get a developer account. Next: testing with families and a clinician review. |

Notes
- Shot 7 is the promise: never shared beyond family, no one else can see it. Put "Only your family. No one else." on screen as text too.
- Be honest: say iCloud sharing isn't live yet (shot 10) and that the parent screen is sample data.
- Keep text on screen big; judges may watch on a phone. No dead air or long cuts (Structure row).
- Upload unlisted and test the link while logged out.
