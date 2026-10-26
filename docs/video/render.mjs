// Renders a canvas module to PNG with headless Chrome: node render.mjs <module> <out.png> [t]
// The module exports SIZE = [w, h] and render(ctx, t). Modules are inlined (no imports at runtime).
import { readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const HERE = dirname(fileURLToPath(import.meta.url));
const [name = "sheet", out = "out/maya-sheet.png", t = "0"] = process.argv.slice(2);
const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const font = (w) => readFileSync(join(HERE, `node_modules/@fontsource/nunito/files/nunito-latin-${w}-normal.woff2`)).toString("base64");
const faces = [700, 800, 900].map((w) => `@font-face{font-family:Nunito;font-weight:${w};src:url(data:font/woff2;base64,${font(w)}) format("woff2")}`).join("");
const caveat = readFileSync(join(HERE, "node_modules/@fontsource/caveat/files/caveat-latin-700-normal.woff2")).toString("base64");

// Inline the module graph: maya.js, props.js, then the scene, with import/export lines removed.
const strip = (f) => readFileSync(join(HERE, f), "utf8").replace(/^import .*$/gm, "").replace(/^export /gm, "");
import { readdirSync, existsSync } from "node:fs";
const scenes = ["scenes/common.js", ...readdirSync(join(HERE, "scenes")).filter((f) => f.endsWith(".js") && f !== "common.js").map((f) => `scenes/${f}`)];
const code = ["maya.js", "props.js", ...(name === "sheet" ? [] : [...scenes, "film.js"]), `${name}.js`].map(strip).join("\n");
// Images a module needs: <name>.assets.json maps a name to a file; they load before render as window.ASSETS.
const manifest = existsSync(join(HERE, `${name === "storyboard" ? "film" : name}.assets.json`)) ? JSON.parse(readFileSync(join(HERE, `${name === "storyboard" ? "film" : name}.assets.json`), "utf8")) : {};
// A still that hasn't been recorded yet is left out (the scene draws an empty frame) with a warning.
for (const [k, f] of Object.entries(manifest)) if (!existsSync(join(HERE, f))) { console.warn(`missing still: ${k} (${f})`); delete manifest[k]; }
const assets = Object.fromEntries(Object.entries(manifest).map(([k, f]) => [k, `data:image/${f.endsWith(".jpg") ? "jpeg" : "png"};base64,${readFileSync(join(HERE, f)).toString("base64")}`]));

const html = `<!doctype html><style>${faces}@font-face{font-family:Caveat;font-weight:700;src:url(data:font/woff2;base64,${caveat}) format("woff2")}html,body{margin:0}</style><canvas id="c"></canvas>
<script>
${code}
(async () => {
  await Promise.all([700, 800, 900].map((w) => document.fonts.load(w + " 40px Nunito")).concat(document.fonts.load("700 40px Caveat")));
  const ASSETS = window.ASSETS = {};
  await Promise.all(Object.entries(${JSON.stringify(assets)}).map(([k, src]) => new Promise((ok) => { const i = new Image(); i.onload = ok; i.src = src; ASSETS[k] = i; })));
  const c = document.getElementById("c");
  [c.width, c.height] = SIZE;
  render(c.getContext("2d"), ${Number(t)}, ASSETS);
  window.done = true;
})();
</script>`;

const browser = await chromium.launch({ executablePath: CHROME });
const page = await browser.newPage();
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
await page.setContent(html);
await page.waitForFunction(() => window.done === true || false, null, { timeout: 15000 }).catch(() => {});
mkdirSync(dirname(join(HERE, out)), { recursive: true });
await page.locator("#c").screenshot({ path: join(HERE, out) });
await browser.close();
console.log(errors.length ? errors.join("\n") : `wrote ${out}`);
