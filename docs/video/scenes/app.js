// App: the real app, front and centre. Real screenshots (docs/screenshots, docs/video/assets) in a
// phone frame, with screens that push in like the app's navigation, tap ripples, and paper callouts
// pointing at real controls. For the final cut, swap a screenshot for a simulator recording of the
// same screen (see docs/demo-video.md › What to record); positions are fractions of the screen.
import { C, drawMaya } from "../maya.js";
import { W, H, smooth, backOut, span, rr, text, caption, FONT } from "./common.js";
import { paperGround, cut, blob, hop, onTwos, hash } from "./paper.js";
import { editor } from "./code.js";

export const IMG = (name) => (typeof window !== "undefined" && window.ASSETS ? window.ASSETS[name] : null);
const SCREEN_W = 1320, SCREEN_H = 2868;

// A phone with real screens. `screens` is [[name, from]], each pushing in from the right at `from`.
export function realPhone(ctx, t, { x, y, h, screens, taps = [], tag }) {
  const w = (h * SCREEN_W) / SCREEN_H, b = 14;
  ctx.save();
  ctx.shadowColor = "rgba(30,45,36,.3)"; ctx.shadowBlur = 40; ctx.shadowOffsetY = 18;
  rr(ctx, x - b, y - b, w + b * 2, h + b * 2, w * 0.15, C.ink, null);
  ctx.restore();
  ctx.save();
  ctx.beginPath(); ctx.roundRect(x, y, w, h, w * 0.13); ctx.clip();
  ctx.fillStyle = "#efeae0"; ctx.fillRect(x, y, w, h);
  screens.forEach(([name, from], i) => {
    const img = IMG(name);
    if (!img || t < from - 0.0001) return;
    const k = i === 0 ? 1 : smooth(span(t, from, from + 0.45));
    const next = screens[i + 1];
    const out = next ? smooth(span(t, next[1], next[1] + 0.45)) : 0;
    ctx.drawImage(img, x + (1 - k) * w - out * w * 0.3, y, w, h);
    if (out > 0) { ctx.fillStyle = `rgba(0,0,0,${out * 0.15})`; ctx.fillRect(x, y, w, h); }
  });
  // Tap ripples on real controls: [at, fx, fy].
  for (const [at, fx, fy] of taps) {
    const k = span(t, at, at + 0.6);
    if (k > 0 && k < 1) {
      ctx.beginPath(); ctx.arc(x + fx * w, y + fy * h, 18 + k * 50, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(31,107,74,${0.35 * (1 - k)})`; ctx.fill();
    }
  }
  ctx.restore();
  if (tag) { ctx.font = FONT(900, 22); const tw = ctx.measureText(tag).width + 28; rr(ctx, x + w / 2 - tw / 2, y + h + 30, tw, 40, 20, C.berry, null); text(ctx, tag, x + w / 2, y + h + 51, { size: 22, weight: 900, color: "#ffffff" }); }
  return { w, h, at: (fx, fy) => [x + fx * w, y + fy * h] };
}

// A paper callout that hops in at `a`, with a line to a dot on the real control.
export function callout(ctx, t, a, [tx, ty], [lx, ly], label, { color = C.cream, until = Infinity } = {}) {
  const k = span(onTwos(t), a, a + 0.35);
  const gone = span(t, until, until + 0.3);
  if (k <= 0 || gone >= 1) return;
  ctx.save(); ctx.globalAlpha = 1 - gone;
  const e = smooth(k);
  ctx.beginPath(); ctx.moveTo(lx, ly); ctx.lineTo(lx + (tx - lx) * e, ly + (ty - ly) * e);
  ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.setLineDash([2, 10]); ctx.lineCap = "round"; ctx.stroke(); ctx.setLineDash([]);
  if (e > 0.9) { ctx.beginPath(); ctx.arc(tx, ty, 11, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill(); ctx.lineWidth = 4; ctx.stroke(); }
  cut(ctx, lx, ly, (lx > tx ? 1 : -1) * 0.03, Math.round(a * 10), t, (c) => {
    c.font = FONT(900, 40); const w = c.measureText(label).width + 64;
    const s = backOut(k); c.scale(s, s);
    blob(c, () => c.roundRect(-w / 2, -40, w, 80, 24), color);
    c.shadowColor = "transparent"; c.fillStyle = C.ink; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText(label, 0, 2);
  });
  ctx.restore();
}

const ground = (ctx) => paperGround(ctx, C.sage, { seed: 51 });
const PH = { x: 700, y: 70, h: 880 };

// 4 · Setup: Who's using? → Kid → a grown-up makes the passcode → the kid's Today with the meter ruler.
export const appSetup = {
  duration: 10,
  line: "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...PH, screens: [["setup", 0], ["setupPasscode", 4.6], ["setupKidToday", 7]], taps: [[4.1, 0.5, 0.39]] });
    [["Kid", 0.39], ["Teen", 0.53], ["Adult", 0.66], ["Parent", 0.82]].forEach(([s, fy], i) => callout(ctx, t, 0.8 + i * 0.7, p.at(0.08, fy), [430, 260 + i * 170], s, { color: i === 3 ? C.mint : "#fff7ea", until: 4.4 }));
    callout(ctx, t, 5.2, p.at(0.5, 0.33), [1520, 300], "A grown-up sets a passcode", { until: 6.9 });
    callout(ctx, t, 7.6, p.at(0.62, 0.85), [1500, 620], "Slide the ruler to log");
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};


// 6 · The grown-up passcode on a kid's phone, then under the hood: ParentLock's salted hash.
export const appLock = {
  duration: 10,
  line: "Risky things need a grown-up's passcode. Safety help never does. The app never saves the passcode itself, only a salted hash of it.",
  render(ctx, t) {
    ground(ctx);
    const slide = smooth(span(t, 3.4, 4.2));
    const p = realPhone(ctx, t, { ...PH, x: 740 - slide * 560, screens: [["passcode", 0], ["rangesUnlocked", 2.4]], taps: [[0.8, 0.25, 0.47], [1.2, 0.5, 0.47], [1.6, 0.75, 0.47], [2, 0.25, 0.56]] });
    callout(ctx, t, 0.6, p.at(0.5, 0.35), [1500, 300], "Ask a Grown-Up", { until: 3.3 });
    if (slide > 0) editor(ctx, {
      x: 2000 - slide * 1240, y: 110, w: 1100, h: 640, file: "ParentLock.swift", size: 27,
      lines: ["func setPasscode(_ code: String) {", "    var salt = Data(count: 16)", "    SecRandomCopyBytes(kSecRandomDefault, 16, ...)", "    storage.write(salt + Self.hash(code, salt: salt))", "}", "", "private static func hash(_ code: String, salt: Data) -> Data {", "    Data(SHA256.hash(data: salt + Data(code.utf8)))", "}"],
      chars: Math.max(0, (t - 4.2) * 70), mark: 7, markAlpha: smooth(span(t, 8, 8.5)),
    });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};


// 8 · Your Path: the plant, the last quiz, Skill Learned, and the move up to Teen.
export const appEarn = {
  duration: 14,
  line: "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...PH, screens: [["pathKid", 0], ["skillLearned", 3.6], ["readyToMoveUp", 6.6], ["movedUpTeen", 10]], taps: [[9.4, 0.5, 0.69]] });
    callout(ctx, t, 0.8, p.at(0.22, 0.2), [380, 240], "A plant that grows with you", { until: 3.4 });
    callout(ctx, t, 1.8, p.at(0.5, 0.33), [1540, 420], "Kid → Teen → Adult", { until: 3.4 });
    callout(ctx, t, 7.2, p.at(0.5, 0.6), [1540, 560], "Ready for Teen: 4 of 4", { until: 9.6 });
    callout(ctx, t, 10.6, p.at(0.5, 0.38), [1540, 380], "Moved up to Teen");
    const up = smooth(span(t, 3.8, 4.4)) - smooth(span(t, 6.4, 7));
    if (up > 0) drawMaya(ctx, { x: 300, y: 1240 - up * 380, scale: 1.05, facing: "three-quarter", expression: "proud", pose: "cheer", t });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};


// 10 · See What Family Sees, real, beside the sealed letter.
export const appSees = {
  duration: 14,
  line: "Her health information stays inside her family. Not even Apple can read it, and since we don't run a server, we never get a copy.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...PH, x: 300, screens: [["familySees", 0]] });
    callout(ctx, t, 1.4, p.at(0.62, 0.22), [1000, 840], "Exactly what family sees");
    const letter = IMG("letter");
    if (letter) { const k = backOut(span(onTwos(t), 3, 3.6)); if (k > 0) cut(ctx, 1300, 560, -0.03, 99, t, (c) => { c.scale(k, k); blob(c, () => c.roundRect(-430, -250, 860, 500, 18), "#ffffff"); c.shadowColor = "transparent"; c.drawImage(letter, -410, -230, 820, 461); }); }
    ["Not us", "Not Apple", "No server"].forEach((s, i) => callout(ctx, t, 6 + i * 1.4, [1100 + i * 200, 330], [1060 + i * 250, 170], s, { color: "#fff7ea" }));
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

