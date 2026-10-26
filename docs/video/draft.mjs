// Gate 3 and the final: renders every shot in film.js to its own MP4 with headless Chrome and ffmpeg.
//   node draft.mjs                 960×540 drafts in out/draft/, plus out/draft/contact.png
//   node draft.mjs --final         1920×1080 in out/final/
//   node draft.mjs 4 12a           only these shots
import { readFileSync, readdirSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn, execFileSync } from "node:child_process";
import { chromium } from "playwright-core";
import { FILM } from "./film.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const final = args.includes("--final");
const only = args.filter((a) => !a.startsWith("--"));
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
const assets = Object.fromEntries(Object.entries(manifest).map(([k, f]) => [k, `data:image/png;base64,${readFileSync(join(HERE, f)).toString("base64")}`]));
const names = [...new Set(FILM.map((s) => s.scene))];

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
  window.frame = (name, t) => {
    const g = big.getContext("2d"); g.save(); g.clearRect(0, 0, 1920, 1080); SCENES[name].render(g, t, ASSETS); g.restore();
    const o = c.getContext("2d"); o.drawImage(big, 0, 0, ${w}, ${h});
    return c.toDataURL("image/jpeg", 0.9).slice(23);
  };
  window.ready = true;
})();
</script>`;

const browser = await chromium.launch({ executablePath: CHROME });
const jobs = FILM.filter((s) => !only.length || only.includes(s.shot));

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
    const b64 = await page.evaluate(([name, t]) => window.frame(name, t), [s.scene, (i / FPS) * speed]);
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

// Contact sheet for the gate: a frame every half second of the whole film, 6 across.
if (!final && !only.length) {
  const list = join(OUT, "list.txt");
  (await import("node:fs")).writeFileSync(list, files.map((f) => `file '${f}'`).join("\n"));
  execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", join(OUT, "film.mp4")]);
  console.log(`wrote ${join(OUT, "film.mp4")}`);
}
