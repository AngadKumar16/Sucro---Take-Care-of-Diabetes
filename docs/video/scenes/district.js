// 2d · Why it matters here: Texas draws in, the camera dives into Texas's 22nd district, and the
// district fills with dots, one per thousand adults; the ones with diabetes light up as the count
// runs. Numbers from `district-stat.py` (CDC PLACES) and CDC's National Diabetes Statistics Report.
import { C } from "../maya.js";
import { W, H, smooth, span, rr, text, caption, FONT } from "./common.js";
import { hash } from "./paper.js";
import { hypeBg, slam, burst, shake } from "./hype.js";
import { GEO } from "./geo.js";

const ADULTS = 554, WITH = 64; // thousands, rounded from district-stat.py

const bbox = (pts) => pts.reduce((b, [x, y]) => [Math.min(b[0], x), Math.min(b[1], y), Math.max(b[2], x), Math.max(b[3], y)], [Infinity, Infinity, -Infinity, -Infinity]);
const KX = Math.cos((30 * Math.PI) / 180); // longitude shrink at Texas's latitude

// The view that fits box b into the screen rect [x, y, w, h]: [scale, lon0, lat0, cx, cy].
function fit(b, [x, y, w, h]) {
  const s = Math.min(w / ((b[2] - b[0]) * KX), h / (b[3] - b[1]));
  return [s, (b[0] + b[2]) / 2, (b[1] + b[3]) / 2, x + w / 2, y + h / 2];
}
const project = ([s, lon0, lat0, cx, cy], [lon, lat]) => [cx + (lon - lon0) * KX * s, cy - (lat - lat0) * s];

function inside([x, y], poly) {
  let c = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i], [xj, yj] = poly[j];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
}

// About ADULTS dots on a grid inside the district; WITH of them, picked by a fixed hash, light up.
let DOTS = null;
function dots() {
  if (DOTS) return DOTS;
  const b = bbox(GEO.tx22);
  let best = null;
  for (let step = 0.02; step < 0.1; step += 0.0005) {
    const pts = [];
    for (let lat = b[1] + step / 2; lat < b[3]; lat += step) for (let lon = b[0] + step / (2 * KX); lon < b[2]; lon += step / KX) if (inside([lon, lat], GEO.tx22)) pts.push([lon, lat]);
    if (!best || Math.abs(pts.length - ADULTS) < Math.abs(best.pts.length - ADULTS)) best = { pts, step };
    if (pts.length < ADULTS) break;
  }
  const order = best.pts.map((p, i) => [hash(i * 3.7 + 1), i]).sort((a, b2) => a[0] - b2[0]).map(([, i]) => i);
  const lit = new Map(order.slice(0, WITH).map((i, k) => [i, k]));
  return (DOTS = { pts: best.pts, step: best.step, lit });
}

function path(ctx, view, pts, k = 1) {
  const n = Math.max(2, Math.floor(pts.length * k));
  ctx.beginPath();
  for (let i = 0; i < n; i++) { const [x, y] = project(view, pts[i]); i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
  if (k >= 1) ctx.closePath();
}

// The camera between two views: scale eases in log space so a big zoom feels like a camera move.
function between(a, b, k) {
  return [Math.exp(Math.log(a[0]) * (1 - k) + Math.log(b[0]) * k), a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k, a[4] + (b[4] - a[4]) * k];
}

// A citation under a number, small but readable.
function cite(ctx, s, x, y, alpha) {
  if (alpha <= 0) return;
  ctx.save(); ctx.globalAlpha = alpha;
  ctx.font = FONT(700, 21);
  const w = ctx.measureText(s).width + 30;
  rr(ctx, x - w / 2, y - 17, w, 34, 17, "rgba(15,34,25,.8)", "rgba(191,224,201,.35)", 2);
  text(ctx, s, x, y + 1, { size: 21, weight: 700, color: "#cfe0d6" });
  ctx.restore();
}

export const district = {
  duration: 12.5,
  line: "According to the CDC, about 64,000 adults in my district, Texas's 22nd, live with diabetes. And across the country, 314,000 kids and teens have type 1.",
  render(ctx, t) {
    const hits = [3, 7.6];
    ctx.save();
    shake(ctx, t, hits, 8);
    hypeBg(ctx, t, { tint: "#1f4a37" });
    const MAP = [90, 110, 1000, 720];
    const vTX = fit(bbox(GEO.texas), MAP), vD = fit(bbox(GEO.tx22), [140, 130, 900, 680]);
    const vUS = fit([-125, 18, -66, 49.5], [60, 170, 1060, 640]);
    // Texas → dive into TX-22 → pull all the way out to the country.
    const zin = smooth(span(t, 1.2, 2.8)), zout = smooth(span(t, 6.4, 8));
    const view = zout > 0 ? between(vD, vUS, zout) : between(vTX, vD, zin);
    ctx.save();
    ctx.lineJoin = "round";
    // The country, as the camera pulls out: every state, Texas picked out.
    const usA = smooth(span(t, 6.8, 7.8));
    if (usA > 0) {
      for (const ring of GEO.us) { path(ctx, view, ring); ctx.fillStyle = `rgba(191,224,201,${0.1 * usA})`; ctx.fill(); ctx.lineWidth = 2; ctx.strokeStyle = `rgba(191,224,201,${0.55 * usA})`; ctx.stroke(); }
      path(ctx, view, GEO.texas); ctx.fillStyle = `rgba(95,167,126,${0.35 * usA})`; ctx.fill();
    }
    // Texas fades as the camera dives in (its coastline is simplified and would cut the district),
    // and comes back with the country.
    const tx = Math.max(1 - smooth(span(t, 1.6, 2.4)), usA);
    if (tx > 0) {
      path(ctx, view, GEO.texas, smooth(span(t, 0, 1)));
      ctx.fillStyle = `rgba(191,224,201,${0.08 * tx * smooth(span(t, 0.8, 1.2))})`; ctx.fill();
      ctx.lineWidth = 4; ctx.strokeStyle = `rgba(191,224,201,${0.75 * tx})`; ctx.stroke();
    }
    const d = smooth(span(t, 0.8, 1.3));
    if (d > 0) {
      path(ctx, view, GEO.tx22);
      ctx.fillStyle = `rgba(95,167,126,${0.35 * d})`; ctx.fill();
      ctx.lineWidth = zout > 0.5 ? 3 : 5; ctx.strokeStyle = `rgba(242,201,76,${d})`; ctx.stroke();
    }
    ctx.restore();
    // The dots: one per thousand adults; the lit ones (diabetes) count up with the number.
    const { pts, step, lit } = dots();
    const show = smooth(span(t, 2.6, 3.2)) * (1 - smooth(span(t, 6.4, 7)));
    if (show > 0) {
      const r = Math.max(3, step * view[0] * 0.3);
      const count = smooth(span(t, 3, 5.6));
      pts.forEach((p, i) => {
        const [x, y] = project(view, p), k = lit.get(i);
        const on = k !== undefined && k < count * WITH;
        ctx.save(); ctx.globalAlpha = show;
        ctx.beginPath(); ctx.arc(x, y, r * (on ? 1.35 : 1), 0, Math.PI * 2);
        ctx.fillStyle = on ? C.berry : "rgba(251,248,241,.55)"; ctx.fill();
        if (on) { ctx.lineWidth = 2; ctx.strokeStyle = C.cream; ctx.stroke(); }
        ctx.restore();
      });
      ctx.save(); ctx.globalAlpha = show;
      ctx.beginPath(); ctx.arc(90, 60, 9, 0, Math.PI * 2); ctx.fillStyle = "rgba(251,248,241,.6)"; ctx.fill();
      text(ctx, "1,000 adults", 110, 61, { size: 24, weight: 800, color: C.cream, align: "left" });
      ctx.beginPath(); ctx.arc(300, 60, 11, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill();
      text(ctx, "with diabetes", 320, 61, { size: 24, weight: 800, color: C.cream, align: "left" });
      ctx.restore();
    }
    // Once we're out at the country: a pulse where the district is.
    if (zout > 0.9) {
      const [cx, cy] = project(view, [-95.8, 29.3]), k = ((((t - 8) * 0.8) % 1) + 1) % 1;
      ctx.beginPath(); ctx.arc(cx, cy, 10 + k * 50, 0, Math.PI * 2); ctx.lineWidth = 4; ctx.strokeStyle = `rgba(242,201,76,${1 - k})`; ctx.stroke();
      ctx.beginPath(); ctx.arc(cx, cy, 8, 0, Math.PI * 2); ctx.fillStyle = "#f2c94c"; ctx.fill();
    }
    if (d > 0 && t < 3) { const [lx, ly] = project(view, [-95.9, 29.95]); text(ctx, "TX-22", lx, ly, { size: 40, weight: 900, color: "#f2c94c" }); }
    // The numbers, each with its source right under it.
    const n = Math.round((64000 * smooth(span(t, 3, 5.6))) / 1000) * 1000;
    slam(ctx, t, 0.4, "According to the CDC", 1460, 46, { size: 34, color: C.mint, shadow: C.pine, rot: 0 });
    slam(ctx, t, 1.2, "Texas's 22nd", 1460, 116, { size: 64, color: "#f2c94c", shadow: C.pine, rot: -0.02 });
    if (t > 3) slam(ctx, t, 3, n.toLocaleString("en-US"), 1460, 260, { size: 140, color: C.cream, shadow: C.berry, rot: -0.03 });
    slam(ctx, t, 3.3, "adults with diabetes", 1460, 372, { size: 46, color: C.mint, shadow: C.pine, rot: -0.02 });
    slam(ctx, t, 5.2, "more than 1 in 9", 1290, 446, { size: 36, color: "#10261c", shadow: C.pine, pill: "#f2c94c", rot: 0.02 });
    cite(ctx, "According to CDC PLACES 2025 (2023 data), census tracts in TX-22", 1460, 506, smooth(span(t, 3.6, 4.1)));
    burst(ctx, t, 3, 1460, 260, { color: C.berry, r: 220 });
    slam(ctx, t, 7.6, "314,000", 1460, 640, { size: 120, color: "#f2c94c", shadow: C.berry, rot: 0.03 });
    slam(ctx, t, 7.9, "U.S. kids and teens with type 1", 1460, 738, { size: 40, color: C.cream, shadow: C.pine, rot: 0.01 });
    cite(ctx, "According to the CDC, National Diabetes Statistics Report", 1460, 800, smooth(span(t, 8.2, 8.7)));
    burst(ctx, t, 7.6, 1460, 640, { color: "#f2c94c", r: 200 });
    ctx.restore();
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
