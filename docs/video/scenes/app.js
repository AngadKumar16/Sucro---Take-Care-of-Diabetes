// App: the real app, front and centre. Real screenshots (docs/screenshots, docs/video/assets) in a
// phone frame, with screens that push in like the app's navigation, tap ripples, and paper callouts
// pointing at real controls. For the final cut, swap a screenshot for a simulator recording of the
// same screen (see docs/demo-video.md › What to record); positions are fractions of the screen.
import { C, drawMaya } from "../maya.js";
import { W, H, smooth, backOut, span, rr, text, caption, FONT } from "./common.js";
import { paperGround, cut, blob, hop, onTwos, hash } from "./paper.js";
import { editor, sideCode } from "./code.js";
import { SRC } from "./source.js";

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
// With code beside it: the phone on the left, the code card on the right, labelled links between.
const SIDE = { x: 130, y: 70, h: 880 };
const CODE = { x: 1000, y: 120, w: 870, h: 720 };
const tab = (name, from, marks) => ({ ...SRC[name], from, marks });









// 4 · Setup: Who's using? → Kid → a grown-up makes the passcode → the kid's Today. Beside it, the
// setup screen's code and CareStage scroll to what's being picked.
export const appSetup = {
  duration: 9,
  line: "First it asks who it's for: a kid, a teen, an adult, or a parent. The whole app changes with the answer.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...SIDE, screens: [["setup", 0], ["setupPasscode", 4.1], ["setupKidToday", 6.3]], taps: [[3.7, 0.5, 0.39]] });
    sideCode(ctx, t, { ...CODE, enter: 0.2, tabs: [
      tab("setup", 0.2, [[0.7, 0, p.at(0.62, 0.39), "Kid"], [1.3, 0, p.at(0.62, 0.53), "Teen"], [1.9, 0, p.at(0.62, 0.66), "Adult"], [2.6, 11, p.at(0.62, 0.82), "Parent"]]),
      tab("careStage", 3.9, [[4.3, 40, p.at(0.5, 0.33), "A grown-up sets a passcode"], [6.6, 24, p.at(0.5, 0.62), "Kid: simple, big buttons"]]),
    ] });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 6 · The grown-up passcode on a kid's phone, with ParentLock beside it: the check, then the
// salted hash that's the only thing saved.
export const appLock = {
  duration: 9.5,
  line: "Risky things need a grown-up's passcode. Safety help never does. The app never saves the passcode itself, only a salted hash of it.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...SIDE, screens: [["passcode", 0], ["rangesUnlocked", 2.3]], taps: [[0.8, 0.25, 0.47], [1.2, 0.5, 0.47], [1.6, 0.75, 0.47], [2, 0.25, 0.56]] });
    sideCode(ctx, t, { ...CODE, enter: 0.2, tabs: [
      tab("parentLock", 0.2, [[0.5, 13, p.at(0.5, 0.35), "Ask a Grown-Up"], [2.4, 17, p.at(0.5, 0.3), "Unlocked"], [4.4, 3, null, "16 random bytes of salt"], [6, 6, null, "Saves only the salted hash"]]),
    ] });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 8 · Your Path: the plant, the last quiz, Skill Learned, the move up to Teen; CareStage and
// SkillPathView beside it.
export const appEarn = {
  duration: 10.5,
  line: "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...SIDE, screens: [["pathKid", 0], ["skillLearned", 2.7], ["readyToMoveUp", 5], ["movedUpTeen", 7.5]], taps: [[7.05, 0.5, 0.69]] });
    const up = smooth(span(t, 2.9, 3.4)) - smooth(span(t, 4.6, 5.1));
    if (up > 0) drawMaya(ctx, { x: 760, y: 1220 - up * 360, scale: 0.9, facing: "three-quarter", expression: "proud", pose: "cheer", t });
    sideCode(ctx, t, { ...CODE, enter: 0.2, tabs: [
      tab("careStage", 0.2, [[0.6, 44, p.at(0.22, 0.2), "A plant that grows"], [2.9, 46, p.at(0.5, 0.33), "Skill learned"]]),
      tab("skillPath", 4.8, [[5.1, 2, p.at(0.5, 0.6), "Ready for Teen: 4 of 4"], [6.7, 23, p.at(0.5, 0.69), "A grown-up approves"], [8, 33, p.at(0.5, 0.38), "Moved up to Teen"]]),
    ] });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 10 · See What Family Sees, real, with the shared record's fields walking by and the line that
// seals it; then the three promises.
export const appSees = {
  duration: 10,
  line: "Her health information stays inside her family. Not even Apple can read it, and since there's no server, I never get a copy.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...SIDE, screens: [["familySees", 0]] });
    sideCode(ctx, t, { ...CODE, y: 190, h: 650, enter: 0.2, tabs: [
      tab("familyModels", 0.2, [[0.7, 1, p.at(0.3, 0.09), "Exactly what family sees"], [1.9, 4, p.at(0.5, 0.3), "Her ranges"], [2.9, 26, p.at(0.25, 0.22), "Help requests"]]),
      tab("codec", 4, [[4.3, 3, null, "Sealed on her phone"]]),
    ] });
    ["Not me", "Not Apple", "No server"].forEach((s2, i) => {
      const a = [4.6, 6.2, 7.2][i], k = backOut(span(onTwos(t), a, a + 0.35));
      if (k <= 0) return;
      cut(ctx, 1150 + i * 290, 110, (hash(i + 2) - 0.5) * 0.1, 500 + i, t, (c) => {
        c.scale(k, k); c.font = FONT(900, 40); const w = c.measureText(s2).width + 60;
        blob(c, () => c.roundRect(-w / 2, -38, w, 76, 38), i === 1 ? C.mint : "#fff7ea");
        c.shadowColor = "transparent"; c.fillStyle = C.ink; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText(s2, 0, 2);
      });
    });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// A soft, blurred wash of a screen behind everything (a tiny copy scaled up), so the frame takes
// the screen's own colours.
const WASH = {};
function wash(ctx, name, alpha = 1) {
  const img = IMG(name);
  if (!img || alpha <= 0) return;
  if (!WASH[name]) { const c = document.createElement("canvas"); c.width = 24; c.height = 52; c.getContext("2d").drawImage(img, 0, 0, 24, 52); WASH[name] = c; }
  ctx.save(); ctx.globalAlpha = alpha; ctx.imageSmoothingQuality = "high";
  ctx.drawImage(WASH[name], -200, -900, W + 400, (W + 400) * 52 / 24);
  ctx.restore();
}

// 5 · Feeling off? The real help flow, with a calm, polished frame: the screen's colours washed
// behind it, a soft glow that beats while it's urgent and turns green once the recheck runs, a
// step tracker, and the code for each step scrolling beside the phone.
export const appHelp = {
  duration: 11,
  line: "A kid gets a simpler screen. Feeling off? Get Help walks them through it, starts a 15-minute recheck, and calls Mom in one tap.",
  render(ctx, t) {
    const screens = [["kidToday", 0], ["kidHelp", 3], ["kidHelpLogged", 5], ["liveActivity", 8.6]];
    ctx.fillStyle = C.sage; ctx.fillRect(0, 0, W, H);
    screens.forEach(([name, at], i) => { const nx = screens[i + 1]; wash(ctx, name, smooth(span(t, at, at + 0.5)) * (nx ? 1 - smooth(span(t, nx[1], nx[1] + 0.5)) : 1)); });
    const g = ctx.createLinearGradient(0, 0, W, 0);
    g.addColorStop(0, "rgba(251,248,241,.55)"); g.addColorStop(1, "rgba(226,238,227,.8)");
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    // The glow: a heartbeat in berry while it's urgent, settling into green.
    const calm = smooth(span(t, 5.2, 6.4));
    const beat = Math.pow(Math.max(0, Math.sin(t * Math.PI * 2 * 1.1)), 6) * (1 - calm);
    const cx = SIDE.x + 203, cy = SIDE.y + 440;
    const glow = ctx.createRadialGradient(cx, cy, 120, cx, cy, 620 + beat * 60);
    glow.addColorStop(0, calm < 0.5 ? `rgba(224,100,74,${0.3 + beat * 0.25})` : `rgba(95,167,126,${0.35 * calm})`); glow.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = glow; ctx.fillRect(0, 0, W, H);
    // A gentle push on each new screen.
    const push = screens.reduce((m, [, at]) => (t >= at && at > 0 ? Math.max(m, Math.exp(-(t - at) * 4)) : m), 0);
    ctx.save(); ctx.translate(cx, cy); ctx.scale(1 + push * 0.025, 1 + push * 0.025); ctx.translate(-cx, -cy);
    const p = realPhone(ctx, t, { ...SIDE, screens, taps: [[2.6, 0.78, 0.6], [4.6, 0.5, 0.5], [7.2, 0.27, 0.31]] });
    ctx.restore();
    // Step tracker.
    const steps = [["1", "Find a grown-up", 3, 4.6], ["2", "15 g fast sugar", 4.4, 5.4], ["3", "Recheck in 15 min", 5.5, Infinity]];
    const trk = smooth(span(t, 2.8, 3.3));
    if (trk > 0) {
      ctx.save(); ctx.globalAlpha = trk; ctx.translate(0, (1 - trk) * -20);
      steps.forEach(([n, label, on, done], i) => {
        const x = 1000 + i * 295, a = smooth(span(t, on, on + 0.3)), d = t >= done;
        rr(ctx, x, 46, 280, 60, 30, d ? C.mint : a > 0.5 ? C.pine : "rgba(251,248,241,.9)", C.ink, 3);
        rr(ctx, x + 10, 56, 40, 40, 20, d ? C.pine : a > 0.5 ? "#ffffff" : C.sage, null);
        text(ctx, d ? "✓" : n, x + 30, 77, { size: 24, weight: 900, color: d ? "#ffffff" : C.pine });
        text(ctx, label, x + 160, 77, { size: 24, weight: 900, color: a > 0.5 && !d ? "#ffffff" : C.ink });
      });
      ctx.restore();
    }
    sideCode(ctx, t, { ...CODE, y: 140, h: 700, enter: 0.3, tabs: [
      tab("kidToday", 0.3, [[0.9, 0, p.at(0.3, 0.52), "A simpler screen"], [1.8, 12, p.at(0.78, 0.6), "Get Help"]]),
      tab("kidSteps", 3, [[3.3, 0, p.at(0.3, 0.24), "Find a grown-up"], [4.3, 8, p.at(0.5, 0.5), "15 g fast sugar"]]),
      tab("lowTreatment", 5.2, [[5.5, 21, p.at(0.5, 0.58), "Recheck in 15 min"]]),
      tab("callButton", 6.6, [[6.8, 1, p.at(0.27, 0.31), "Call Mom: one tap"]]),
      tab("liveActivity", 8.6, [[8.9, 10, p.at(0.62, 0.035), "Still counting"]]),
    ] });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 7b · Built on Apple: CGM readings arrive through Apple Health in the background, and on phones
// with Apple Intelligence an on-device model retells the day; StoryWriter throws its answer away
// unless every number survives.
export const appApple = {
  duration: 11,
  line: "Readings from her CGM come in through Apple Health. And with Apple Intelligence, an on-device model retells her day, and the app throws it out if a single number changes.",
  render(ctx, t) {
    ground(ctx);
    const p = realPhone(ctx, t, { ...SIDE, screens: [["devicesHealth", 0], ["todayStory", 4.2]] });
    sideCode(ctx, t, { ...CODE, y: 170, h: 670, enter: 0.2, tabs: [
      tab("healthImport", 0.2, [[0.6, 3, p.at(0.5, 0.245), "CGM readings via Apple Health"], [2.4, 12, null, "Arrive in the background"]]),
      tab("storyWriter", 4, [[4.3, 10, p.at(0.5, 0.42), "On-device model"], [6, 12, null, "Keep every number"], [8, 19, null, "Checked before it's shown"]]),
    ] });
    // Two badges up top: what it's built on.
    [["Apple Health", 0.4, C.berry], ["Apple Intelligence", 4, C.pine]].forEach(([s2, a, col], i) => {
      const k = backOut(span(t, a, a + 0.35));
      if (k <= 0) return;
      ctx.save(); ctx.translate(1200 + i * 380, 100); ctx.scale(k, k);
      ctx.font = FONT(900, 34); const w = ctx.measureText(s2).width + 70;
      rr(ctx, -w / 2, -34, w, 68, 34, "#fbf8f1", C.ink, 4);
      ctx.beginPath(); ctx.arc(-w / 2 + 30, 0, 11, 0, Math.PI * 2); ctx.fillStyle = col; ctx.fill();
      text(ctx, s2, 14, 2, { size: 34, weight: 900 });
      ctx.restore();
    });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
