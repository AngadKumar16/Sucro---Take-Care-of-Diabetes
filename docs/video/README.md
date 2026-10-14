# Demo video: clips

Code for the animated parts of the CAC demo video. The plan (script, timing, shots) is `../demo-video.md`; the rules are the `diabetescare-video` skill.

Setup: `npm install` (uses your installed Google Chrome; set `CHROME=<path>` if it's elsewhere).

| Step | Command | Output |
|---|---|---|
| Maya sheet | `node render.mjs sheet out/maya-sheet.png` | character sheet |
| Storyboard | `node render.mjs storyboard out/storyboard.png` | one key frame per shot |
| Draft | to come (960×540, 30 fps clips) | `out/draft/` |
| Sound, final | to come (`sound.py`, 1080p clips) | `out/final/` |

- `maya.js`: Maya, drawn in code. `props.js`: chair, table, bed.
- `scenes/`: one `render(ctx, t)` clip per Maya shot, plus shared helpers (`common.js`).
- `render.mjs`: renders a module to PNG in headless Chrome; images listed in `<module>.assets.json` are loaded first.
