# Demo video shot list

Target length: under the CAC cap (check congressionalappchallenge.us; it has been 3 minutes). Times below add up to about 2:45.

Record the simulator with `xcrun simctl io booted recordVideo --codec h264 take1.mp4` (Ctrl-C to stop). Set the status bar first: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100`. Launch arguments go in Edit Scheme › Run › Arguments.

| # | Time | Screen / launch args | Say |
|---|---|---|---|
| 1 | 0:00–0:25 | You on camera, or photos (with permission) | My mom has type 1 diabetes. Kids diagnosed young start with a parent doing everything, and one day have to do it all alone. Most apps are built for one adult. |
| 2 | 0:25–0:40 | Setup screen, `-resetSetup` | DiabetesCare asks who it's for: a kid, a teen, an adult or a parent. The app changes with the answer. |
| 3 | 0:40–1:05 | Kid Today → Get Help, `-demoData -stage kid` | A kid gets a simpler screen. Feeling off? Get Help walks them through it: find a grown-up, 15 g of sugar, a recheck timer on the Lock Screen, one tap to call Mom. |
| 4 | 1:05–1:20 | Log › Add Insulin asks for passcode | Risky things need a grown-up's passcode. Safety info never does. |
| 5 | 1:20–1:45 | Your Path → Treat a Low quiz → skill unlocked | Kids earn independence by learning. Pass Know Your Ranges and Treat a Low, and they can log insulin themselves. |
| 6 | 1:45–1:55 | Move Up to Teen (passcode 1234), plant grows | When all the skills are done, a grown-up approves the move to Teen. |
| 7 | 1:55–2:15 | `-demoFamily`: parent's phone, "Maya: Urgent Low" | The parent sees readings and gets alerts. Fewer as the kid grows: at Teen, only urgent ones. |
| 8 | 2:15–2:25 | Quick cuts: widget, Live Activity, watch | It lives outside the app too. |
| 9 | 2:25–2:45 | You on camera | Free. Nothing comes to us: no account, no server. Family sharing over iCloud is built and turns on when we get a developer account. Next: testing with families and a clinician review. |

Notes
- Say plainly that iCloud sharing isn't live (shot 9) and that the parent screen is sample data.
- Keep text on screen big; judges may watch on a phone.
- Upload unlisted and test the link while logged out.
