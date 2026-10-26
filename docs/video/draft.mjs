// Gate 3 and the final: renders every shot in film.js to its own MP4 with headless Chrome and ffmpeg.
//   node draft.mjs                 960×540 drafts in out/draft/, plus out/draft/contact.png
//   node draft.mjs --final         1920×1080 in out/final/
//   node draft.mjs 4 12a           only these shots
//   node draft.mjs --join          join the clips already rendered into film.mp4
import { readFileSync, readdirSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn, execFileSync } from "node:child_process";
import { chromium } from "playwright-core";
import { FILM, XF, timeline } from "./film.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const final = args.includes("--final");
const only = args.filter((a) => !a.startsWith("--"));
const joinOnly = args.includes("--join");
const [w, h] = final ? [1920, 1080] : [960, 540];
const FPS = 30, OUT = join(HERE, "out", final ? "final" : "draft");
const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
mkdirSync(OUT, { recursive: true });

const font = (wt) => readFileSync(join(HERE, `node_modules/@fontsource/nunito/files/nunito-latin-${wt}-normal.woff2`)).toString("base64");
const faces = [700, 800, 900].map((wt) => `@font-face{font-family:Nunito;font-weight:${wt};src:url(data:font/woff2;base64,${font(wt)}) format("woff2")}`).join("");
const caveat = readFileSync(join(HERE, "node_modules/@fontsource/caveat/files/caveat-latin-700-normal.woff2")).toString("base64");
const strip = (f) => readFileSync(join(HERE, f), "utf8").replace(/^import .*$/gm, "").replace(/^export /gm, "");
const scenes = ["scenes/common.js", ...readdirSync(join(HERE, "scenes")).filter((f) => f.endsWith(".js") && f !== "common.js").map((f) => `scenes/${f}`)];
const code = ["maya.js", "props.js", ...scenes].map(strip).join("\n");
const manifest = JSON.parse(readFileSync(join(HERE, "film.assets.json"), "utf8"));
// A still that hasn't been recorded yet is left out (the scene draws an empty frame) with a warning.
for (const [k, f] of Object.entries(manifest)) if (!existsSync(join(HERE, f))) { console.warn(`missing still: ${k} (${f})`); delete manifest[k]; }
const assets = Object.fromEntries(Object.entries(manifest).map(([k, f]) => [k, `data:image/${f.endsWith(".jpg") ? "jpeg" : "png"};base64,${readFileSync(join(HERE, f)).toString("base64")}`]));
const names = [...new Set(FILM.map((s) => s.scene))];
// Caption phrases timed to the voiceover (vo-mix.py), when it has run.
const CUES = existsSync(join(HERE, "out", "captions.json")) ? JSON.parse(readFileSync(join(HERE, "out", "captions.json"), "utf8")) : {};

const html = `<!doctype html><style>${faces}@font-face{font-family:Caveat;font-weight:700;src:url(data:font/woff2;base64,${caveat}) format("woff2")}html,body{margin:0}</style><canvas id="c"></canvas>
<script>
${code}
const SCENES = { ${names.join(", ")} };
(async () => {
  await Promise.all([700, 800, 900].map((wt) => document.fonts.load(wt + " 40px Nunito")).concat(document.fonts.load("700 40px Caveat")));
  const ASSETS = window.ASSETS = {};
  await Promise.all(Object.entries(${JSON.stringify(assets)}).map(([k, src]) => new Promise((ok) => { const i = new Image(); i.onload = ok; i.src = src; ASSETS[k] = i; })));
  const big = document.createElement("canvas"); big.width = 1920; big.height = 1080;
  const c = document.getElementById("c"); c.width = ${w}; c.height = ${h};
  window.frame = (name, t, gate = 1, ct = 0, cap = null, cues = null) => {
    window.CAPTION_GATE = gate; window.CLIP_T = ct; window.CAPTION_STYLE = cap; window.CAPTION_CUES = cues;
    const g = big.getContext("2d"); g.save(); g.clearRect(0, 0, 1920, 1080); SCENES[name].render(g, t, ASSETS); g.restore();
    const o = c.getContext("2d"); o.drawImage(big, 0, 0, ${w}, ${h});
    return c.toDataURL("image/jpeg", 0.9).slice(23);
  };
  window.ready = true;
})();
</script>`;

const browser = await chromium.launch({ executablePath: CHROME });
const jobs = joinOnly ? [] : FILM.filter((s) => !only.length || only.includes(s.shot));

async function renderShot(s) {
  const page = await browser.newPage();
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  await page.setContent(html);
  await page.waitForFunction(() => window.ready === true, null, { timeout: 30000 });
  const sceneDur = await page.evaluate((n) => SCENES[n].duration, s.scene);
  const file = join(OUT, `${s.shot}-${s.scene}.mp4`);
  const ff = spawn("ffmpeg", ["-v", "error", "-y", "-f", "image2pipe", "-framerate", String(FPS), "-c:v", "mjpeg", "-i", "-",
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", final ? "slow" : "veryfast", "-crf", final ? "16" : "23", "-movflags", "+faststart", file]);
  const n = Math.round(s.dur * FPS), speed = sceneDur / s.dur;
  for (let i = 0; i < n; i++) {
    // Captions: in after the incoming blend, out before the outgoing one (no fade at the film's ends).
    const ct = i / FPS, first = s === FILM[0], last = s === FILM.at(-1);
    const gate = Math.min(first ? 1 : Math.min(1, Math.max(0, (ct - XF) / 0.25)), last ? 1 : Math.min(1, Math.max(0, (s.dur - XF - ct) / 0.2)));
    const b64 = await page.evaluate(([name, t, g, c, cap, cues]) => window.frame(name, t, g, c, cap, cues), [s.scene, ct * speed, gate, ct, s.cap ?? null, CUES[s.shot] ?? null]);
    if (!ff.stdin.write(Buffer.from(b64, "base64"))) await new Promise((ok) => ff.stdin.once("drain", ok));
  }
  ff.stdin.end();
  await new Promise((ok) => ff.on("close", ok));
  await page.close();
  console.log(`${s.shot} ${s.scene} ${s.dur}s${speed !== 1 ? ` (×${speed.toFixed(2)})` : ""}${errors.length ? "  ERRORS: " + errors.join("; ") : ""}`);
  return file;
}

// Four shots at a time.
const files = [];
for (let i = 0; i < jobs.length; i += 4) files.push(...(await Promise.all(jobs.slice(i, i + 4).map(renderShot))));
await browser.close();

// The cut: every shot joined with its transition (film.js), overlapping by XF seconds, so shots
// flow into each other instead of hard-cutting. `node draft.mjs --join` rejoins without rendering.
if (!only.length || args.includes("--join")) {
  const clips = FILM.map((s) => join(OUT, `${s.shot}-${s.scene}.mp4`));
  const starts = timeline().map((s) => s.start);
  let graph = "", last = "[0:v]";
  FILM.slice(1).forEach((s, i) => {
    const out = i === FILM.length - 2 ? "[v]" : `[x${i}]`;
    graph += `${last}[${i + 1}:v]xfade=transition=${s.in ?? "fade"}:duration=${XF}:offset=${starts[i + 1].toFixed(3)}${out};`;
    last = out;
  });
  execFileSync("ffmpeg", ["-v", "error", "-y", ...clips.flatMap((c) => ["-i", c]), "-filter_complex", graph.slice(0, -1), "-map", "[v]",
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", final ? "slow" : "veryfast", "-crf", final ? "16" : "23", "-movflags", "+faststart", join(OUT, "film.mp4")]);
  console.log(`wrote ${join(OUT, "film.mp4")}`);
}
