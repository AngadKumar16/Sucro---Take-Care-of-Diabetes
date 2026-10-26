// Rewrites the Time column of the shot table in docs/demo-video.md from film.js, and the film's
// length in its first paragraph: node sync-times.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { timeline } from "./film.js";

const path = new URL("../demo-video.md", import.meta.url);
const mmss = (x) => { const m = Math.floor(x / 60), r = x - m * 60; return `${m}:${String(Math.floor(r)).padStart(2, "0")}${r % 1 ? "." + String(Math.round((r % 1) * 10)) : ""}`; };
const shots = timeline();
let md = readFileSync(path, "utf8");
for (const s of shots) md = md.replace(new RegExp(`^\\| ${s.shot} \\| [^|]* \\|`, "m"), `| ${s.shot} | ${mmss(s.start)}–${mmss(s.start + s.dur)} |`);
const end = shots.at(-1).start + shots.at(-1).dur;
md = md.replace(/Length \d:\d\d(\.\d)?/, `Length ${mmss(end)}`);
writeFileSync(path, md);
console.log(`film is ${mmss(end)}`);
