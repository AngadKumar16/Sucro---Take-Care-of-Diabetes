// Builds the demo-video figures: node docs/video-frames/build.mjs
// Needs the anatomy skill (set ANATOMY=<path> if it isn't in ~/.claude/skills/anatomy).
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const figures = ["fig1-family-only", "fig2-passcode", "fig3-one-gate"].filter((name) => process.argv.length < 3 || process.argv.slice(2).some((a) => name.startsWith(a)));
for (const name of figures) {
  const { build } = await import(`./${name}.mjs`);
  writeFileSync(join(HERE, `${name}.html`), build("light"));
  console.log("wrote", `${name}.html`);
}
