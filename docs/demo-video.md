# Demo video plan

The film for the Congressional App Challenge. Length 2:50 (cap has been 3:00; check congressionalappchallenge.us before final). How clips are made: the `diabetescare-video` skill (`.claude/skills/diabetescare-video/SKILL.md`).

Built on the CAC rubric (30 points): **Ideology, Impact, Structure** (concept) and **Function, Code, UI** (technology). Three acts: why it matters (Maya), how it works (the app), why you can trust it (privacy, security, code).

Spoken lines run about 2.5 words a second; each line below fits its shot. Every line is also a burned-in caption.

## Act 1 · Why (0:00–0:48)

| # | Time | Rubric | Picture | Say (Angad, voiceover unless noted) |
|---|---|---|---|---|
| 1 | 0:00–0:12 | Ideology | Angad on camera (photos of Mom only with her OK) | "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young." |
| 2a | 0:12–0:21 | Ideology | **Maya, animated.** Corner card: "Maya is made up. Her days aren't." 6:40 a.m., kitchen table, slumped (tired), meter and a paper log, the clock ticking. | "Meet Maya. She's fourteen. Every day starts with numbers." |
| 2b | 0:21–0:30 | Ideology | School lunch. Her phone buzzes again and again: "What's your number?" ×4 from Mom. Friends glance; Maya hides the phone (embarrassed, then annoyed). | "Her mom checks in all day, because she has no other way to know." |
| 2c | 0:30–0:40 | Ideology, Impact | 2 a.m., a soft alarm beeps; Maya pulls the pillow over her head. Then she sits up, thought bubble: "I can do this. Just let me." | "Most apps treat her like an adult, or like a little kid. Nothing grows up with her." |
| 3 | 0:40–0:48 | Structure | Title: the app's sprout grows from a seed and wipes the screen into "DiabetesCare · grows with you". | "So we built DiabetesCare. It grows with you." |

## Act 2 · How it works (0:48–1:56)

| # | Time | Rubric | Picture | Say |
|---|---|---|---|---|
| 4 | 0:48–1:00 | Impact, UI | Simulator: setup "Who's using DiabetesCare?" (`-resetSetup`) → tap Kid. Then **Scene 1 (Today)** for 4 s. | "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer." |
| 5 | 1:00–1:18 | Function, UI | Simulator: Kid Today → Get Help (`-demoData -stage kid`). Cut to **Scene 2 (Feeling off?)**: juice box, recheck ring on phone and watch. | "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap." |
| 6 | 1:18–1:26 | Function | Simulator: Log › Add Insulin asks for the grown-up passcode. | "Risky things need a grown-up's passcode. Safety help never does." |
| 7 | 1:26–1:44 | Impact | Simulator: Your Path → Treat a Low quiz → skill unlocked. **Maya, 2 s:** cheers (proud), the sprout grows a leaf. Back to the simulator: Move Up to Teen (passcode 1234). | "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up." |
| 8 | 1:44–1:56 | Function | **Scene 3 (Only your family)**: the sealed letter flies to Mom's phone. Then simulator, `-demoFamily`: the parent's phone with "Maya: Urgent Low". | "Mom doesn't have to text all day. She gets an alert when it matters, and fewer as Maya grows." |

## Act 3 · Why you can trust it (1:56–2:50)

| # | Time | Rubric | Picture | Say |
|---|---|---|---|---|
| 9 | 1:56–2:12 | Impact | Sealed-letter frame (`video-frames/sealed-letter.png`), on-screen text "Only your family. No one else." Then See What Family Sees, then the passcode lockout. | "Her health information is never shared outside her family. It's end-to-end encrypted, so not even Apple can read it. We don't have a server, so we never get a copy." |
| 10 | 2:12–2:34 | Code | Xcode: `CareStage.access(to:completed:)`, then `FamilyRecordCodec` `encryptedValues`, then `ParentLock` salted hash, then the test run passing. | "It's built in SwiftUI. Every rule about who can do what lives in one function, so no screen has a back door. Family data is encrypted before it leaves the phone, the passcode is stored only as a salted hash, and 207 tests check it." |
| 11 | 2:34–2:50 | Structure | **Maya, 3 s:** at her desk, phone in hand, proud. Then Angad on camera. | "It's free. Family sharing goes live once we have a developer account. Next, we're testing with real families." |

## What to make

| Item | How | Shots |
|---|---|---|
| Maya: character sheet, then clips 2a, 2b, 2c, 7 (cheer), 11 (proud) | `docs/video/` per the skill: `maya.js`, `render(ctx, t)` | 2, 7, 11 |
| Title card with sprout wipe | `docs/video/scenes/title.js` | 3 |
| App scenes 1–3 as MP4 | `docs/video-frames/scenes.mjs`, driven by `t` | 4, 5, 8 |
| Sealed-letter still | done: `docs/video-frames/sealed-letter.png` | 9 |
| Captions | `captions.srt` from the lines above; burned in at assembly | all |
| Music bed and SFX | `docs/video/sound.py` (synthesized) | all |

## What to record

| Item | How | Shots |
|---|---|---|
| Angad on camera | Phone on a tripod, window light, quiet room; 2 takes of each line | 1, 11 |
| Voiceover | One clean read of every line; record in a closet or under a blanket; WAV | 2–11 |
| Simulator footage | iPhone 17 Pro simulator, status bar `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100`, record with `xcrun simctl io booted recordVideo --codec h264 shotN.mp4` | 4–9 |
| Xcode | Screen recording at 1080p, editor font 18 pt, one file at a time | 10 |

## Order of work

1. Maya character sheet (gate 1 in the skill).
2. Storyboard of all 11 shots (gate 2).
3. Record voiceover and simulator footage (can run alongside 2).
4. Draft clips at 960×540 (gate 3); rough cut with the real voiceover to check timing.
5. Final 1080p clips, sound, captions; assemble; check length under the cap and the file plays logged out.

## Rules for the cut

- Say plainly that iCloud family sharing isn't live yet (shot 11) and that the parent screen is sample data (corner tag in shots 5 and 8).
- Maya's corner card in shot 2a is the only place she's labelled made up; don't imply she's a real user.
- Text big, on a backing card; judges may watch on a phone. No dead air.
- Upload unlisted; test the link while logged out.
- Details for questions after: `docs/security.md`, `PLANNING.md`.
