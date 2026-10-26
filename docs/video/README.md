# Demo video: clips

Code for the animated parts of the CAC demo video. The plan (script, timing, shots) is `../demo-video.md`; the rules are the `diabetescare-video` skill.

Setup: `npm install` (uses your installed Google Chrome; set `CHROME=<path>` if it's elsewhere).

| Step | Command | Output |
|---|---|---|
| Maya sheet | `node render.mjs sheet out/maya-sheet.png` | character sheet |
| Storyboard | `node render.mjs storyboard out/storyboard.png` | one key frame per shot |
| Draft | `node draft.mjs` (`node draft.mjs 4 12a` for some shots) | `out/draft/<shot>-<scene>.mp4`, `film.mp4` |
| Final clips | `node draft.mjs --final` | `out/final/` (1080p) |
| Sound | to come (`sound.py`) | |

- `maya.js`: Maya, drawn in code. `props.js`: chair, table, bed.
- `scenes/`: one `render(ctx, t)` clip per Maya shot, plus shared helpers (`common.js`).
- `render.mjs`: renders a module to PNG in headless Chrome; images in `film.assets.json` load first.
- `film.js`: the shots in order with their length in the cut. `draft.mjs` renders them.
