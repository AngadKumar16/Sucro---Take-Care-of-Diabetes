// Shared setup for the demo-video figures. Built with the anatomy skill's kit:
// ANATOMY=<path to the skill> node docs/video-frames/build.mjs
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

export const ANATOMY = process.env.ANATOMY ?? join(homedir(), ".claude/skills/anatomy");
export const k = await import(pathToFileURL(join(ANATOMY, "kit/iso-kit.mjs")).href);
export const { kitScript } = await import(pathToFileURL(join(ANATOMY, "scripts/inline-kit.mjs")).href);

// DiabetesCare's soft greens on the light theme. Accent is the app's AccentColor (#1F6B4A).
export const GREEN_CSS = `
.iso[data-theme="light"]{
  --anatomy-page:#eef3ee;--anatomy-card:#fbfcf9;--anatomy-text:#4c5f54;--anatomy-strong:#17291f;--anatomy-muted:#8a9b90;
  --anatomy-paper:#fbfcf9;--anatomy-face:#ffffff;--anatomy-top:#ffffff;
  --anatomy-shade-0:#d3e0d6;--anatomy-shade-1:#dfe9e1;--anatomy-shade-2:#e9f0ea;--anatomy-shade-3:#f2f6f2;
  --anatomy-lit-top:#e8f5ec;--anatomy-lit-shade:#d2e9da;
  --anatomy-hi:#1f3a2c;--anatomy-mid:#7d978a;--anatomy-lo:#b3c6ba;--anatomy-faint:#d5e1d8;--anatomy-lit:#1f6b4a;
  --anatomy-halo:#5f7d68;--anatomy-halo-opacity:.3;--anatomy-dot:#2f4a3b;
  --anatomy-green:#1f6b4a;--anatomy-red:#c8553d;
}
.iso-plate{border-radius:22px}
`;

export function helpers(P) {
  const at = (point) => k.iso(point, P);
  const byDepth = (points) => [...points].sort((a, b) => k.depthOf([a[0], a[1], 0], P) - k.depthOf([b[0], b[1], 0], P));
  const S = (paths, style) => k.solidSvg(paths, style);
  const L = (d, style) => k.lineSvg(d, style);
  const D = (points, style) => k.dotsSvg(points, style);

  // Base plate on four feet with a groove, corner screws, a ruler strip along the front and a label plate.
  function plate(PLATE, { h = 10, foot = 5, ruler = null, label = null } = {}) {
    const out = [`<path class="iso-halo" d="${k.haloOf(PLATE, -h - foot, h, P)}"/>`];
    for (const [x, y] of byDepth(k.corners(PLATE, 20))) {
      out.push(S(k.cylinder(x, y, 6.6, -h - foot, 1.6, P, 28), { tone: "lo" }));
      out.push(S(k.cylinder(x, y, 5, -h - foot + 1.6, foot - 1.6, P, 28), { tone: "mid" }));
    }
    out.push(S(k.slabOf(PLATE, -h, h, P, 10, 1.6), { tone: "mid" }));
    out.push(L(k.planOutline(k.insetPlan(PLATE, 5), 0, P, 10), { tone: "faint" }));
    const screws = k.corners(PLATE, 10);
    out.push(L(screws.map(([x, y]) => k.ring(x, y, 2.2, 0, P, 16)).join(""), { tone: "lo" }));
    out.push(D(screws.map(([x, y]) => at([x, y, 0])), { size: 0.5 }));
    if (ruler) {
      out.push(S(k.slabOf(ruler, 0, 0.6, P, 3), { tone: "lo", crease: "none" }));
      const t = k.topTicks(ruler.x + 4, ruler.x + ruler.w - 4, 4, 5, ruler.y + 0.8, 0.6, [2, 3.6], P);
      out.push(L(t.minor, { tone: "lo" }), L(t.major, { tone: "mid" }));
      out.push(D([at([ruler.x + 2, ruler.y + 3.5, 0.6]), at([ruler.x + ruler.w - 2, ruler.y + 3.5, 0.6])], { size: 0.45 }));
    }
    if (label) out.push(labelPlate(label, 0));
    return out.join("");
  }

  function labelPlate(plan, z) {
    const out = [S(k.slabOf(plan, z, 0.8, P, 4), { tone: "lo", crease: "none" })];
    out.push(L(k.planOutline(k.insetPlan(plan, 1.6), z + 0.8, P, 4), { tone: "faint" }));
    const y0 = plan.y + plan.d * 0.3;
    [0.7, 0.5, 0.6].forEach((share, i) => {
      const y = y0 + i * plan.d * 0.2;
      out.push(L(k.lineOnTop([plan.x + 4, y], [plan.x + 4 + (plan.w - 8) * share, y], z + 0.8, P), { tone: "lo", free: true }));
    });
    out.push(D([at([plan.x + plan.w - 3, plan.y + 3, z + 0.8]), at([plan.x + plan.w - 3, plan.y + plan.d - 3, z + 0.8])], { size: 0.4 }));
    return out.join("");
  }

  function knob(x, y, z, r = 5, h = 4) {
    return [
      S(k.cylinder(x, y, r, z, h, P, 32), { tone: "mid" }),
      L(k.knurl(x, y, r, z, z + h, 30, P), { tone: "lo" }),
    ].join("");
  }

  return { at, byDepth, S, L, D, plate, labelPlate, knob };
}

export function page({ k, title, theme, body, live }) {
  return k
    .pageHtml({ title, theme, body, script: kitScript() + live })
    .replace("</style>", `${GREEN_CSS}</style>`);
}
