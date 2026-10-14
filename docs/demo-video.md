# Demo video shot list

Target length: under the CAC cap (check congressionalappchallenge.us; it has been 3 minutes). Times below add up to about 2:57.

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
| 7 | 1:35–2:05 | Impact, Code | Sealed-letter frame (`video-frames/sealed-letter.png`), then See What Family Sees, then the passcode lockout screen | **Privacy and security.** Your health information is never shared with anyone outside your family, ever. We don't have a server, an account or ads, so there's nothing of ours to hack and we never get a copy. It stays on your phone, encrypted, and only the family you invite can see it. Even that is end-to-end encrypted, so not even Apple can read it. The grown-up passcode is never stored, only a scrambled hash, and five wrong tries locks it out. And you can see exactly what your family sees. |
| 8 | 2:05–2:12 | UI | Quick cuts: widget, Live Activity, watch | It lives outside the app too. |
| 9 | 2:12–2:42 | Code | Xcode: `CareStage.swift` `access(to:completed:)`, `FamilyRecordCodec.swift` `encryptedValues`, `ParentLock.swift` salted hash, then the test run passing | Built in SwiftUI. Every rule about who can do what lives in one function behind one gate, so there's no back door in some screen. Family data is encrypted before it leaves the phone, and the passcode is salted and hashed in the Keychain. 147 unit tests and 60 UI tests check it. |
| 10 | 2:42–2:57 | Structure | You on camera | Free. Family sharing over iCloud is built and turns on when we get a developer account. Next: testing with families and a clinician review. |

Notes
- **Sealed-letter frame** (`docs/video-frames/sealed-letter.png`, 1920×1080; vector in `sealed-letter.svg`): Maya's phone sends a sealed envelope with the sprout seal straight to Mom's phone, which holds the only key. Hold it under "only the family you invite can see it… not even Apple". Drawn in the app's soft style (Nunito, app greens).
- **Animated app scenes** (`docs/video-frames/scene1-today.html`, `scene2-feeling-off.html`, `scene3-family.html`; rebuild with `node docs/video-frames/build-scenes.mjs`, needs the anatomy skill): phones on a desk with the app's real screens, made with the anatomy skill. Open full screen and screen-record. Sample data, sped up (the captions say so).
  - Scene 1, Today (loops ~18 s): sensor flashes, the reading rolls 148 → 112, the trend arrow turns, the 3-hour line grows. Use behind shot 2 or 3.
  - Scene 2, Feeling off? (loops ~12 s): Low 62 banner, juice box (15 g), 15-minute recheck ring on phone and watch, then "Back in range · 94". Use with shot 3.
  - Scene 3, Only your family (loops 11 s): the sealed letter flies from Maya's phone to Mom's, "Maya: Low 62 · treating it" slides onto Mom's lock screen, later "back in range". Use with shot 6 or 7.
- Shot 7 is the promise: never shared beyond family, no one else can see it, and it's secure. Put "Only your family. No one else." and "End-to-end encrypted" on screen as text. Security details for questions: `docs/security.md`.
- Be honest: say iCloud sharing isn't live yet (shot 10) and that the parent screen is sample data.
- Keep text on screen big; judges may watch on a phone. No dead air or long cuts (Structure row).
- Upload unlisted and test the link while logged out.
