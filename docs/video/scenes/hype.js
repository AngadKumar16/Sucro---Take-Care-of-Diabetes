// Hype: the loud look, for the big moments. A dark pine stage with turning light rays and halftone
// dots, words that slam in from the camera with a flash, a shake and a burst, and the real phone
// punching in on each beat. Same palette, turned up. Still frame-deterministic: every shake and
// flash is a function of t and the beat times.
import { C } from "../maya.js";
import { W, H, smooth, backOut, span, rr, caption, FONT } from "./common.js";
import { hash } from "./paper.js";
import { realPhone, IMG } from "./app.js";
import { editor } from "./code.js";
import { SRC } from "./source.js";
import { TESTS } from "./tests.js";

const NIGHT = "#0f2219";

// The stage: dark radial ground, slowly turning rays, halftone dots in the corners. `tint` warms
// the centre (berry for the alarm beats, pine when things are calm).
export function hypeBg(ctx, t, { tint = C.pine, pulse = 0 } = {}) {
  ctx.fillStyle = NIGHT; ctx.fillRect(0, 0, W, H);
  const g = ctx.createRadialGradient(W / 2, H * 0.45, 40, W / 2, H * 0.45, H * 1.05);
  g.addColorStop(0, tint); g.addColorStop(1, NIGHT);
  ctx.save(); ctx.globalAlpha = 0.55 + pulse * 0.35; ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); ctx.restore();
  ctx.save(); ctx.translate(W / 2, H * 0.45); ctx.rotate(t * 0.12);
  ctx.fillStyle = "rgba(251,248,241,.05)";
  for (let i = 0; i < 16; i++) { ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, 2400, (i / 16) * Math.PI * 2, (i / 16 + 1 / 32) * Math.PI * 2); ctx.fill(); }
  ctx.restore();
  ctx.fillStyle = "rgba(191,224,201,.10)";
  for (let y = 0; y < H; y += 28) for (let x = 0; x < W; x += 28) {
    const d = Math.hypot((x - W / 2) / W, (y - H * 0.45) / H);
    const r = Math.max(0, (d - 0.38) * 14);
    if (r > 0.4) { ctx.beginPath(); ctx.arc(x + ((y / 28) % 2) * 14, y, r, 0, Math.PI * 2); ctx.fill(); }
  }
}

// How hard the beats in `hits` are still hitting at t: 1 on the beat, decaying over 0.35 s.
const impact = (t, hits) => hits.reduce((m, a) => (t >= a ? Math.max(m, Math.exp(-(t - a) * 12)) : m), 0);

// Shake the camera on the beats (call inside save/restore, before drawing the shot).
export function shake(ctx, t, hits, amount = 18) {
  const k = impact(t, hits), f = Math.floor(t * 30);
  if (k > 0.01) ctx.translate((hash(f * 3.1) - 0.5) * amount * k * 2, (hash(f * 7.7) - 0.5) * amount * k * 2);
}

// Zoom punch: scale about (cx, cy) on the beats.
export function punch(ctx, t, hits, cx, cy, amount = 0.06) {
  const s = 1 + amount * impact(t, hits);
  ctx.translate(cx, cy); ctx.scale(s, s); ctx.translate(-cx, -cy);
}

export function flash(ctx, t, hits, strength = 0.75) {
  const k = hits.reduce((m, a) => (t >= a ? Math.max(m, 1 - span(t, a, a + 0.2)) : m), 0);
  if (k > 0) { ctx.fillStyle = `rgba(251,248,241,${k * strength})`; ctx.fillRect(0, 0, W, H); }
}

// A burst of lines from (x, y) at a.
export function burst(ctx, t, a, x, y, { color = C.amber, r = 140, n = 12 } = {}) {
  const k = span(t, a, a + 0.4);
  if (k <= 0 || k >= 1) return;
  const e = smooth(k);
  ctx.save(); ctx.lineCap = "round"; ctx.lineWidth = 10 * (1 - k) + 2; ctx.strokeStyle = color;
  for (let i = 0; i < n; i++) {
    const an = (i / n) * Math.PI * 2 + hash(a * 10) * 0.5, r0 = r * (0.6 + e * 0.8), r1 = r * (0.8 + e * 1.3);
    ctx.beginPath(); ctx.moveTo(x + Math.cos(an) * r0, y + Math.sin(an) * r0); ctx.lineTo(x + Math.cos(an) * r1, y + Math.sin(an) * r1); ctx.stroke();
  }
  ctx.restore();
}

// A word that slams in from the camera at a: thick ink outline, a hard offset shadow, an optional
// pill behind it. Leaves at `until`.
export function slam(ctx, t, a, s, x, y, { size = 110, color = C.cream, shadow = C.berry, pill = null, rot = -0.04, until = Infinity } = {}) {
  const k = span(t, a, a + 0.16);
  const gone = until === Infinity ? 0 : span(t, until, until + 0.2);
  if (k <= 0 || gone >= 1) return;
  const sc = 1 + Math.pow(1 - k, 2) * 1.8 + (1 - backOut(span(t, a + 0.16, a + 0.4))) * 0.06;
  ctx.save(); ctx.translate(x, y - gone * 40); ctx.rotate(rot); ctx.scale(sc, sc); ctx.globalAlpha = k * (1 - gone);
  ctx.font = FONT(900, size); ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.lineJoin = "round";
  if (pill) { const w = ctx.measureText(s).width + size * 0.9; rr(ctx, -w / 2, -size * 0.72, w, size * 1.44, size * 0.72, pill, C.ink, 8); }
  ctx.fillStyle = shadow; ctx.fillText(s, size * 0.07, size * 0.08);
  ctx.lineWidth = size * 0.14; ctx.strokeStyle = C.ink; ctx.strokeText(s, 0, 0);
  ctx.fillStyle = color; ctx.fillText(s, 0, 0);
  ctx.restore();
}


// ---- Shots ------------------------------------------------------------------------------------

// 3 · The turn: the sprout bursts up, the name slams in letter by letter, then "grows with you".
export const hypeTitle = {
  duration: 10.5,
  line: "So I built DiabetesCare, an iPhone app that helps kids and teens with type 1 diabetes take over their own care, with their parents in the loop.",
  render(ctx, t) {
    const word = "DiabetesCare", letterAt = (i) => 1.1 + i * 0.07;
    const hits = [0.45, ...[...word].map((_, i) => letterAt(i)), 2.1, 3, 6.6, 8.5];
    ctx.save();
    shake(ctx, t, hits, 14);
    hypeBg(ctx, t, { tint: "#2f7a55", pulse: Math.exp(-Math.max(0, t - 2.1) * 3) * (t > 2.1 ? 1 : 0) });
    // Sprout: shoots up with overshoot, leaves pop on beats.
    const g = backOut(span(t, 0.3, 0.75));
    ctx.save(); ctx.translate(W / 2, 380); ctx.scale(g, g);
    ctx.lineWidth = 8; ctx.strokeStyle = C.ink; ctx.lineJoin = "round";
    const leaf = (x, y, r, k) => { if (k <= 0) return; ctx.save(); ctx.translate(x, y); ctx.rotate(r); ctx.scale(k, k); ctx.beginPath(); ctx.ellipse(0, 0, 70, 30, 0, 0, Math.PI * 2); ctx.fillStyle = C.leaf; ctx.fill(); ctx.stroke(); ctx.restore(); };
    ctx.beginPath(); ctx.roundRect(-10, -260, 20, 260, 10); ctx.fillStyle = C.pine; ctx.fill(); ctx.stroke();
    leaf(-62, -130, -0.5, backOut(span(t, 0.6, 0.9)));
    leaf(62, -190, 0.5, backOut(span(t, 0.75, 1.05)));
    const bloom = backOut(span(t, 2.1, 2.4));
    if (bloom > 0) { ctx.save(); ctx.translate(0, -270); ctx.scale(bloom, bloom); for (let i = 0; i < 6; i++) { ctx.beginPath(); ctx.ellipse(Math.cos(i) * 32, Math.sin(i) * 32, 30, 18, i, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill(); ctx.stroke(); } ctx.beginPath(); ctx.arc(0, 0, 20, 0, Math.PI * 2); ctx.fillStyle = "#f2c94c"; ctx.fill(); ctx.stroke(); ctx.restore(); }
    ctx.beginPath(); ctx.moveTo(-110, 0); ctx.lineTo(110, 0); ctx.lineTo(88, 130); ctx.lineTo(-88, 130); ctx.closePath(); ctx.fillStyle = C.amber; ctx.fill(); ctx.stroke();
    ctx.restore();
    burst(ctx, t, 0.45, W / 2, 290, { color: C.mint, r: 200, n: 16 });
    burst(ctx, t, 2.1, W / 2, 110, { color: "#f2c94c", r: 120 });
    // The name, a letter per beat.
    ctx.font = FONT(900, 150);
    const widths = [...word].map((ch) => ctx.measureText(ch).width);
    let x = W / 2 - widths.reduce((a, b) => a + b, 0) / 2;
    [...word].forEach((ch, i) => { slam(ctx, t, letterAt(i), ch, x + widths[i] / 2, 610, { size: 150, rot: (hash(i) - 0.5) * 0.12, shadow: i < 8 ? C.pine : C.berry }); x += widths[i]; });
    slam(ctx, t, 8.5, "grows with you", W / 2, 738, { size: 70, color: NIGHT, shadow: C.pine, pill: C.mint, rot: -0.03 });
    burst(ctx, t, 8.5, W / 2, 738, { color: C.mint, r: 260, n: 18 });
    // Who made it, and who it's for (the purpose in one sentence is the spoken line).
    const by = smooth(span(t, 2.4, 2.9));
    if (by > 0) text(ctx, "by Angad Kumar", 70, 64, { size: 40, weight: 800, align: "left", color: `rgba(191,224,201,${by})` });
    slam(ctx, t, 3, "For kids & teens with type 1", 440, 250, { size: 52, color: C.cream, shadow: C.berry, rot: -0.04 });
    slam(ctx, t, 6.6, "+ their parents", 1520, 250, { size: 52, color: C.cream, shadow: C.pine, rot: 0.04 });
    ctx.restore();
    flash(ctx, t, [0.45, 2.1, 8.5], 0.45);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};


// 11 · One function holds the rules, then the proof: every test in the suite scrolls past a scan
// line and ticks green (the real names, from the last run: `python3 sync-tests.py`) while the
// count runs up to the total.
export const hypeGate = {
  duration: 12,
  line: "I wrote it in Swift with SwiftUI. One function decides what each age is allowed to do, so every screen follows the same rules. And 198 tests check it.",
  render(ctx, t) {
    const N = TESTS.names.length, total = TESTS.count;
    const hits = [];
    ctx.save();
    shake(ctx, t, hits, 10);
    hypeBg(ctx, t, { tint: "#245c43" });
    const mark = t < 4.2 ? -1 : t < 4.9 ? 7 : t < 5.6 ? 9 : t < 6.2 ? 3 : 15;
    const away = smooth(span(t, 6.4, 7));
    if (away < 1) {
      ctx.save(); ctx.globalAlpha = 1 - away; ctx.translate(0, -away * 80);
      editor(ctx, { x: 50, y: 150, w: 1430, h: 700, file: "CareStage.swift", size: 19, lines: SRC.access.lines, chars: Math.max(0, (t - 0.6) * 160), mark, markAlpha: 1 });
      ctx.restore();
    }
    // Built with: the language, the tools and Apple's frameworks (the rules ask for the tools; AI use
    // is disclosed in the entry form).
    const panel = smooth(span(t, 0.3, 0.8)) * (1 - smooth(span(t, 6.4, 7)));
    if (panel > 0) {
      ctx.save(); ctx.globalAlpha = panel; ctx.translate((1 - smooth(span(t, 0.3, 0.8))) * 80, 0);
      rr(ctx, 1510, 150, 370, 580, 26, "rgba(15,34,25,.92)", C.mint, 3);
      text(ctx, "Built with", 1695, 200, { size: 36, weight: 900, color: "#f2c94c" });
      const tools = ["Swift", "SwiftUI", "Xcode", "Core Data", "CloudKit", "HealthKit", "WidgetKit", "ActivityKit", "App Intents", "WatchConnectivity", "Foundation Models", "Swift Testing, XCTest"];
      tools.forEach((s2, i) => { const k = smooth(span(t, 0.6 + i * 0.12, 0.9 + i * 0.12)); if (k > 0) text(ctx, s2, 1695, 248 + i * 37, { size: i < 2 ? 32 : 27, weight: i < 2 ? 900 : 800, color: `rgba(${i < 2 ? "251,248,241" : "191,224,201"},${k})` }); });
      ctx.restore();
    }
    // The test wall: four columns rising past the scan line.
    const wall = smooth(span(t, 6.6, 7.1));
    let passed = 0;
    if (wall > 0) {
      const cols = 4, rows = Math.ceil(N / cols), lh = 34, scanY = 820;
      const scroll = (H - scanY + rows * lh) * smooth(span(t, 6.9, 10.2));
      ctx.save(); ctx.globalAlpha = wall;
      ctx.font = '600 19px ui-monospace, "SF Mono", Menlo, monospace'; ctx.textBaseline = "middle"; ctx.textAlign = "left";
      for (let i = 0; i < N; i++) {
        const r = Math.floor(i / cols), c = i % cols, y = H + 10 + r * lh - scroll, x = 70 + c * 455;
        const ok = y < scanY;
        if (ok) passed++;
        if (y < 60 || y > H + 20) continue;
        const fade = Math.min(1, (y - 60) / 120);
        ctx.globalAlpha = wall * fade * (ok ? 1 : 0.45);
        ctx.fillStyle = ok ? C.leaf : "#6f8a7a"; ctx.fillText(ok ? "✓" : "○", x, y);
        let name = TESTS.names[i]; while (ctx.measureText(name).width > 400 && name.length > 4) name = name.slice(0, -2);
        if (name !== TESTS.names[i]) name = name.slice(0, -1) + "…";
        ctx.fillStyle = ok ? C.cream : "#9fb2a5"; ctx.fillText(name, x + 26, y);
      }
      ctx.globalAlpha = wall;
      const g = ctx.createLinearGradient(0, scanY - 6, 0, scanY + 6);
      g.addColorStop(0, "rgba(191,224,201,0)"); g.addColorStop(0.5, "rgba(191,224,201,.9)"); g.addColorStop(1, "rgba(191,224,201,0)");
      ctx.fillStyle = g; ctx.fillRect(40, scanY - 6, W - 80, 12);
      ctx.restore();
      // The running count.
      const shown = Math.round((passed / N) * total);
      ctx.save(); ctx.globalAlpha = wall;
      rr(ctx, W / 2 - 230, 30, 460, 70, 35, "rgba(15,34,25,.9)", C.mint, 3);
      text(ctx, `${shown} of ${total} passed`, W / 2, 66, { size: 34, weight: 900, color: C.mint });
      ctx.restore();
    }
    ctx.restore();
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 12a · Everything else: each feature lands on the stage as it's named, with its name up top and
// the real Swift type that builds it underneath; "Free" lands last.
const MONTAGE = [
  ["widgetMedium", "Widgets", 1.4, "GlucoseWidget"], ["watchGlance", "Apple Watch", 1.9, "WatchBridge", "watch"], ["siriGlucose", "Siri", 2.8, "CheckGlucoseIntent"],
  ["carbSearch", "5,371 foods", 3.4, "FoodSearchView"], ["trends2", "Trends", 4.8, "TrendsView"], ["weeklyRecap", "Weekly recap", 5.3, "WeeklyRecapView"],
  ["parentUrgentLow", "Urgent alerts", 6.2, "CaregiverAlertPolicy"], ["sickDay", "Sick days", 8.7, "SickDayCard"], ["schoolCard", "School card", 10.2, "SchoolCardView"],
  ["report", "Doctor reports", 11.1, "ReportsView"], ["supplies", "Supplies", 12.1, "SuppliesView"], ["learn", "Lessons", 12.6, "LearnView"],
  ["ipadToday", "iPad", 13.6, "MainTabView", "ipad"],
];
const FREE = 15.3;

export const hypeMontage = {
  duration: 16.5,
  line: "There's more: widgets, Apple Watch, Siri, five thousand foods, trends, weekly recaps, urgent alerts for family, a sick-day checklist, a school card, doctor reports, supplies, lessons, and iPad. All of it free.",
  render(ctx, t) {
    const hits = [...MONTAGE.map((c) => c[2]), FREE];
    ctx.save();
    shake(ctx, t, hits, 8);
    hypeBg(ctx, t, { tint: "#2f6b4a", pulse: impact(t, hits) * 0.5 });
    MONTAGE.forEach(([name, label, a, type, kind], i) => {
      const img = IMG(name); if (!img) return;
      const k = span(t, a, a + 0.18);
      if (k <= 0) return;
      const tx = 150 + i * 135, ty = 430 + (i % 2) * 30, rot = (hash(i + 3) - 0.5) * 0.12;
      const s = 0.72 * (1 + Math.pow(1 - k, 2) * 2.2);
      ctx.save(); ctx.globalAlpha = k; ctx.translate(tx + (W / 2 - tx) * (1 - k), ty); ctx.rotate(rot); ctx.scale(s, s);
      ctx.shadowColor = "rgba(0,0,0,.45)"; ctx.shadowBlur = 30; ctx.shadowOffsetY = 14;
      if (kind === "watch") {
        rr(ctx, -70, -230, 140, 460, 30, C.ink, null);
        rr(ctx, -118, -146, 236, 292, 52, "#1c2420", C.ink, 6);
        ctx.shadowColor = "transparent"; ctx.save(); ctx.beginPath(); ctx.roundRect(-104, -132, 208, 264, 40); ctx.clip(); ctx.drawImage(img, -104, -132, 208, 264); ctx.restore();
      } else if (kind === "ipad") {
        rr(ctx, -200, -265, 400, 530, 30, "#1c2420", C.ink, 6);
        ctx.shadowColor = "transparent"; ctx.save(); ctx.beginPath(); ctx.roundRect(-186, -251, 372, 502, 18); ctx.clip(); ctx.drawImage(img, -186, -251, 372, 502); ctx.restore();
      } else {
        rr(ctx, -125, -272, 250, 544, 26, C.cream, C.ink, 6);
        ctx.shadowColor = "transparent"; ctx.save(); ctx.beginPath(); ctx.roundRect(-113, -260, 226, 520, 18); ctx.clip(); { const iw = (520 * img.width) / img.height; ctx.drawImage(img, -iw / 2, -260, iw, 520); } ctx.restore();
      }
      ctx.restore();
      burst(ctx, t, a, tx, ty - 110, { color: [C.mint, "#f2c94c", C.berry][i % 3], r: 100 });
      // The real type behind it.
      const ck = smooth(span(t, a + 0.25, a + 0.5));
      if (ck > 0) {
        ctx.save(); ctx.globalAlpha = ck;
        ctx.font = '700 16px ui-monospace, "SF Mono", Menlo, monospace';
        const w = ctx.measureText(type).width + 20, y = ty + 215 + (i % 2) * 6 + (i % 2 ? 34 : 0);
        rr(ctx, tx - w / 2, y, w, 32, 10, "#1e2c25", C.mint, 2);
        ctx.fillStyle = C.mint; ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillText(type, tx, y + 16);
        ctx.restore();
      }
      const next = MONTAGE[i + 1] ? MONTAGE[i + 1][2] : FREE - 0.4;
      slam(ctx, t, a, label, W / 2, 110, { size: 96, shadow: [C.berry, C.pine][i % 2], rot: i % 2 ? 0.03 : -0.03, until: next - 0.05 });
    });
    slam(ctx, t, FREE, "Free", W / 2, 400, { size: 200, color: NIGHT, shadow: C.pine, pill: "#f2c94c", rot: -0.08 });
    burst(ctx, t, FREE, W / 2, 400, { color: "#f2c94c", r: 340, n: 20 });
    ctx.restore();
    flash(ctx, t, [FREE], 0.5);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
