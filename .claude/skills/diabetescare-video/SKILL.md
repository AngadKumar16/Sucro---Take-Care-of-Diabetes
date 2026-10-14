---
name: diabetescare-video
description: Make the DiabetesCare demo video for the Congressional App Challenge, or any clip for it (Maya character scenes, animated app scenes, title cards, captions, music bed). Use when asked to plan, storyboard, animate, render or edit the demo video, to draw or animate Maya, or to turn docs/video-frames scenes into MP4 clips.
---

# DiabetesCare demo video

You are the motion designer and engineer for the CAC demo video. The film plan (script, timing, shots) lives in `docs/demo-video.md`; read it first and keep it the single source of truth. This skill is how clips get made.

## 1. What matters most

- **The voiceover leads.** Angad's narration is the spine. Scene lengths come from the script's spoken lines, not from a beat grid. Music sits under the voice (about −18 dB below it, ducked further while he speaks).
- **Under the cap.** The CAC video cap has been 3:00. Check congressionalappchallenge.us before final, and keep the cut at 2:50 or less.
- **The rubric.** 30 points: Ideology, Impact, Structure (concept); Function, Code, UI (technology). Every shot in the plan names the rubric row it serves. The Code row needs real code on screen, explained.
- **Honest.** Maya is a made-up character and says so on screen once. Sample data is labelled "sample data". Sped-up time says so. Family sharing over iCloud is built but not live until the paid developer account: say it plainly. Never show a claim the app doesn't back (see `docs/security.md`, `PLANNING.md`).
- **Captions burned in.** Judges may watch muted or on a phone: every spoken line appears as a caption on a backing card, Nunito 800, at least 44 px at 1080p, bottom third, never over a phone screen's key content.

## 2. Look

The app's own style, which the owner chose: soft, rounded, friendly, illustrated real objects, greens. Not sleek, not "manufactured", not grey machines. The approved reference is the sealed letter (`docs/video-frames/sealed-letter.png`).

| Token | Hex | Use |
|---|---|---|
| Pine | `#1f6b4a` | primary, buttons, seal, titles |
| Leaf | `#5fa77e` | sprout, success |
| Mint | `#bfe0c9` | soft fills, cards |
| Sage | `#e2eee3` | backgrounds |
| Cream | `#fbf8f1` | phone glass, paper |
| Amber | `#d9933f` | pot, carbs, warmth |
| Berry | `#e0644a` | lows, alerts, Maya's hoodie accent |
| Ink | `#2f4a3b` | outlines (never pure black) |

Type: **Nunito** (800/900 display, 700 text), the closest free face to the app's SF Rounded. Outline weight: 4 px at 1080p on characters and props. Light from the top left.

## 3. Maya

Maya is original, drawn in code from simple shapes with an Ink outline, so she looks the same in every shot. She appears in the opening (her frustrations) and the ending (her confidence), and briefly when she earns a skill. She is about 14 (the app's demo teen), in a Cream T-shirt under an open Berry hoodie with the sleeves pushed up, dark bob with a Leaf clip, a CGM sensor on the back of her left upper arm (always the same arm), round eyes, simple brows that carry the expression.

Rules:
1. Same proportions every shot: head is 1/4.5 of her height; sensor visible whenever the left arm faces the camera.
2. Five expressions only: neutral, tired, annoyed, embarrassed, proud. Brows and mouth change; eyes stay round.
3. Frustration is shown, never mocked: she's tired and fed up, not sad or sick. No needles drawn piercing skin, no blood beyond a dot on a test strip.
4. Thought text goes in a rounded bubble with an Ink outline, never floating.
5. She never says anything about dosing.

`maya.js` exports `drawMaya(ctx, { x, y, scale, facing: "front" | "three-quarter" | "side" | "back", expression, pose, t })`. Poses: stand, sit, slump, phone (holding a phone), pillow (lying with pillow over head), cheer.

## 4. How clips are built

- **Frame-deterministic.** Every animated clip is `render(ctx, t)` on a 1920×1080 canvas, drawing the frame at time `t` seconds with no stored state, so frames render in any order and in parallel.
- **Files.** `docs/video/` holds: `maya.js` (character), `film.js` (scenes, timeline, `events()`), `scenes/*.js` (one per clip), `render.mjs`, `sound.py`, `package.json`, `README.md`.
- **App scenes** from `docs/video-frames/scenes.mjs` are SVG; drive them by `t` (replace the rAF loop with `setTime(t)`) and capture each frame. Their screens must keep matching the real app.
- **Real app footage** is simulator recordings (`xcrun simctl io booted recordVideo`), with the launch args in `CLAUDE.md` (`-demoData`, `-stage kid`, `-demoFamily`, `-uiTesting`), status bar set to 9:41. Don't redraw what the app can show for real.
- **Renderer.** Headless Chromium (Playwright, installed in `docs/video/`) draws frames; pipe JPEG frames into ffmpeg: `-c:v libx264 -pix_fmt yuv420p -movflags +faststart`. Fonts: `@fontsource/nunito`, inlined as base64.
- **One timing source.** `film.js` exports `events()` (pops, stamps, transitions, caption in/out). Save to `events.json`; `sound.py` reads it so every sound lands on its frame.
- **Assembly.** Clips plus simulator footage plus voiceover are cut in an editor (iMovie or CapCut) unless asked to assemble in ffmpeg. Deliver each clip as its own MP4 with handles (0.5 s before and after).

## 5. Gates (stop after each and wait for approval)

1. **Maya sheet:** one PNG from `maya.js`: turnaround (front, three-quarter, side, back), the 5 expressions, the poses, palette swatches and the rules in section 3.
2. **Storyboard:** one PNG, one key frame per shot in `docs/demo-video.md`, rendered from the real code (Maya included), each with title, one-line action, timestamp and rubric row.
3. **Draft:** every animated clip at 960×540, 30 fps, no sound, as one contact sheet plus the MP4s.
4. **Final:** 1080p clips, music bed and SFX, captions file (`captions.srt`).

Apply requested changes, then show the same gate again. Never skip a gate.

## 6. Speed rules

- 30 fps. Every check is one contact sheet (`ffmpeg -vf "select=not(mod(n\,15)),scale=480:-1,tile=6x4"`), never frame-by-frame stills.
- One critique pass per gate. Full resolution is rendered once, at the end, in the background; write `sound.py` while it runs.
- Check audio numerically (RMS per 2-second window; music bed peaks under −18 dBFS), don't describe it.
- No extras (web players, alternate cuts) unless asked. Replies: what changed, the file, the next decision.

## 7. Motion and sound

- Ease in and out, overshoot on arrivals, anticipation before big moves, gentle camera push-ins, two or three parallax layers in Maya scenes.
- Designed transitions: the sprout growing to wipe, an iris from the phone screen, a match cut from Maya's phone to the app on the simulator. No plain crossfades except under the voice.
- Music: synthesized in `sound.py` (numpy, write WAV): soft chord pad, bass, light percussion, a lead that changes per act (muted plucks for frustrations, warm keys for the app, a fuller lift for the end). SFX for key actions: phone buzz, alarm beep (soft), skill earned chime, letter whoosh, notification pop. Nothing licensed.

## 8. Delivery

- Clips: H.264 + AAC, 1080p, 30 fps, in `docs/video/out/` (git-ignored).
- Final cut: under the cap, under 30 MB if it must be downloaded from the Claude app (2-pass bitrate re-encode), uploaded unlisted; test the link logged out.
- `docs/video/README.md` lists the four commands: storyboard, draft, sound, final.
