# Demo video plan

The film for the Congressional App Challenge. Length 2:50 (cap has been 3:00; check congressionalappchallenge.us before final). The real app is the star: most of Act 2 is the real app, animated around. How clips are made: the `diabetescare-video` skill (`.claude/skills/diabetescare-video/SKILL.md`). Storyboard: `docs/video/out/storyboard.png` (`node docs/video/render.mjs storyboard out/storyboard.png`).

Built on the CAC rubric (30 points): **Ideology, Impact, Structure** (concept) and **Function, Code, UI** (technology). Three acts: why it matters, how it works, why you can trust it. The code appears three times ("under the hood"): the passcode (6), the sealed letter (9b) and the rules with the tests (11).

## Looks

The real app carries the solution: Act 2 and the code shots are built on real app screens. Paper, Maya and Code frame them.

| Look | What it is | Shots |
|---|---|---|
| **App** | The real app in a phone frame: real screens (screenshots now, simulator recordings in the final), pushed like the app's navigation, tap ripples, paper callouts pointing at real controls | 4, 6, 8, 10 |
| **Scrapbook** | A journal page on kraft paper: real screens printed as polaroids and taped in with washi tape, the kit as die-cut stickers, handwritten notes (Caveat), doodled arrows and sticky notes. Stop motion on twos | 1, 7, 9a, 12b |
| **Hype** | The loud beats: a dark pine stage with turning rays and halftone dots; words slam in from the camera with a flash, a shake and a burst; the real phone punches in on each beat | 3, 5, 11, 12a |
| **Paper** | Stop-motion cut paper: poses on twos (12 per second), a little wobble each pose, soft shadows on textured paper | the callouts, the cut-paper pieces in Scrapbook |
| **Maya** | The character, drawn in code (`docs/video/maya.js`) | 2a, 2b, 2c, and a cheer in 8 |
| **Code** | The app's real Swift typed onto an editor card | 6, 9b, 11 |

The isometric Desk scenes and the sealed-letter illustration appear as photos (9a, 10). The calm looks (Scrapbook, App, Maya) carry the story; Hype hits the turn (3), the urgent moment (5), the proof (11) and the list (12a). The real app is on screen for about 110 of the 170 seconds.

Spoken lines run about 2.5 words a second; each line fits its shot and is a burned-in caption.

## Shots

| # | Time | Look | Rubric | Picture | Say |
|---|---|---|---|---|---|
| 1 | 0:00–0:10 | Scrapbook | Ideology | "Mom, every day": her kit is stuck into a scrapbook as stickers, one by one, each with a handwritten note: her log, the meter (112 before breakfast), the pen (in every bag), the sensor (on her arm, always), juice (for lows). | "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young." |
| 2a | 0:10–0:18 | Maya | Ideology | 6:40 a.m., kitchen table, tired; numbers fill her paper log. Corner card: "Maya is made up. Her days aren't." | "Meet Maya. She's fourteen. Every day starts with numbers." |
| 2b | 0:18–0:26 | Maya | Ideology | School lunch: four texts from Mom, "What's your number?"; embarrassed, then annoyed. | "Her mom checks in all day, because she has no other way to know." |
| 2c | 0:26–0:35 | Maya | Ideology, Impact | 2 a.m.: alarm, pillow over her head; she sits up: "I can do this. Just let me." | "Most apps treat her like an adult or like a little kid. None of them change as she grows up." |
| 3 | 0:35–0:41 | Hype | Structure | The turn: a flash, the sprout bursts up and blooms, "DiabetesCare" slams in letter by letter, then "grows with you". | "So we built DiabetesCare. It grows with you." |
| 4 | 0:41–0:51 | App | Impact, UI | Setup "Who's Using DiabetesCare?" → Kid → the grown-up sets a passcode → the kid's Today with the "What did your meter say?" ruler. | "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer." |
| 5 | 0:51–1:05 | Hype, App | Function, UI | The stage pulses berry; the real phone punches in on each step: Kid Today → Get Help → "I Had 15 g of Sugar" → the Dynamic Island still counting. Words slam in as they're said: "Feeling off?", "15 g", "Recheck 15:00", "Call Mom: 1 tap"; it calms to green once the recheck runs. | "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap." |
| 6 | 1:05–1:15 | App, Code | Function, Code | "Ask a Grown-Up" keypad (dots fill) → the range rulers unlock; the phone slides aside and `ParentLock.swift` is typed, salted-hash line highlighted. | "Risky things need a grown-up's passcode. Safety help never does. The app never saves the passcode itself, only a salted hash of it." |
| 7 | 1:15–1:27 | Scrapbook | UI | "Feels like real life": four polaroids of the real screens taped in as they're named: the kitchen scale (30 g), the insulin pen dial, the body map, time in range as test tubes. | "Logging feels like real life: a kitchen scale for carbs, an insulin pen you dial, and a body map for sites." |
| 8 | 1:27–1:41 | App | Impact | Your Path with the plant ("Budding") → the last quiz → "Skill Learned!" (Maya cheers) → "Ready for Teen 4 of 4" → Move Up → the ladder fills Teen and the colours change. | "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up." |
| 9a | 1:41–1:51 | Scrapbook, App | Function | Mom's real phone taped into the book beside a polaroid of Desk scene 3: "Maya asked for help" → one tap → "On my way!" (sample data). The four lunch texts from 2b are sticky notes, scribbled out as the line says it. | "When Maya needs help, Mom sees it right away and answers with one tap. Maya doesn't get four texts at lunch anymore." |
| 9b | 1:51–1:57 | Code | Code | `FamilyRecordCodec.swift`: the `encryptedValues` line is typed and highlighted; the letter flies over it. | "Before it leaves her phone, it's sealed: end-to-end encrypted, for her family only." |
| 10 | 1:57–2:11 | App | Impact | Real See What Family Sees beside the sealed-letter photo; "Not us", "Not Apple", "No server". | "Her health information stays inside her family. Not even Apple can read it, and since we don't run a server, we never get a copy." |
| 11 | 2:11–2:26 | Hype, Code | Code, Function | `CareStage.access` is typed on the dark stage; "SwiftUI", "One function", "No back door" slam in; the highlight walks the stages; 147 unit and 60 UI tests count up and "207 tests ✓" lands with checkmark confetti; the real app slides in: "Running on iPhone". | "It's built in SwiftUI. Every rule about who can do what lives in one function, so no screen has a back door. And 207 tests check it." |
| 12a | 2:26–2:38 | Hype, App | Function, UI | Rapid fire: each real screen slams onto the stage as it's named, its name slams in up top, about one a second: Home Screen widgets, the watch glance, the "Check Glucose" shortcut (the snippet Siri shows), the food search, the weekly recap, the sick-day checklist, the school card, Teen. | "There's more: widgets, an Apple Watch app, Siri, five thousand foods to look up, a weekly recap, a sick-day checklist, and a card for school. All of it free." |
| 12b | 2:38–2:50 | Scrapbook | Impact, Structure | The last page: the plant in bloom; sticky notes land and get ticked as they're named: "App Store", "Family sharing on", "En español", "School nurses", "Clinics". End card taped in: "Every kid with diabetes grows up. Now their app can too." | "Next: the App Store, with family sharing on. Then Spanish, school nurses, and clinics that hand it to families the day a kid is diagnosed." |

## Footage

Recorded from the real app with demo data: `sh scripts/record-demo.sh` runs `DiabetesCareUITests/DemoReelUITests` (skipped in normal runs) on an iPhone 17 Pro Max simulator at 9:41, one video per flow in `docs/video/assets/rec/` (git-ignored, large) and named stills in `docs/video/assets/stills/`. Re-record one flow with `sh scripts/record-demo.sh test04EarnAndMoveUp`.

| Clip | What it shows | Shots |
|---|---|---|
| `test01Setup` | Who's Using → Kid → Grown-Up Passcode → kid Today with the meter ruler | 4 |
| `test02KidHelpAndLiveActivity` | Kid Today with the plant → Get Help → 15 g → Dynamic Island countdown | 5 |
| `test03PasscodeAndInsulinPen` | Ask a Grown-Up keypad → range rulers; Add Insulin pen dial | 6, 7 |
| `test04EarnAndMoveUp` | Your Path → Time in Range quiz → Skill Learned → Move Up to Teen | 8 |
| `test05SiteBodyMap` | Change Site body map | 7 |
| `test06CarbLookup` | Add Carbs kitchen scale → search "apple raw" → 30 g fills in | 7 |
| `test07Trends` | Trends: time-in-range tubes, typical day, after meals | 7 |
| `test08WeeklyRecap` | Today's story → the weekly recap | 12a |
| `test09SickDay` | Day tags → sick-day checklist | 12a |
| `test10FamilySees` | Family settings → See What Family Sees | 10 |
| `test11ParentPhone` | Mom's phone: Maya's help request → "On my way!" | 9a |
| `test12SchoolCard` | School & Sitter Card: low signs, rule of 15, who to call | 12a |
| `test13Siri` | Shortcuts: the app's shortcuts → Check Glucose answers "175 mg/dL, in range" (Siri itself doesn't draw in the simulator) | 12a |
| `test14Widgets` | Home Screen widget gallery: small and medium Glucose widgets (placing the widget is flaky; the gallery stills are used) | 12a |
| `scripts/record-watch.sh` | The watch glance with real data from the phone over WatchConnectivity | 12a |

Not captured: the sample "Maya: Urgent Low" notification (UI-test launches don't show it); the help-request reply covers the same story.

## What to make

| Item | How | Shots |
|---|---|---|
| App clips | `docs/video/scenes/app.js`: the recordings in a phone frame with paper callouts (stills in drafts) | 4, 6, 8, 10 |
| Scrapbook, Hype clips | `scenes/scrap.js`, `scenes/hype.js` (real screens inside both) | 1, 3, 5, 7, 9a, 11, 12a, 12b |
| Maya, Code clips | `scenes/maya-scenes.js`, `scenes/code.js` | 2a–2c, 9b |
| Voiceover | Angad, one clean read of every line, WAV; quiet room | all |
| Music, SFX, captions | `sound.py`, `captions.srt` (final gate) | all |

## Rules for the cut

- Honest: Maya is labelled made up (2a). Real app screens show sample data and say so where it matters (9a). The code is the real source. Family sharing is shown through the real publish and apply path with sample data, and 12b says it turns on at App Store launch. Don't claim it was tested on two phones or used by real families.
- Text big, on a backing card; judges may watch on a phone. No dead air.
- Upload unlisted; test the link while logged out.
- Details for questions after: `docs/security.md`, `PLANNING.md`.
