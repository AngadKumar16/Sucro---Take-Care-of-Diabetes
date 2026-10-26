// Paper: a stop-motion cut-paper look. Pieces move on twos (12 poses a second), "boil" a little
// every pose, cast soft shadows and sit on textured paper. Still frame-deterministic: every wobble
// comes from a hash of the piece and the pose number, never from stored state.
import { C } from "../maya.js";
import { W, H, smooth, backOut, span, text, caption, FONT } from "./common.js";

export const POSE_FPS = 12;
export const pose = (t) => Math.floor(t * POSE_FPS);
export const onTwos = (t) => pose(t) / POSE_FPS;
export const hash = (n) => { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };
// A small per-pose wobble for piece `id`: [dx, dy, rotation].
export const boil = (id, t, amount = 1) => { const p = pose(t); return [(hash(id * 7 + p) - 0.5) * 3 * amount, (hash(id * 13 + p) - 0.5) * 3 * amount, (hash(id * 17 + p) - 0.5) * 0.012 * amount]; };

// Textured paper ground: flat colour, fibres and speckles from a fixed seed.
export function paperGround(ctx, base, { seed = 1, planks = 0 } = {}) {
  ctx.fillStyle = base;
  ctx.fillRect(0, 0, W, H);
  if (planks) for (let i = 0; i < planks; i++) { ctx.fillStyle = `rgba(47,74,59,${0.04 + hash(seed + i) * 0.04})`; ctx.fillRect(0, (i * H) / planks, W, 3); }
  for (let i = 0; i < 1400; i++) {
    const x = hash(seed * 3 + i) * W, y = hash(seed * 5 + i * 1.3) * H, r = 0.6 + hash(i + seed) * 1.6;
    ctx.fillStyle = hash(i * 2 + seed) > 0.5 ? "rgba(255,255,255,.22)" : "rgba(47,74,59,.06)";
    ctx.fillRect(x, y, r * 2, r * 0.6);
  }
  const g = ctx.createRadialGradient(W / 2, H / 2, H * 0.3, W / 2, H / 2, H * 0.95);
  g.addColorStop(0, "rgba(0,0,0,0)"); g.addColorStop(1, "rgba(47,74,59,.18)");
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
}

// A cut-paper piece: shadow under it, then the shapes, then a light cut edge.
export function cut(ctx, x, y, rot, id, t, draw, { lift = 1 } = {}) {
  const [dx, dy, dr] = boil(id, t, 1);
  ctx.save();
  ctx.translate(x + dx, y + dy);
  ctx.rotate(rot + dr);
  ctx.shadowColor = "rgba(30,45,36,.28)";
  ctx.shadowBlur = 10 * lift;
  ctx.shadowOffsetX = 5 * lift;
  ctx.shadowOffsetY = 8 * lift;
  draw(ctx);
  ctx.restore();
}

export function blob(ctx, build, fill) {
  ctx.beginPath(); build(); ctx.fillStyle = fill; ctx.fill();
  ctx.shadowColor = "transparent";
  ctx.lineWidth = 2.5; ctx.strokeStyle = "rgba(255,255,255,.35)"; ctx.stroke();
}

// A piece hops in from `from` to `to` over [a, b] seconds, on twos, landing with a small overshoot.
export function hop(t, a, b, from, to) {
  const k = backOut(span(onTwos(t), a, b));
  return [from[0] + (to[0] - from[0]) * k, from[1] + (to[1] - from[1]) * k, k];
}

// ---- Pieces -----------------------------------------------------------------------------------

export const P = {
  notebook: (c) => { blob(c, () => c.roundRect(-150, -190, 300, 380, 16), "#fffdf6"); for (let i = 0; i < 9; i++) blob(c, () => c.rect(-120, -140 + i * 34, 240, 3), "#cfe0e8"); blob(c, () => c.rect(-112, -190, 4, 380), "#f0b3a5"); },
  meter: (c) => { blob(c, () => c.roundRect(-70, -110, 140, 220, 34), C.cream); blob(c, () => c.roundRect(-48, -84, 96, 70, 12), C.mint); c.shadowColor = "transparent"; c.font = FONT(900, 40); c.fillStyle = C.pine; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText("112", 0, -48); blob(c, () => c.arc(0, 50, 22, 0, Math.PI * 2), C.sage); },
  pen: (c) => { blob(c, () => c.roundRect(-210, -24, 330, 48, 24), C.pine); blob(c, () => c.roundRect(110, -24, 110, 48, 20), C.amber); blob(c, () => c.roundRect(-250, -12, 44, 24, 10), C.cream); blob(c, () => c.roundRect(-120, -10, 90, 20, 8), C.leaf); },
  sensor: (c) => { blob(c, () => c.arc(0, 0, 62, 0, Math.PI * 2), "#ffffff"); blob(c, () => c.arc(0, 0, 36, 0, Math.PI * 2), C.sage); blob(c, () => c.arc(0, 0, 12, 0, Math.PI * 2), C.mint); },
  juice: (c) => { blob(c, () => c.roundRect(-70, -100, 140, 200, 14), C.berry); blob(c, () => c.arc(0, -10, 34, 0, Math.PI * 2), "#f6c2b5"); blob(c, () => c.roundRect(-8, -150, 16, 70, 6), C.leaf); },
  heart: (c) => { blob(c, () => { c.moveTo(0, 30); c.bezierCurveTo(-60, -10, -40, -60, 0, -30); c.bezierCurveTo(40, -60, 60, -10, 0, 30); }, C.berry); },
};



// 4a · Who's it for? Four paper cards are dealt; Kid is picked up.
export const paperDeal = {
  duration: 5,
  line: "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer.",
  render(ctx, t) {
    paperGround(ctx, "#2f6b52", { seed: 21 });
    const cards = [["Kid", C.berry, 1], ["Teen", C.amber, 2], ["Adult", C.leaf, 3], ["Parent", C.mint, 4]];
    cards.forEach(([name, col, n], i) => {
      const a = 0.3 + i * 0.5, to = [420 + i * 360, 520], [x, y, k] = hop(t, a, a + 0.42, [W / 2, -300], to);
      if (k <= 0) return;
      const picked = i === 0 && t > 3;
      const lift = picked ? smooth(span(onTwos(t), 3, 3.5)) : 0;
      cut(ctx, x, y - lift * 70, (hash(i * 3) - 0.5) * 0.14 * (1 - lift), 100 + i, t, (c) => {
        blob(c, () => c.roundRect(-140, -190, 280, 380, 28), C.cream);
        blob(c, () => c.roundRect(-110, -160, 220, 200, 22), col);
        // Growth stage drawn as more leaves for each step.
        for (let l = 0; l < n; l++) blob(c, () => c.ellipse(-50 + l * 34, -60 - (l % 2) * 22, 26, 14, (l % 2 ? 0.6 : -0.6), 0, Math.PI * 2), C.pine);
        c.shadowColor = "transparent"; c.font = FONT(900, 56); c.fillStyle = C.ink; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText(name, 0, 110);
      }, { lift: 1 + lift * 2.5 });
    });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

