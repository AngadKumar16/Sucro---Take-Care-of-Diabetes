# Demo video plan

The film for the Congressional App Challenge. Length 2:47 (cap has been 3:00; check congressionalappchallenge.us before final). The real app is the star: most of Act 2 is the real app, animated around. How clips are made: the `diabetescare-video` skill (`.claude/skills/diabetescare-video/SKILL.md`). Storyboard: `docs/video/out/storyboard.png` (`node docs/video/render.mjs storyboard out/storyboard.png`).

Built on the CAC rubric (30 points): **Ideology, Impact, Structure** (concept) and **Function, Code, UI** (technology). Three acts: why it matters, how it works, why you can trust it. The code appears three times ("under the hood"): the passcode (6), the sealed letter (9b) and the rules with the tests (11).

## Looks

The real app carries the solution: Act 2 and the code shots are built on real app screens. Paper, Maya and Code frame them.

| Look | What it is | Shots |
|---|---|---|
| **App** | The real app in a phone frame: real screens (screenshots now, simulator recordings in the final), pushed like the app's navigation, tap ripples, paper callouts pointing at real controls | 4, 5, 6, 7, 8, 9a, 10, 11 (end), 12a |
| **Paper** | Stop-motion cut paper: poses on twos (12 per second), a little wobble each pose, soft shadows on textured paper | 1, 3, 12b, and the callouts |
| **Maya** | The character, drawn in code (`docs/video/maya.js`) | 2a, 2b, 2c, and a cheer in 8 |
| **Code** | The app's real Swift typed onto an editor card | 6, 9b, 11 |

The isometric Desk scenes and the sealed-letter illustration appear as paper photos inside App shots (9a, 10). The real app is on screen for about 100 of the 167 seconds.

Spoken lines run about 2.5 words a second; each line fits its shot and is a burned-in caption.

## Shots

| # | Time | Look | Rubric | Picture | Say |
|---|---|---|---|---|---|
| 1 | 0:00–0:10 | Paper | Ideology | Mom's kit lands on the kitchen table piece by piece: notebook, meter (112), insulin pen, sensor, juice box, a paper heart. | "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young." |
| 2a | 0:10–0:18 | Maya | Ideology | 6:40 a.m., kitchen table, tired; numbers fill her paper log. Corner card: "Maya is made up. Her days aren't." | "Meet Maya. She's fourteen. Every day starts with numbers." |
| 2b | 0:18–0:26 | Maya | Ideology | School lunch: four texts from Mom, "What's your number?"; embarrassed, then annoyed. | "Her mom checks in all day, because she has no other way to know." |
| 2c | 0:26–0:35 | Maya | Ideology, Impact | 2 a.m.: alarm, pillow over her head; she sits up: "I can do this. Just let me." | "Most apps treat her like an adult, or like a little kid. Nothing grows up with her." |
| 3 | 0:35–0:41 | Paper | Structure | A paper sprout blooms; "DiabetesCare" is laid tile by tile, then "grows with you". | "So we built DiabetesCare. It grows with you." |
| 4 | 0:41–0:51 | App | Impact, UI | Setup "Who's Using DiabetesCare?" → Kid → the grown-up sets a passcode → the kid's Today with the "What did your meter say?" ruler. | "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer." |
| 5 | 0:51–1:07 | App | Function, UI | Kid Today → Get Help → "I Had 15 g of Sugar" → Home Screen, where the 15-minute recheck keeps counting in the Dynamic Island. | "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap." |
| 6 | 1:07–1:17 | App, Code | Function, Code | "Ask a Grown-Up" keypad (dots fill) → the range rulers unlock; the phone slides aside and `ParentLock.swift` is typed, salted-hash line highlighted. | "Risky things need a grown-up's passcode. Safety help never does. The code itself is never saved, only a salted hash." |
| 7 | 1:17–1:29 | App | UI | Real-life tools, 3 s each: the kitchen-scale dial filling with an apple's 30 g, the insulin pen dial, the body map, time in range as test tubes. | "Logging feels like real life: a kitchen scale for carbs, an insulin pen you dial, and a body map for sites." |
| 8 | 1:29–1:43 | App | Impact | Your Path with the plant ("Budding") → the last quiz → "Skill Learned!" (Maya cheers) → "Ready for Teen 4 of 4" → Move Up → the ladder fills Teen and the colours change. | "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up." |
| 9a | 1:43–1:53 | App | Function | Desk scene 3 as a photo beside Mom's real phone: "Maya asked for help" → one tap → "Sent: On my way!" (sample data). | "When Maya needs help, Mom sees it right away and answers with one tap. No more texting all day." |
| 9b | 1:53–1:59 | Code | Code | `FamilyRecordCodec.swift`: the `encryptedValues` line is typed and highlighted; the letter flies over it. | "Before it leaves her phone, it's sealed: end-to-end encrypted, for her family only." |
| 10 | 1:59–2:13 | App | Impact | Real See What Family Sees beside the sealed-letter photo; "Not us", "Not Apple", "No server". | "Her health information is never shared outside her family. It's end-to-end encrypted, so not even Apple can read it. We don't have a server, so we never get a copy." |
| 11 | 2:13–2:33 | Code, App | Code, Function | `CareStage.access` is typed; the highlight walks Kid → Teen → Adult → skills; 147 unit and 60 UI tests count up; the real app slides in: "Running on iPhone". | "It's built in SwiftUI. Every rule about who can do what lives in one function, so no screen has a back door. And 207 tests check it." |
| 12a | 2:33–2:40 | App | Structure | The most distinctive screens land on the table like photos: the plant, the kitchen scale, the weekly recap, the sick-day checklist, Teen. | "It's free. Family sharing goes live once we have a developer account." |
| 12b | 2:40–2:47 | Paper | Structure | The paper plant blooms; notes: "Free, for every family", "Family sharing: live with a developer account", "Next: testing with real families". | "Next, we're testing with real families." |

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

Not captured: the sample "Maya: Urgent Low" notification (UI-test launches don't show it); the help-request reply covers the same story.

## What to make

| Item | How | Shots |
|---|---|---|
| App clips | `docs/video/scenes/app.js`: the recordings in a phone frame with paper callouts (stills in drafts) | 4–10, 12a |
| Paper, Maya, Code clips | `scenes/paper.js`, `scenes/maya-scenes.js`, `scenes/code.js` | 1–3, 6, 9b, 11, 12b |
| Voiceover | Angad, one clean read of every line, WAV; quiet room | all |
| Music, SFX, captions | `sound.py`, `captions.srt` (final gate) | all |

## Rules for the cut

- Honest: Maya is labelled made up (2a). Real app screens show sample data and say so where it matters (9a). The code is the real source. Say plainly that iCloud family sharing isn't live yet (12a, 12b).
- Text big, on a backing card; judges may watch on a phone. No dead air.
- Upload unlisted; test the link while logged out.
- Details for questions after: `docs/security.md`, `PLANNING.md`.
