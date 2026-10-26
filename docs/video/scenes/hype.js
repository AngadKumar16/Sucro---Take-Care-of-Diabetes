// Hype: the loud look, for the big moments. A dark pine stage with turning light rays and halftone
// dots, words that slam in from the camera with a flash, a shake and a burst, and the real phone
// punching in on each beat. Same palette, turned up. Still frame-deterministic: every shake and
// flash is a function of t and the beat times.
import { C } from "../maya.js";
import { W, H, smooth, backOut, span, rr, caption, FONT } from "./common.js";
import { hash } from "./paper.js";
import { realPhone, IMG } from "./app.js";
import { editor } from "./code.js";

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

// A pulse ring for the alarm beats (heartbeat rhythm).
function pulseRings(ctx, t, x, y, color, until) {
  if (t > until) return;
  for (let i = 0; i < 3; i++) {
    const k = ((t * 0.9) + i / 3) % 1;
    ctx.beginPath(); ctx.arc(x, y, 260 + k * 520, 0, Math.PI * 2);
    ctx.lineWidth = 6; ctx.strokeStyle = color.replace("A", String((1 - k) * 0.35)); ctx.stroke();
  }
}

// ---- Shots ------------------------------------------------------------------------------------

// 3 · The turn: the sprout bursts up, the name slams in letter by letter, then "grows with you".
export const hypeTitle = {
  duration: 6,
  line: "So we built DiabetesCare. It grows with you.",
  render(ctx, t) {
    const word = "DiabetesCare", letterAt = (i) => 1.1 + i * 0.07;
    const hits = [0.45, ...[...word].map((_, i) => letterAt(i)), 2.1, 3.7];
    ctx.save();
    shake(ctx, t, hits, 14);
    hypeBg(ctx, t, { tint: "#2f7a55", pulse: Math.exp(-Math.max(0, t - 2.1) * 3) * (t > 2.1 ? 1 : 0) });
    // Sprout: shoots up with overshoot, leaves pop on beats.
    const g = backOut(span(t, 0.3, 0.75));
    ctx.save(); ctx.translate(W / 2, 470); ctx.scale(g, g);
    ctx.lineWidth = 8; ctx.strokeStyle = C.ink; ctx.lineJoin = "round";
    const leaf = (x, y, r, k) => { if (k <= 0) return; ctx.save(); ctx.translate(x, y); ctx.rotate(r); ctx.scale(k, k); ctx.beginPath(); ctx.ellipse(0, 0, 70, 30, 0, 0, Math.PI * 2); ctx.fillStyle = C.leaf; ctx.fill(); ctx.stroke(); ctx.restore(); };
    ctx.beginPath(); ctx.roundRect(-10, -260, 20, 260, 10); ctx.fillStyle = C.pine; ctx.fill(); ctx.stroke();
    leaf(-62, -130, -0.5, backOut(span(t, 0.6, 0.9)));
    leaf(62, -190, 0.5, backOut(span(t, 0.75, 1.05)));
    const bloom = backOut(span(t, 2.1, 2.4));
    if (bloom > 0) { ctx.save(); ctx.translate(0, -270); ctx.scale(bloom, bloom); for (let i = 0; i < 6; i++) { ctx.beginPath(); ctx.ellipse(Math.cos(i) * 32, Math.sin(i) * 32, 30, 18, i, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill(); ctx.stroke(); } ctx.beginPath(); ctx.arc(0, 0, 20, 0, Math.PI * 2); ctx.fillStyle = "#f2c94c"; ctx.fill(); ctx.stroke(); ctx.restore(); }
    ctx.beginPath(); ctx.moveTo(-110, 0); ctx.lineTo(110, 0); ctx.lineTo(88, 130); ctx.lineTo(-88, 130); ctx.closePath(); ctx.fillStyle = C.amber; ctx.fill(); ctx.stroke();
    ctx.restore();
    burst(ctx, t, 0.45, W / 2, 380, { color: C.mint, r: 200, n: 16 });
    burst(ctx, t, 2.1, W / 2, 200, { color: "#f2c94c", r: 120 });
    // The name, a letter per beat.
    ctx.font = FONT(900, 150);
    const widths = [...word].map((ch) => ctx.measureText(ch).width);
    let x = W / 2 - widths.reduce((a, b) => a + b, 0) / 2;
    [...word].forEach((ch, i) => { slam(ctx, t, letterAt(i), ch, x + widths[i] / 2, 760, { size: 150, rot: (hash(i) - 0.5) * 0.12, shadow: i < 8 ? C.pine : C.berry }); x += widths[i]; });
    slam(ctx, t, 3.7, "grows with you", W / 2, 935, { size: 70, color: NIGHT, shadow: C.pine, pill: C.mint, rot: -0.03 });
    burst(ctx, t, 3.7, W / 2, 935, { color: C.mint, r: 260, n: 18 });
    ctx.restore();
    flash(ctx, t, [0.45, 2.1, 3.7], 0.45);
  },
};

// 5 · Feeling off? The urgent beat: the stage pulses berry, the phone punches in on each step, and
// each step slams in as it's said. Calms to pine once the recheck is running.
export const hypeHelp = {
  duration: 14,
  line: "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap.",
  render(ctx, t) {
    const hits = [2.8, 3.6, 6.1, 8.6, 10.4];
    const calm = smooth(span(t, 9.8, 11));
    const beat = Math.pow(Math.max(0, Math.sin(t * Math.PI * 2 * 1.1)), 8);
    ctx.save();
    shake(ctx, t, hits, 16);
    hypeBg(ctx, t, { tint: calm > 0.5 ? C.pine : "#7a2f22", pulse: (1 - calm) * beat * (t > 2.6 ? 1 : 0.3) });
    if (t > 2.6) pulseRings(ctx, t, W / 2, 520, "rgba(224,100,74,A)", 9.8);
    const PHX = 757, PHY = 80, PHH = 880, PHW = (PHH * 1320) / 2868;
    ctx.save();
    punch(ctx, t, hits, PHX + PHW / 2, PHY + PHH / 2, 0.05);
    const p = realPhone(ctx, t, { x: PHX, y: PHY, h: PHH, screens: [["kidToday", 0], ["kidHelp", 3.6], ["kidHelpLogged", 6.1], ["liveActivity", 10.4]], taps: [[3.2, 0.78, 0.6], [5.7, 0.5, 0.5], [8.9, 0.27, 0.31]] });
    ctx.restore();
    slam(ctx, t, 0.9, "Simpler screen", 380, 300, { size: 64, shadow: C.pine, until: 3.4 });
    slam(ctx, t, 2.8, "Feeling off?", 1500, 300, { size: 100, until: 5.9 });
    slam(ctx, t, 4.4, "Step by step", 380, 420, { size: 64, shadow: C.pine, until: 5.9 });
    slam(ctx, t, 6.1, "15 g", 370, 360, { size: 170, color: "#f2c94c", shadow: C.berry, until: 9.9 });
    slam(ctx, t, 6.9, "Recheck 15:00", 1510, 460, { size: 72, color: NIGHT, shadow: C.pine, pill: C.mint, until: 9.9 });
    slam(ctx, t, 8.6, "Call Mom: 1 tap", 1500, 250, { size: 72, until: 9.9 });
    slam(ctx, t, 10.8, "Still counting", 1500, 250, { size: 80, shadow: C.pine });
    burst(ctx, t, 2.8, 1500, 300, { color: C.berry, r: 220 });
    burst(ctx, t, 6.1, 370, 360, { color: "#f2c94c", r: 180 });
    const [ix, iy] = p.at(0.62, 0.03);
    burst(ctx, t, 10.4, ix, iy + 10, { color: C.mint, r: 90 });
    ctx.restore();
    flash(ctx, t, [2.8, 6.1], 0.45);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 11 · One set of rules, then the tests land like a scoreboard and the app runs.
export const hypeGate = {
  duration: 15,
  line: "It's built in SwiftUI. Every rule about who can do what lives in one function, so no screen has a back door. And 207 tests check it.",
  render(ctx, t) {
    const hits = [0.3, 4.6, 7.6, 10.9];
    ctx.save();
    shake(ctx, t, hits, 12);
    hypeBg(ctx, t, { tint: "#245c43", pulse: Math.exp(-Math.max(0, t - 10.9) * 2) * (t > 10.9 ? 1 : 0) });
    const lines = [
      "func access(to feature: Feature, completed: Set<Skill>) -> FeatureAccess {",
      "    switch (self, feature) {",
      "    case (.adult, _):                               base = .open",
      "    case (.kid, .quickBolus):                       base = .hidden",
      "    case (.kid, .logInsulin), (.kid, .changeSite):  base = .parent",
      "    case (.teen, .logInsulin), (.teen, .changeSite): base = .open",
      "    case (_, .editThresholds), (_, .clearData):     base = .parent",
      "    }",
      "    // A kid's skills can open what the stage keeps behind the passcode.",
      "    if base == .parent, skills ⊆ completed { return .open }",
      "}",
    ];
    const mark = t < 5.4 ? -1 : t < 6.2 ? 4 : t < 7 ? 5 : t < 7.6 ? 2 : 9;
    const away = smooth(span(t, 9.4, 10));
    ctx.save(); ctx.globalAlpha = 1 - away * 0.75;
    ctx.translate(-away * 160, 0);
    editor(ctx, { x: 90, y: 150, w: 1360, h: 700, file: "CareStage.swift", size: 26, lines, chars: Math.max(0, (t - 0.6) * 140), mark, markAlpha: 1 });
    ctx.restore();
    slam(ctx, t, 0.3, "SwiftUI", 1680, 160, { size: 70, color: NIGHT, shadow: C.pine, pill: C.mint, rot: 0.05, until: 9.4 });
    slam(ctx, t, 4.6, "One function", 1640, 420, { size: 70, rot: 0.04, until: 9.4 });
    slam(ctx, t, 7.6, "No back door", 1640, 620, { size: 70, shadow: C.pine, rot: -0.05, until: 9.4 });
    // The scoreboard.
    const n1 = Math.round(147 * smooth(span(t, 9.6, 10.6))), n2 = Math.round(60 * smooth(span(t, 9.9, 10.7)));
    if (t > 9.6 && t < 12.2) {
      slam(ctx, t, 9.6, `${n1} unit`, 560, 330, { size: 90, color: C.mint, shadow: C.pine, rot: -0.03, until: 12 });
      slam(ctx, t, 9.9, `${n2} UI`, 560, 480, { size: 90, color: C.mint, shadow: C.pine, rot: 0.03, until: 12 });
    }
    slam(ctx, t, 10.9, "207 tests ✓", 1300, 400, { size: 150, color: "#f2c94c", shadow: C.berry, rot: -0.05, until: 12.2 });
    burst(ctx, t, 10.9, 1300, 400, { color: "#f2c94c", r: 320, n: 20 });
    // Confetti checkmarks.
    if (t > 10.9 && t < 12.6) for (let i = 0; i < 26; i++) {
      const k = (t - 10.9) / 1.7, x = hash(i) * W, y = -60 + k * (900 + hash(i + 9) * 500), r = k * 6 * (hash(i + 3) - 0.5);
      ctx.save(); ctx.translate(x, y); ctx.rotate(r); ctx.beginPath(); ctx.moveTo(-18, 0); ctx.lineTo(-4, 14); ctx.lineTo(22, -16);
      ctx.lineWidth = 9; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = [C.mint, "#f2c94c", C.cream][i % 3]; ctx.stroke(); ctx.restore();
    }
    // And it runs.
    const run = smooth(span(t, 12.2, 12.9));
    if (run > 0) {
      realPhone(ctx, t, { x: W / 2 - 190 + (1 - run) * 1200, y: 70, h: 820, screens: [["today", 0]] });
      slam(ctx, t, 12.9, "Running on iPhone", 480, 470, { size: 64, color: C.mint, shadow: C.pine });
    }
    ctx.restore();
    flash(ctx, t, [10.9], 0.7);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 12a · Everything else, rapid fire: each feature slams onto the stage as it's named, its name
// slams up top, and "Free" lands last.
export const hypeMontage = {
  duration: 12,
  line: "There's more: widgets, an Apple Watch app, Siri, five thousand foods to look up, a weekly recap, a sick-day checklist, and a card for school. All of it free.",
  render(ctx, t) {
    const cards = [
      ["widgetMedium", "Widgets", 0.8], ["watchGlance", "Apple Watch", 1.7, true], ["siriGlucose", "Siri", 2.5],
      ["carbSearch", "5,371 foods", 3.4], ["weeklyRecap", "Weekly recap", 4.5], ["sickDay", "Sick days", 5.5], ["schoolCard", "School card", 6.6],
    ];
    const hits = [...cards.map((c) => c[2]), 8.4];
    ctx.save();
    shake(ctx, t, hits, 12);
    hypeBg(ctx, t, { tint: "#2f6b4a", pulse: impact(t, hits) * 0.6 });
    cards.forEach(([name, label, a, watch], i) => {
      const img = IMG(name); if (!img) return;
      const k = span(t, a, a + 0.18);
      if (k <= 0) return;
      const tx = 225 + i * 245, ty = 440 + (i % 2) * 34, rot = (hash(i + 3) - 0.5) * 0.12;
      const s = 1 + Math.pow(1 - k, 2) * 2.2;
      ctx.save(); ctx.globalAlpha = k; ctx.translate(tx + (W / 2 - tx) * (1 - k), ty); ctx.rotate(rot); ctx.scale(s, s);
      ctx.shadowColor = "rgba(0,0,0,.45)"; ctx.shadowBlur = 30; ctx.shadowOffsetY = 14;
      if (watch) {
        rr(ctx, -70, -230, 140, 460, 30, C.ink, null);
        rr(ctx, -118, -146, 236, 292, 52, "#1c2420", C.ink, 6);
        ctx.shadowColor = "transparent"; ctx.save(); ctx.beginPath(); ctx.roundRect(-104, -132, 208, 264, 40); ctx.clip(); ctx.drawImage(img, -104, -132, 208, 264); ctx.restore();
      } else {
        rr(ctx, -125, -272, 250, 544, 26, C.cream, C.ink, 6);
        ctx.shadowColor = "transparent"; ctx.save(); ctx.beginPath(); ctx.roundRect(-113, -260, 226, 520, 18); ctx.clip(); { const iw = (520 * img.width) / img.height; ctx.drawImage(img, -iw / 2, -260, iw, 520); } ctx.restore();
      }
      ctx.restore();
      burst(ctx, t, a, tx, ty - 120, { color: [C.mint, "#f2c94c", C.berry][i % 3], r: 120 });
      const next = cards[i + 1] ? cards[i + 1][2] : 7.9;
      slam(ctx, t, a, label, W / 2, 120, { size: 104, shadow: [C.berry, C.pine][i % 2], rot: (i % 2 ? 0.03 : -0.03), until: next - 0.05 });
    });
    slam(ctx, t, 8.4, "Free", W / 2, 440, { size: 220, color: NIGHT, shadow: C.pine, pill: "#f2c94c", rot: -0.08 });
    burst(ctx, t, 8.4, W / 2, 440, { color: "#f2c94c", r: 360, n: 24 });
    ctx.restore();
    flash(ctx, t, [8.4], 0.6);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
