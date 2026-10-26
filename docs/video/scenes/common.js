// Shared helpers for every clip: easing, the caption card, the "made up" corner card, rooms.
import { C } from "../maya.js";

export const W = 1920, H = 1080, FLOOR = 900;
export const FONT = (weight, size) => `${weight} ${size}px Nunito, ui-rounded, system-ui, sans-serif`;

export const clamp01 = (v) => Math.max(0, Math.min(1, v));
export const smooth = (v) => { const x = clamp01(v); return x * x * (3 - 2 * x); };
// Ease out with a small overshoot, for arrivals.
export const backOut = (v) => { const x = clamp01(v), s = 1.6; return 1 + (s + 1) * Math.pow(x - 1, 3) + s * Math.pow(x - 1, 2); };
// 0 → 1 between a and b seconds.
export const span = (t, a, b) => clamp01((t - a) / (b - a));

export function pushIn(ctx, t, duration, amount = 0.045, cx = W / 2, cy = H / 2) {
  const k = 1 + amount * smooth(t / duration);
  ctx.translate(cx, cy);
  ctx.scale(k, k);
  ctx.translate(-cx, -cy);
}

export function rr(ctx, x, y, w, h, r, fill, stroke = C.ink, lw = 4) {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
  if (fill) { ctx.fillStyle = fill; ctx.fill(); }
  if (stroke) { ctx.lineWidth = lw; ctx.strokeStyle = stroke; ctx.lineJoin = "round"; ctx.stroke(); }
}

export function text(ctx, s, x, y, { size = 44, weight = 800, color = C.ink, align = "center", base = "middle" } = {}) {
  ctx.font = FONT(weight, size);
  ctx.fillStyle = color;
  ctx.textAlign = align;
  ctx.textBaseline = base;
  ctx.fillText(s, x, y);
}

// The burned-in caption: Nunito 800, 46 px, on a cream card in the bottom third.
// CAPTION_GATE (set by draft.mjs per frame) fades a shot's caption out before the cut and in after
// it, so two shots' captions never show at once while they blend.
export function caption(ctx, line, alpha = 1) {
  alpha *= globalThis.CAPTION_GATE ?? 1;
  const cap = globalThis.CAPTION_STYLE;
  if (cap && cap.mode !== "card" && globalThis.CAPTION_CUES) return phraseCaption(ctx, cap, globalThis.CAPTION_CUES, globalThis.CLIP_T ?? 0);
  if (!line || alpha <= 0) return;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.font = FONT(800, 46);
  const words = line.split(" "), lines = [];
  let cur = "";
  for (const w of words) { const next = cur ? cur + " " + w : w; if (ctx.measureText(next).width > 1440 && cur) { lines.push(cur); cur = w; } else cur = next; }
  lines.push(cur);
  const width = Math.max(...lines.map((l) => ctx.measureText(l).width)) + 80, height = lines.length * 60 + 36;
  rr(ctx, (W - width) / 2, 1040 - height, width, height, 28, "rgba(251,248,241,.94)", null);
  lines.forEach((l, i) => text(ctx, l, W / 2, 1040 - height + 48 + i * 60, { size: 46 }));
  ctx.restore();
}

export function cornerCard(ctx, s, alpha = 1) {
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.font = FONT(800, 32);
  const w = ctx.measureText(s).width + 56;
  rr(ctx, 56, 52, w, 64, 32, "rgba(251,248,241,.94)", C.ink, 3);
  text(ctx, s, 56 + w / 2, 85, { size: 32 });
  ctx.restore();
}

// A plain room: wall, a skirting line and a floor.
export function room(ctx, wall, floor) {
  ctx.fillStyle = wall;
  ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = floor;
  ctx.fillRect(0, FLOOR, W, H - FLOOR);
  ctx.fillStyle = "rgba(47,74,59,.12)";
  ctx.fillRect(0, FLOOR - 6, W, 6);
}

export function windowFrame(ctx, x, y, w, h, sky) {
  rr(ctx, x - 14, y - 14, w + 28, h + 28, 24, C.cream);
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  sky.forEach(([at, c]) => g.addColorStop(at, c));
  rr(ctx, x, y, w, h, 14, g);
  ctx.beginPath();
  ctx.moveTo(x + w / 2, y); ctx.lineTo(x + w / 2, y + h);
  ctx.moveTo(x, y + h / 2); ctx.lineTo(x + w, y + h / 2);
  ctx.lineWidth = 8; ctx.strokeStyle = C.cream; ctx.stroke();
}

// A round wall clock; `minutes` past midnight, the second hand from t.
export function wallClock(ctx, x, y, r, minutes, t) {
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fillStyle = C.cream; ctx.fill(); ctx.lineWidth = 5; ctx.strokeStyle = C.ink; ctx.stroke();
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    ctx.beginPath(); ctx.moveTo(x + Math.sin(a) * r * 0.8, y - Math.cos(a) * r * 0.8); ctx.lineTo(x + Math.sin(a) * r * 0.9, y - Math.cos(a) * r * 0.9);
    ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke();
  }
  const hand = (a, len, w, c) => { ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + Math.sin(a) * len, y - Math.cos(a) * len); ctx.lineWidth = w; ctx.lineCap = "round"; ctx.strokeStyle = c; ctx.stroke(); };
  hand(((minutes / 60) % 12) / 12 * Math.PI * 2, r * 0.5, 7, C.ink);
  hand((minutes % 60) / 60 * Math.PI * 2, r * 0.72, 5, C.ink);
  hand((Math.floor(t) % 60) / 60 * Math.PI * 2, r * 0.78, 2.5, C.berry);
  ctx.beginPath(); ctx.arc(x, y, 6, 0, Math.PI * 2); ctx.fillStyle = C.ink; ctx.fill();
}

// A classmate in the background: an original, simpler figure (no face details), so Maya stays the focus.
export function classmate(ctx, x, y, s, body, hair) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  rr(ctx, -46, -150, 92, 150, 40, body);
  ctx.beginPath(); ctx.arc(0, -196, 44, 0, Math.PI * 2); ctx.fillStyle = C.skin; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke();
  ctx.beginPath(); ctx.arc(0, -206, 46, Math.PI * 1.05, Math.PI * 1.95); ctx.lineTo(30, -214); ctx.closePath(); ctx.fillStyle = hair; ctx.fill(); ctx.stroke();
  ctx.restore();
}

// A phone notification bubble (iMessage-like, but in the app's palette).
export function textBubble(ctx, x, y, from, msg, s = 1) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  rr(ctx, -250, -58, 500, 116, 30, "#ffffff", C.ink, 4);
  ctx.beginPath(); ctx.arc(-196, 0, 30, 0, Math.PI * 2); ctx.fillStyle = C.mint; ctx.fill(); ctx.lineWidth = 3; ctx.strokeStyle = C.ink; ctx.stroke();
  text(ctx, from[0], -196, 2, { size: 30, weight: 900, color: C.pine });
  text(ctx, from, -150, -20, { size: 26, weight: 800, color: "#6f8277", align: "left" });
  text(ctx, msg, -150, 18, { size: 34, weight: 900, align: "left" });
  ctx.restore();
}

// Draws `draw` on its own layer and lays it over the frame at `alpha`, keeping the current
// transform, so two poses or two expressions can cross-fade without either showing through.
const LAYERS = [];
export function fadeLayer(ctx, alpha, draw, slot = 0) {
  if (alpha <= 0) return;
  if (alpha >= 1) { draw(ctx); return; }
  if (!LAYERS[slot]) { LAYERS[slot] = document.createElement("canvas"); LAYERS[slot].width = W; LAYERS[slot].height = H; }
  const g = LAYERS[slot].getContext("2d");
  g.setTransform(1, 0, 0, 1, 0, 0); g.clearRect(0, 0, W, H);
  g.setTransform(ctx.getTransform());
  draw(g);
  ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha *= alpha; ctx.drawImage(LAYERS[slot], 0, 0); ctx.restore();
}

// Phrase captions, timed to the voice (out/captions.json, from vo-mix.py): one phrase at a time,
// easing in with a small rise. "float" = big words with an ink outline placed in open space;
// "paper" = the phrase on a taped paper strip, for the scrapbook pages.
function wrap(ctx, s, w) {
  const out = []; let cur = "";
  for (const word of s.split(" ")) { const next = cur ? cur + " " + word : word; if (ctx.measureText(next).width > w && cur) { out.push(cur); cur = word; } else cur = next; }
  out.push(cur); return out;
}
function phraseCaption(ctx, cap, cues, t) {
  const cue = cues.find(([a, b]) => t >= a - 0.05 && t < b);
  if (!cue) return;
  const [a, b, s] = cue;
  const k = smooth(span(t, a - 0.05, a + 0.15)) * (1 - smooth(span(t, b - 0.12, b)));
  if (k <= 0) return;
  ctx.save();
  ctx.globalAlpha = k;
  ctx.translate(cap.x, cap.y + (1 - k) * 12);
  if (cap.mode === "float") {
    const size = cap.size ?? 54;
    ctx.font = FONT(900, size);
    const lines = wrap(ctx, s, cap.w ?? 900), lh = size * 1.18;
    ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.lineJoin = "round";
    lines.forEach((l, i) => {
      const y = (i - (lines.length - 1) / 2) * lh;
      ctx.shadowColor = "rgba(20,35,28,.45)"; ctx.shadowBlur = 14; ctx.shadowOffsetY = 4;
      ctx.lineWidth = size * 0.13; ctx.strokeStyle = "rgba(31,48,39,.95)"; ctx.strokeText(l, 0, y);
      ctx.shadowColor = "transparent";
      ctx.fillStyle = "#fffdf6"; ctx.fillText(l, 0, y);
    });
  } else {
    ctx.font = FONT(800, 46);
    const w = Math.min(1500, ctx.measureText(s).width + 70), h = 84;
    ctx.rotate(-0.012);
    ctx.shadowColor = "rgba(60,40,20,.28)"; ctx.shadowBlur = 12; ctx.shadowOffsetY = 6;
    ctx.fillStyle = "#ffffff"; ctx.fillRect(-w / 2, -h / 2, w, h);
    ctx.shadowColor = "transparent";
    ctx.fillStyle = "rgba(191,224,201,.85)"; ctx.fillRect(-w / 2 - 26, -h / 2 - 8, 70, 30);
    ctx.fillStyle = "rgba(242,184,168,.85)"; ctx.fillRect(w / 2 - 44, h / 2 - 22, 70, 30);
    text(ctx, s, 0, 3, { size: 46, weight: 800 });
  }
  ctx.restore();
}
