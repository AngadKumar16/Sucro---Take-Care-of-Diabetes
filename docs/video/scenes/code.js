// Code: the app's real Swift, typed onto an editor card. Three shots use it ("under the hood"):
// the passcode (6), the sealed letter (8) and the rules plus tests (10). Lines are copied from the
// app source; keep them in sync if the code changes.
import { C, drawMaya } from "../maya.js";
import { W, H, smooth, backOut, span, rr, text, caption, FONT } from "./common.js";

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
  line: "Risky things need a grown-up's passcode. Safety help never does. The code itself is never saved, only a salted hash.",
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

// 8b · Under the hood of the sealed letter: the payload goes into encryptedValues.
export const codeSeal = {
  duration: 6,
  line: "Before it leaves her phone, it's sealed: end-to-end encrypted, for her family only.",
  render(ctx, t) {
    ctx.fillStyle = "#1a2620"; ctx.fillRect(0, 0, W, H);
    editor(ctx, {
      x: 210, y: 300, w: 1500, h: 470, file: "FamilyRecordCodec.swift", size: 30,
      lines: [
        "let record = CKRecord(recordType: type, recordID: id)",
        "// End-to-end encrypted: only the people the share is with can read it, not Apple.",
        "record.encryptedValues[\"payload\"] = try encoder.encode(payload)",
        "return record",
      ],
      chars: typed(t, 0.6, 55), mark: 2, markAlpha: smooth(span(t, 3.4, 3.9)),
    });
    // The sealed letter flies over the highlighted line once it's typed.
    const k = span(t, 4, 6.2);
    if (k > 0 && k < 1) {
      const e = smooth(k), x = 200 + e * 1520, y = 220 - Math.sin(Math.PI * e) * 120;
      ctx.save(); ctx.translate(x, y); ctx.rotate(-0.08);
      rr(ctx, -80, -52, 160, 104, 14, C.cream, C.ink, 4);
      ctx.beginPath(); ctx.moveTo(-74, -46); ctx.lineTo(0, 6); ctx.lineTo(74, -46); ctx.lineWidth = 4; ctx.strokeStyle = C.ink; ctx.stroke();
      ctx.beginPath(); ctx.arc(0, 8, 24, 0, Math.PI * 2); ctx.fillStyle = C.pine; ctx.fill(); ctx.stroke();
      ctx.restore();
    }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 10 · The rules in one function, then the tests run green.
export const codeGate = {
  duration: 20,
  line: "It's built in SwiftUI. Every rule about who can do what lives in one function, so no screen has a back door. And 207 tests check it.",
  render(ctx, t) {
    ctx.fillStyle = "#1a2620"; ctx.fillRect(0, 0, W, H);
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
    // The marked line walks Kid → Teen → Adult as the narration names the stages.
    const mark = t < 9 ? -1 : t < 11 ? 4 : t < 13 ? 5 : t < 15 ? 2 : 9;
    editor(ctx, { x: 90, y: 80, w: 1360, h: 760, file: "CareStage.swift", size: 26, lines, chars: typed(t, 0.5, 90), mark, markAlpha: 1 });
    // Test panel counts up after the code is typed.
    const k = span(t, 15.5, 19);
    const panel = smooth(span(t, 15, 15.6));
    if (panel > 0) {
      ctx.save(); ctx.globalAlpha = panel;
      rr(ctx, 1490, 160, 360, 520, 30, "#24352d", C.ink, 4);
      text(ctx, "Tests", 1670, 220, { size: 40, weight: 900, color: "#cfe0d6" });
      const unit = Math.round(147 * smooth(k)), ui = Math.round(60 * smooth(span(t, 16.5, 19.5)));
      text(ctx, String(unit), 1670, 330, { size: 96, weight: 900, color: C.mint });
      text(ctx, "unit tests passed", 1670, 400, { size: 26, weight: 800, color: "#9fb2a5" });
      text(ctx, String(ui), 1670, 510, { size: 96, weight: 900, color: C.mint });
      text(ctx, "UI tests passed", 1670, 580, { size: 26, weight: 800, color: "#9fb2a5" });
      ctx.restore();
    }
    // And here it is running: the real app slides in over the tests.
    const run = smooth(span(t, 17, 17.8));
    if (run > 0) {
      const ph = realPhone(ctx, t, { x: 1960 - run * 900, y: 90, h: 820, screens: [["today", 0]] });
      void ph;
      if (run > 0.9) text(ctx, "Running on iPhone", 1250, 960, { size: 34, weight: 900, color: C.mint });
    }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
