// Code: the app's real Swift, typed onto an editor card. Three shots use it ("under the hood"):
// the passcode (6), the sealed letter (8) and the rules plus tests (10). Lines are copied from the
// app source; keep them in sync if the code changes.
import { C, drawMaya } from "../maya.js";
import { W, H, smooth, backOut, span, rr, text, caption, FONT } from "./common.js";
import { SRC } from "./source.js";
import { realPhone } from "./app.js";
import { paperGround } from "./paper.js";

const MONO = (size, weight = 500) => `${weight} ${size}px ui-monospace, "SF Mono", Menlo, monospace`;
const KEYWORDS = /\b(func|let|var|if|else|guard|return|switch|case|static|private|try|throws|for|in|self|true|false|nil)\b/g;
const INK = { base: "#e6eee8", key: "#8fd4ad", type: "#f3cf8a", str: "#f0a58f", num: "#f0a58f", com: "#7f9a8a", dot: "#b9e0f0" };

// Splits a line into coloured runs: comments, strings, keywords, Types, .members, numbers.
function tokens(line) {
  const out = [];
  const com = line.indexOf("//");
  const body = com >= 0 ? line.slice(0, com) : line;
  const re = /("[^"]*")|\b([A-Z][A-Za-z0-9]*)\b|(\.[a-z][A-Za-z0-9]*)|\b(\d+)\b|\b(func|let|var|if|else|guard|return|switch|case|static|private|try|throws|for|in|self|true|false|nil)\b/g;
  let last = 0, m;
  while ((m = re.exec(body))) {
    if (m.index > last) out.push([body.slice(last, m.index), INK.base]);
    out.push([m[0], m[1] ? INK.str : m[2] ? INK.type : m[3] ? INK.dot : m[4] ? INK.num : INK.key]);
    last = m.index + m[0].length;
  }
  if (last < body.length) out.push([body.slice(last), INK.base]);
  if (com >= 0) out.push([line.slice(com), INK.com]);
  return out;
}
void KEYWORDS;

// An editor card with a file tab. `chars` limits how much has been typed; `mark` highlights a line.
export function editor(ctx, { x, y, w, h, file, lines, chars = Infinity, mark = -1, size = 30, markAlpha = 1 }) {
  rr(ctx, x, y, w, h, 26, "#1e2c25", C.ink, 4);
  rr(ctx, x + 22, y + 18, 18, 18, 9, C.berry, null); rr(ctx, x + 50, y + 18, 18, 18, 9, C.amber, null); rr(ctx, x + 78, y + 18, 18, 18, 9, C.leaf, null);
  ctx.font = FONT(800, 24);
  const tw = ctx.measureText(file).width + 40;
  rr(ctx, x + 116, y + 10, tw, 36, 12, "#2b3d34", null);
  text(ctx, file, x + 116 + tw / 2, y + 29, { size: 24, weight: 800, color: "#cfe0d6" });
  const lh = size * 1.55, top = y + 72;
  let left = chars;
  lines.forEach((line, i) => {
    const ly = top + i * lh;
    if (i === mark && markAlpha > 0) { ctx.save(); ctx.globalAlpha = markAlpha; rr(ctx, x + 12, ly - lh / 2 + 2, w - 24, lh - 4, 10, "rgba(95,167,126,.28)", C.leaf, 2); ctx.restore(); }
    ctx.font = MONO(size * 0.8);
    ctx.fillStyle = "#5d7a6b"; ctx.textAlign = "right"; ctx.textBaseline = "middle";
    ctx.fillText(String(i + 1), x + 64, ly);
    ctx.font = MONO(size);
    ctx.textAlign = "left";
    let cx = x + 84;
    for (const [s, color] of tokens(line)) {
      if (left <= 0) break;
      const shown = s.slice(0, Math.max(0, left));
      left -= s.length;
      ctx.fillStyle = color;
      ctx.fillText(shown, cx, ly);
      cx += ctx.measureText(shown).width;
    }
    left -= 1;
    if (left < 0 && left > -2) { ctx.fillStyle = C.leaf; ctx.fillRect(cx + 2, ly - size * 0.55, size * 0.5, size * 1.1); }
  });
}
const typed = (t, a, rate = 60) => Math.max(0, (t - a) * rate);

// A flat phone in the app's style (shared with flat.js).
export function flatPhone(ctx, x, y, w, h, screen) {
  rr(ctx, x, y, w, h, w * 0.16, C.ink, C.ink, 4);
  ctx.save();
  ctx.beginPath(); ctx.roundRect(x + 12, y + 12, w - 24, h - 24, w * 0.13); ctx.clip();
  ctx.fillStyle = C.cream; ctx.fillRect(x, y, w, h);
  ctx.translate(x + 12, y + 12);
  screen(ctx, w - 24, h - 24);
  ctx.restore();
  rr(ctx, x + w / 2 - w * 0.14, y + 26, w * 0.28, 30, 15, C.ink, null);
}

// 6 · The passcode on the phone; then under the hood, the salted hash.
export const codeLock = {
  duration: 8,
  line: "Risky things need a grown-up's passcode. Safety help never does. The app never saves the passcode itself, only a salted hash of it.",
  render(ctx, t) {
    ctx.fillStyle = C.sage; ctx.fillRect(0, 0, W, H);
    const slide = smooth(span(t, 2.2, 3));
    const px = 760 - slide * 520;
    flatPhone(ctx, px, 90, 420, 860, (c, w) => {
      text(c, "Add Insulin", w / 2, 130, { size: 40, weight: 900 });
      text(c, "Ask a grown-up", w / 2, 210, { size: 32, weight: 800, color: C.pine });
      const filled = Math.min(4, Math.floor(span(t, 0.4, 2) * 4.99));
      for (let i = 0; i < 4; i++) { c.beginPath(); c.arc(w / 2 - 90 + i * 60, 290, 15, 0, Math.PI * 2); c.fillStyle = i < filled ? C.ink : "#ffffff"; c.fill(); c.lineWidth = 4; c.strokeStyle = C.ink; c.stroke(); }
      for (let r = 0; r < 4; r++) for (let k = 0; k < 3; k++) if (r < 3 || k === 1) {
        const pressed = Math.floor(span(t, 0.4, 2) * 4.99) === r * 3 + k && t < 2.1;
        rr(c, w / 2 - 170 + k * 120, 360 + r * 110, 100, 90, 30, pressed ? C.mint : C.sage, C.ink, 3);
        text(c, String(r === 3 ? 0 : r * 3 + k + 1), w / 2 - 120 + k * 120, 405 + r * 110, { size: 38, weight: 900 });
      }
    });
    if (slide > 0) {
      const ex = 2000 - slide * 1240;
      editor(ctx, {
        x: ex, y: 120, w: 1100, h: 640, file: "ParentLock.swift", size: 27,
        lines: [
          "func setPasscode(_ code: String) {",
          "    var salt = Data(count: 16)",
          "    SecRandomCopyBytes(kSecRandomDefault, 16, ...)",
          "    storage.write(salt + Self.hash(code, salt: salt))",
          "}",
          "",
          "private static func hash(_ code: String, salt: Data) -> Data {",
          "    Data(SHA256.hash(data: salt + Data(code.utf8)))",
          "}",
        ],
        chars: typed(t, 3, 70), mark: 7, markAlpha: smooth(span(t, 6, 6.5)),
      });
    }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};



// Code beside the app: an editor card that scrolls the real source and highlights the line behind
// what the phone is showing, with a dashed link from that line to the control on screen.
//   tabs: [{ file, start, lines, from, marks: [[at, line, [x, y]?, label?]] }]; `line` is 0-based in `lines`,
//   `start` the file's line number of lines[0]. A tab shows from its `from` until the next one.
export function sideCode(ctx, t, { x, y, w, h, tabs, size = 24, enter = 0, alpha = 1 }) {
  const e = smooth(span(t, enter, enter + 0.5));
  if (e <= 0 || alpha <= 0) return;
  ctx.save();
  ctx.globalAlpha = alpha * e;
  ctx.translate((1 - e) * 140, 0);
  ctx.shadowColor = "rgba(15,30,22,.35)"; ctx.shadowBlur = 30; ctx.shadowOffsetY = 14;
  rr(ctx, x, y, w, h, 24, "#1e2c25", C.ink, 4);
  ctx.shadowColor = "transparent";
  rr(ctx, x + 20, y + 18, 16, 16, 8, C.berry, null); rr(ctx, x + 44, y + 18, 16, 16, 8, C.amber, null); rr(ctx, x + 68, y + 18, 16, 16, 8, C.leaf, null);
  let ti = 0;
  tabs.forEach((tab, i) => { if (t >= (tab.from ?? 0)) ti = i; });
  const sw = ti > 0 ? smooth(span(t, tabs[ti].from, tabs[ti].from + 0.35)) : 1;
  // File tab: the current one, sliding in over the last.
  ctx.font = FONT(800, 20);
  const tab = tabs[ti], tw = ctx.measureText(tab.file).width + 36;
  rr(ctx, x + 102, y + 8, tw, 34, 11, "#2b3d34", null);
  text(ctx, tab.file, x + 102 + tw / 2, y + 26, { size: 20, weight: 800, color: "#cfe0d6" });
  const body = [x + 8, y + 54, w - 16, h - 66];
  const draw = (tb, a) => {
    if (a <= 0) return;
    const lh = size * 1.6, rows = Math.floor(body[3] / lh);
    const marks = tb.marks ?? [];
    let cur = -1, prev = -1, at = 0;
    marks.forEach(([ma, ml], i) => { if (t >= ma) { cur = ml; prev = i ? marks[i - 1][1] : ml; at = ma; } });
    const k = smooth(span(t, at, at + 0.45));
    const m = cur < 0 ? (marks[0]?.[1] ?? 0) : prev + (cur - prev) * k;
    const scroll = Math.max(0, Math.min(tb.lines.length - rows, m - rows * 0.4));
    const shown = smooth(span(t, tb.from ?? enter, (tb.from ?? enter) + 0.7)) * tb.lines.length;
    ctx.save(); ctx.globalAlpha *= a;
    ctx.beginPath(); ctx.rect(...body); ctx.clip();
    const top = body[1] + lh * 0.55 - scroll * lh;
    if (cur >= 0) {
      const by = top + (m - 0.5) * lh;
      rr(ctx, body[0] + 4, by + 2, body[2] - 8, lh - 4, 9, "rgba(95,167,126,.30)", C.leaf, 2);
      rr(ctx, body[0] + 4, by + 2, 6, lh - 4, 3, "#f2c94c", null);
    }
    tb.lines.forEach((line, i) => {
      const ly = top + i * lh;
      if (ly < body[1] - lh || ly > body[1] + body[3] + lh || i > shown) return;
      ctx.font = MONO(size * 0.78); ctx.fillStyle = "#5d7a6b"; ctx.textAlign = "right"; ctx.textBaseline = "middle";
      ctx.fillText(String((tb.start ?? 1) + i), body[0] + 54, ly);
      ctx.font = MONO(size); ctx.textAlign = "left";
      let cx = body[0] + 70;
      for (const [s, color] of tokens(line)) { ctx.fillStyle = color; ctx.fillText(s, cx, ly); cx += ctx.measureText(s).width; }
    });
    ctx.restore();
    // The link from the marked line to the control it runs on the phone, labelled with what it is.
    const mk = marks.filter(([ma]) => t >= ma).pop();
    if (mk && (mk[2] || mk[3]) && a > 0.5) {
      const by = Math.max(body[1] + 16, Math.min(body[1] + body[3] - 16, top + m * lh));
      const lk = smooth(span(t, mk[0] + 0.15, mk[0] + 0.55));
      ctx.save(); ctx.translate(-(1 - e) * 140, 0);
      let sx = x + (1 - e) * 140 - 10;
      if (mk[3]) {
        ctx.font = FONT(900, 30);
        const cw = ctx.measureText(mk[3]).width + 44, ck = backOut(span(t, mk[0] + 0.1, mk[0] + 0.45));
        ctx.save(); ctx.translate(sx - cw / 2, by); ctx.scale(ck, ck);
        rr(ctx, -cw / 2, -30, cw, 60, 30, "#fbf8f1", C.ink, 4);
        text(ctx, mk[3], 0, 2, { size: 30, weight: 900 });
        ctx.restore();
        sx -= cw;
      }
      const [px, py] = mk[2] ?? [sx, by];
      if (mk[2]) {
        ctx.beginPath(); ctx.moveTo(sx, by); ctx.lineTo(sx + (px - sx) * lk, by + (py - by) * lk);
        ctx.setLineDash([3, 10]); ctx.lineCap = "round"; ctx.lineWidth = 4; ctx.strokeStyle = "#f2c94c"; ctx.stroke(); ctx.setLineDash([]);
      }
      if (mk[2] && lk > 0.95) { ctx.beginPath(); ctx.arc(px, py, 12, 0, Math.PI * 2); ctx.fillStyle = "#f2c94c"; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke(); }
      ctx.restore();
    }
  };
  if (ti > 0 && sw < 1) draw(tabs[ti - 1], 1 - sw);
  draw(tab, sw);
  ctx.restore();
}

// 9b · Family sharing, under the hood, between the two real phones: the invite-only iCloud share
// each family gets, Maya's help request published to it, then sealed into encryptedValues; the
// letter flies to Mom's phone.
export const codeSeal = {
  duration: 10.5,
  line: "Family sharing is built on iCloud, with a private share for each family. Before anything leaves her phone, it's sealed: end-to-end encrypted, for her family only.",
  render(ctx, t) {
    paperGround(ctx, C.sage, { seed: 52 });
    realPhone(ctx, t, { x: 50, y: 170, h: 640, screens: [["kidHelp", 0]], tag: "Maya's phone" });
    realPhone(ctx, t, { x: 1576, y: 170, h: 640, screens: [["parentHelp", 0]], tag: "Mom's phone · sample data" });
    sideCode(ctx, t, { x: 400, y: 210, w: 1120, h: 560, size: 24, enter: 0.1, tabs: [
      { ...SRC.familyShare, from: 0.1, marks: [[0.6, 1], [2.2, 8], [3.2, 10]] },
      { ...SRC.sendHelp, from: 4.3, marks: [[4.5, 3], [5.2, 4]] },
      { ...SRC.codec, from: 6.2, marks: [[6.5, 3]] },
    ] });
    // The label over the code says what each part is.
    const steps = [[0.3, "Family sharing · built on iCloud", C.mint, C.ink], [2.2, "A private share for each family", "#fbf8f1", C.ink], [3.2, "Invite only: no public access", "#fbf8f1", C.ink], [4.5, "Her help request, published", "#fbf8f1", C.ink], [6.5, "Sealed: end-to-end encrypted", C.pine, "#ffffff"]];
    const cur = steps.filter(([a]) => t >= a).pop();
    if (cur) {
      const [a, label, bg, fg] = cur, k = backOut(span(t, a, a + 0.35));
      ctx.save(); ctx.translate(960, 130); ctx.scale(k, k); ctx.font = FONT(900, 40);
      const w = ctx.measureText(label).width + 64;
      rr(ctx, -w / 2, -38, w, 76, 38, bg, C.ink, 4); text(ctx, label, 0, 2, { size: 40, weight: 900, color: fg });
      ctx.restore();
    }
    // The sealed letter: leaves Maya's phone, passes over the sealed line, lands on Mom's.
    const f = span(t, 7.4, 9.6);
    if (f > 0 && f < 1) {
      const e = smooth(f), x = 200 + e * 1520, y = 440 - Math.sin(Math.PI * e) * 260;
      ctx.save(); ctx.translate(x, y); ctx.rotate(-0.08 + e * 0.16);
      rr(ctx, -80, -52, 160, 104, 14, C.cream, C.ink, 4);
      ctx.beginPath(); ctx.moveTo(-74, -46); ctx.lineTo(0, 6); ctx.lineTo(74, -46); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke();
      ctx.beginPath(); ctx.arc(0, 8, 24, 0, Math.PI * 2); ctx.fillStyle = C.pine; ctx.fill(); ctx.stroke();
      ctx.restore();
    }
    const land = span(t, 9.6, 10.2);
    if (land > 0 && land < 1) { ctx.beginPath(); ctx.arc(1723, 440, 40 + land * 90, 0, Math.PI * 2); ctx.lineWidth = 6; ctx.strokeStyle = `rgba(31,107,74,${1 - land})`; ctx.stroke(); }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
