# Demo video plan

The film for the Congressional App Challenge. Length 2:51 (cap has been 3:00; check congressionalappchallenge.us before final). The real app is the star: most of Act 2 is the real app, animated around. How clips are made: the `diabetescare-video` skill (`.claude/skills/diabetescare-video/SKILL.md`). Storyboard: `docs/video/out/storyboard.png` (`node docs/video/render.mjs storyboard out/storyboard.png`).

Built on the CAC rubric (30 points): **Ideology, Impact, Structure** (concept) and **Function, Code, UI** (technology). Three acts: why it matters, how it works, why you can trust it. The real code runs beside the app through most of Act 2: an editor card scrolls the actual Swift and highlights the line behind what the phone is showing, with a labelled link to the control (4, 5, 6, 8, 9b, 10), printed strips in the scrapbook (7), the rules with the tests (11), and the type behind each feature (12a). `sync-source.py` copies it from the app, so it's never retyped.

## Looks

The real app carries the solution: Act 2 and the code shots are built on real app screens. Paper, Maya and Code frame them.

| Look | What it is | Shots |
|---|---|---|
| **App** | The real app in a phone frame: real screens (screenshots now, simulator recordings in the final), pushed like the app's navigation, tap ripples; beside it the code card with labelled links to the controls | 4, 5, 6, 8, 9b, 10 |
| **Scrapbook** | A journal page on kraft paper: real screens printed as polaroids and taped in with washi tape, the kit as die-cut stickers, handwritten notes (Caveat), doodled arrows and sticky notes. Stop motion on twos | 1, 7, 9a, 12b |
| **Hype** | The loud beats: a dark pine stage with turning rays and halftone dots; words slam in from the camera with a flash, a shake and a burst | 2d, 3, 11, 12a |
| **Paper** | Stop-motion cut paper: poses on twos (12 per second), a little wobble each pose, soft shadows on textured paper | the callouts, the cut-paper pieces in Scrapbook |
| **Maya** | The character, drawn in code (`docs/video/maya.js`); pose and expression changes cross-fade, never snap | 2a, 2b, 2c (each with a time-of-day card), and a cheer in 8 |
| **Code** | The app's real Swift on an editor card, beside the app wherever it can be | 4–11, 12a |

The isometric Desk scenes and the sealed-letter illustration appear as photos (9a, 10). The calm looks (Scrapbook, App, Maya) carry the story; Hype hits the numbers (2d), the turn (3), the proof (11) and the list (12a). The real app is on screen for about 110 of the 170 seconds.

Shots flow into each other: each one has a designed transition into the next (`in` in `film.js`: fades, a slide like the app's navigation, an iris), overlapping by half a second, so there's no dead air at the cuts. Captions change style by section (`cap` in `film.js`): big phrase-by-phrase words placed in open space for Maya, the numbers and the title; taped paper strips on the scrapbook pages; the bottom card for the app and feature shots. Phrases are timed to Angad's recording (`vo-mix.py`). No music in the final cut (the owner's choice; `sound.py` and `vo-mix.py --music` keep it available). Spoken lines run about 2.75 words a second (a bit brisker than easy speech); each line fits its shot and is a burned-in caption. The scratch voice (`scratch-vo.py`) reads at that pace.

## Shots

| # | Time | Look | Rubric | Picture | Say |
|---|---|---|---|---|---|
| 1 | 0:00–0:08 | Scrapbook | Ideology | "Mom, every day": her kit is stuck into a scrapbook as stickers, one by one, each with a handwritten note: her log, the meter (112 before breakfast), the pen (in every bag), the sensor (on her arm, always), juice (for lows). | "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young." |
| 2a | 0:07.5–0:13.5 | Maya | Ideology | 6:40 a.m., kitchen table, tired; numbers fill her paper log. Corner card: "Maya is made up. Her days aren't." | "Meet Maya. She's fourteen, and her day starts with a blood sugar check." |
| 2b | 0:13–0:22.5 | Maya | Ideology | School lunch, a 12:15 p.m. time card: four texts from Mom, "What's your number?"; embarrassed, then annoyed. A notice is pinned up: "PHONES AWAY · Texas House Bill 1481 · No phones all school day · Exception: a doctor's note · 2025". She puts the phone away and Mom's texts fade. | "Her mom checks in all day, because she has no other way to know. And a new Texas law keeps phones put away at school unless a doctor signs off." |
| 2c | 0:22–0:29 | Maya | Ideology, Impact | 2 a.m.: alarm, pillow over her head; she sits up slowly (the poses dissolve while she rises, then her face settles): "I can do this. Just let me." | "Most apps treat her like an adult or like a little kid. None of them change as she grows up." |
| 2d | 0:28.5–0:41 | Hype | Impact | Texas draws in; the camera dives into TX-22, which fills with dots (one per 1,000 adults); 64 light up as the count runs to 64,000 ("more than 1 in 9"), with its source under it. Then the camera pulls all the way out to the whole country (every state, Alaska and Hawaii as insets, TX-22 pulsing) for 314,000 U.S. kids and teens with type 1, with its own source under it. | "According to the CDC, about 64,000 adults in my district, Texas's 22nd, live with diabetes. And across the country, 314,000 kids and teens have type 1." |
| 3 | 0:40.5–0:51 | Hype | Structure | The turn: a flash, the sprout bursts up and blooms, "DiabetesCare" slams in letter by letter, "by Angad Kumar" above it, then "grows with you"; "For kids & teens with type 1" and "+ their parents" slam in as the line says them (the one-sentence purpose and the audience the rules ask for). | "So I built DiabetesCare, an iPhone app that helps kids and teens with type 1 diabetes take over their own care, with their parents in the loop." |
| 4 | 0:50.5–0:59.5 | App, Code | Impact, UI, Code | Setup "Who's Using DiabetesCare?" → Kid → the grown-up sets a passcode → the kid's Today. Beside the phone, `SetupView.swift` and `CareStage.swift` scroll to the line behind each choice, with a labelled link to the control. | "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer." |
| 5 | 0:59–1:08.5 | App, Code | Function, UI, Code | Kid Today → Get Help → "I Had 15 g of Sugar" → the Dynamic Island still counting. The screen's colours washed behind, a soft glow that beats until the recheck starts, a step tracker (find a grown-up, 15 g, recheck), and the code for each step: `KidHelpCard`, `LowTreatmentService`, the Live Activity. | "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap." |
| 6 | 1:08–1:17.5 | App, Code | Function, Code | "Ask a Grown-Up" keypad (dots fill) → the range rulers unlock, beside `ParentLock.swift`: the check, then the salt and the salted hash, the only thing saved. | "Risky things need a grown-up's passcode. Safety help never does. The app never saves the passcode itself, only a salted hash of it." |
| 7 | 1:17–1:25.5 | Scrapbook, Code | UI, Code | "Feels like real life": four polaroids of the real screens taped in as they're named (the kitchen scale, the insulin pen dial, the body map, time in range as test tubes), each with a strip of its real code taped under it and highlighted. | "Logging feels like real life: a kitchen scale for carbs, an insulin pen you dial, and a body map for sites." |
| 7b | 1:25–1:35.5 | App, Code | Function, Code | Built on Apple: Devices & Apple Health, then the day's story on Today, beside `HealthGlucoseImporter` (the observer query, background delivery) and `StoryWriter` (the on-device model's instructions, then `isFaithful`, which throws the answer away unless every number survives). Badges: "Apple Health", "Apple Intelligence". | "Readings from her CGM come in through Apple Health. And with Apple Intelligence, an on-device model retells her day, and the app throws it out if a single number changes." |
| 8 | 1:35–1:43.5 | App, Code | Impact, Code | Your Path with the plant → "Skill Learned!" (Maya cheers) → "Ready for Teen 4 of 4" → Move Up, beside `CareStage.skillsToMoveUp` and `SkillPathView` (the grown-up's `gate.run(.changeStage)`). | "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up." |
| 9a | 1:43–1:51.5 | Scrapbook, App | Function | Mom's real phone taped into the book beside a polaroid of Desk scene 3: "Maya asked for help" → one tap → "On my way!" (sample data). The four lunch texts from 2b are sticky notes, scribbled out as the line says it. | "When Maya needs help, Mom sees it right away and answers with one tap. Maya doesn't get four texts at lunch anymore." |
| 9b | 1:51–1:57 | App, Code | Code | Maya's phone and Mom's phone on either side of the code: `sendHelpRequest` builds and publishes the request, then `FamilyRecordCodec` seals it into `encryptedValues`; the sealed letter flies from her phone over the line to Mom's. | "Before it leaves her phone, it's sealed: end-to-end encrypted, for her family only." |
| 10 | 1:56.5–2:05 | App, Code | Impact, Code | Real See What Family Sees beside `FamilyModels.swift` (the fields family gets, walked one by one) and the sealing line; "Not me", "Not Apple", "No server". | "Her health information stays inside her family. Not even Apple can read it, and since there's no server, I never get a copy." |
| 11 | 2:04.5–2:16 | Hype, Code | Code, Function | `CareStage.access` (the real function) beside a "Built with" panel: Swift, SwiftUI, Xcode, Core Data, CloudKit, HealthKit, WidgetKit, ActivityKit, App Intents, WatchConnectivity, Foundation Models, Swift Testing and XCTest; the highlight walks the stages. Then all 198 tests from the last full run scroll up past a scan line in four columns, each ticking green with its real name, while the counter runs to "198 of 198 passed". | "I wrote it in Swift with SwiftUI. One function decides what each age is allowed to do, so every screen follows the same rules. And 198 tests check it." |
| 12a | 2:15.5–2:31 | Hype, App, Code | Function, UI | Thirteen real screens land on the stage as they're named, each with its Swift type underneath (`GlucoseWidget`, `WatchBridge`, `CheckGlucoseIntent`, `FoodSearchView`, `TrendsView`, `WeeklyRecapView`, `CaregiverAlertPolicy`, `SickDayCard`, `SchoolCardView`, `ReportsView`, `SuppliesView`, `LearnView`, the iPad's `MainTabView`); "Free" lands last. | "There's more: widgets, Apple Watch, Siri, five thousand foods, trends, weekly recaps, urgent alerts for family, a sick-day checklist, a school card, doctor reports, supplies, lessons, and iPad. All of it free." |
| 12b | 2:30.5–2:45 | Scrapbook | Impact, Structure | The last page: the plant in bloom; sticky notes land and get ticked as they're named: "App Store", "Family sharing on", "More languages", "School nurses", "Clinics". End card taped in, and spoken (a second recording, 12b-2): "Diabetes doesn't stop growing. DiabetesCare doesn't stop caring." | "Next: the App Store, with family sharing on. Then other languages, school nurses, and clinics that hand it to families the day a kid is diagnosed." |
| 13 | 2:44.5–2:51 | Scrapbook | Ideology | The last page is Angad's: real photos of him and his mom taped in (`docs/video/assets/personal/me.jpg`, `mom.jpg`; a dashed slot until they're added), the app icon as a sticker, handwritten "DiabetesCare · for Mom, and for every kid like Maya", signed "Angad". | "I'm Angad. I built DiabetesCare for my mom, and for every kid who'll grow up with it." |

## Facts on screen

| Claim | Source |
|---|---|
| Texas phone law (2b) | HB 1481, 89th Legislature, signed June 2025, in effect for the 2025–26 school year: districts must ban personal communication devices on campus during the school day; use is allowed with a documented need from a physician's directive, an IEP or a 504 plan, or a health or safety rule. [Bill text](https://capitol.texas.gov/tlodocs/89R/billtext/html/HB01481F.htm) |
| About 64,000 adults with diabetes in TX-22, more than 1 in 9 (2d; the source is on screen under the number) | CDC PLACES, census-tract estimates (2025 release, 2023 BRFSS data), diagnosed diabetes among adults, summed over the 164 tracts in the district (119th Congress), split tracts weighted by land area: 64,326 of 554,077 adults (11.6%). Model-based estimates. Rerun with `python3 docs/video/district-stat.py`. |
| 198 tests (11) | Every test that passed in the full suite run of 2026-10-25 (147 unit, 51 UI; 17 demo-footage and screenshot tests are skipped in normal runs and Xcode's 3 empty template tests aren't counted). `HealthImportUITests.testGlucoseDeletedInHealthIsRemoved` failed once inside Apple's Health app and passed on rerun. The wall shows their real names: `python3 docs/video/sync-tests.py <xcresult>…`. |
| 314,000 U.S. kids and teens with type 1 (2d; the source is on screen under the number) | CDC, National Diabetes Statistics Report: children and adolescents under 20 with diagnosed type 1 diabetes. [CDC](https://www.cdc.gov/diabetes/php/data-research/index.html) |

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
| `test15MoreFeatures` | Learn, the doctor report, Supplies, Doctor Visit questions, Devices & Apple Health | 7b, 12a |
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

## 2026 CAC rules the video must meet

From the official 2026 rules (deadline **12:00 pm EDT, Monday, October 26, 2026**; the entry can't be changed after it):

| Rule | Where |
|---|---|
| 1 to 3 minutes | 2:55.5 (`node sync-times.mjs` prints it) |
| Name of each participant | "by Angad Kumar" on the title (3); "I'm Angad" and his signature (13) |
| Name of the app | 3, and throughout |
| Purpose in one clear sentence | 3: "…an iPhone app that helps kids and teens with type 1 diabetes take over their own care, with their parents in the loop." |
| Target audience | 3: kids and teens with type 1, and their parents (spoken and on screen) |
| Tools and coding languages | 11: spoken "Swift with SwiftUI"; "Built with" panel lists the frameworks and tools |
| Showcase the functionality | 4 to 12a, the real app |
| AI use fully disclosed | The submission form (not in the video, by choice) must disclose it in full (what AI helped with, for the app and for this video) |
| Open-source libraries and tools documented | the form: video tooling (Playwright, Nunito and Caveat fonts), data sources (CDC PLACES, Census, USDA FNDDS for the food list) |
| Public video on YouTube or Vimeo | upload step |

## Rules for the cut

- Honest: Maya is labelled made up (2a). Real app screens show sample data and say so where it matters (9a). The code is the real source. Family sharing is shown through the real publish and apply path with sample data, and 12b says it turns on at App Store launch. Don't claim it was tested on two phones or used by real families.
- Text big, on a backing card; judges may watch on a phone. No dead air.
- Upload to YouTube or Vimeo set to **Public** (the 2026 rules require it; unlisted or private doesn't count). Test the link while logged out.
- Details for questions after: `docs/security.md`, `PLANNING.md`.
