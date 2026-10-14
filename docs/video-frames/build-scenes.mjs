// Builds the animated app scenes: node docs/video-frames/build-scenes.mjs
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { today, help, family } from "./scenes.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
for (const [name, build] of [["scene1-today", today], ["scene2-feeling-off", help], ["scene3-family", family]]) {
  writeFileSync(join(HERE, `${name}.html`), build("light"));
  console.log("wrote", `${name}.html`);
}
