# Demo video: clips

Code for the animated parts of the CAC demo video. The plan (script, timing, shots) is `../demo-video.md`; the rules are the `diabetescare-video` skill.

Setup: `npm install` (uses your installed Google Chrome; set `CHROME=<path>` if it's elsewhere).

| Step | Command | Output |
|---|---|---|
| Maya sheet | `node render.mjs sheet out/maya-sheet.png` | character sheet |
| Storyboard | `node render.mjs storyboard out/storyboard.png` | one key frame per shot |
| Code on screen | `python3 sync-source.py` | `scenes/source.js` (the app's real Swift) |
| District numbers | `python3 district-stat.py` | prints the TX-22 estimate; rewrites `scenes/geo.js` |
| Test wall | `python3 sync-tests.py <xcresult>…` | `scenes/tests.js` (every passing test, for shot 11) |
| Plan times | `node sync-times.mjs` | rewrites the Time column in `../demo-video.md` from `film.js` |
| Scratch voice | `python3 scratch-vo.py` | `out/draft/scratch-vo.wav` |
| Draft | `node draft.mjs` (`node draft.mjs 4 12a` for some shots, `--join` to rejoin) | `out/draft/<shot>-<scene>.mp4`, `film.mp4` |
| Final clips | `node draft.mjs --final` | `out/final/` (1080p) |
| Music | `python3 sound.py` | `out/music.wav` (original, made in code; peaks at -18 dBFS) |
| Final cut | `node draft.mjs --final`, then mux `out/final/film.mp4` + `out/music.wav` | `out/final/DiabetesCare-CAC-2026.mp4` |

- `maya.js`: Maya, drawn in code. `props.js`: chair, table, bed.
- `scenes/`: one `render(ctx, t)` clip per Maya shot, plus shared helpers (`common.js`).
- `render.mjs`: renders a module to PNG in headless Chrome; images in `film.assets.json` load first.
- `film.js`: the shots in order with their length in the cut. `draft.mjs` renders them.
- `scenes/scrap.js` (Scrapbook), `scenes/hype.js` (Hype), `scenes/district.js` (2d), `scenes/code.js` (`sideCode`: the code card beside the app).
