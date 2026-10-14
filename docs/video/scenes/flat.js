// Flat: the approved sealed-letter illustration style (rounded phones, soft greens), animated.
import { C } from "../maya.js";
import { W, H, smooth, backOut, span, rr, text, caption } from "./common.js";
import { flatPhone } from "./code.js";
import { cheer } from "./maya-scenes.js";

function envelope(ctx, x, y, s = 1, rot = -0.08) {
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot); ctx.scale(s, s);
  rr(ctx, -110, -72, 220, 144, 20, C.cream, C.ink, 6);
  ctx.beginPath(); ctx.moveTo(-100, -62); ctx.lineTo(0, 12); ctx.lineTo(100, -62); ctx.lineWidth = 6; ctx.strokeStyle = C.ink; ctx.lineJoin = "round"; ctx.stroke();
  ctx.beginPath(); ctx.arc(0, 14, 34, 0, Math.PI * 2); ctx.fillStyle = C.pine; ctx.fill(); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(0, 34); ctx.lineTo(0, 0); ctx.moveTo(0, 18); ctx.bezierCurveTo(-14, 14, -18, 2, -16, -4); ctx.bezierCurveTo(-4, -4, 0, 6, 0, 18);
  ctx.moveTo(0, 10); ctx.bezierCurveTo(12, 6, 16, -6, 14, -12); ctx.bezierCurveTo(4, -10, 0, 0, 0, 10);
  ctx.lineWidth = 4; ctx.strokeStyle = "#ffffff"; ctx.stroke();
  ctx.restore();
}

// 9 · Sealed the whole way: Maya's phone → Mom's phone, only Mom's key opens it.
export const sealedLetter = {
  duration: 16,
  line: "Her health information is never shared outside her family. It's end-to-end encrypted, so not even Apple can read it. We don't have a server, so we never get a copy.",
  render(ctx, t) {
    ctx.fillStyle = C.sage; ctx.fillRect(0, 0, W, H);
    const phone = (x, icon, label) => {
      flatPhone(ctx, x, 230, 340, 620, (c, w) => {
        rr(c, 26, 70, w - 52, 420, 30, "#e9f3eb", null);
        icon(c, w / 2, 220);
        rr(c, 60, 380, w - 120, 22, 11, C.mint, null);
        rr(c, 60, 420, (w - 120) * 0.6, 22, 11, C.mint, null);
      });
      text(ctx, label, x + 170, 900, { size: 40, weight: 900 });
    };
    phone(260, (c, x, y) => { c.beginPath(); c.moveTo(x, y - 70); c.bezierCurveTo(x - 60, y, x - 54, y + 60, x, y + 60); c.bezierCurveTo(x + 54, y + 60, x + 60, y, x, y - 70); c.fillStyle = C.berry; c.fill(); c.lineWidth = 5; c.strokeStyle = C.ink; c.stroke(); }, "Maya's phone");
    phone(1320, (c, x, y) => { c.beginPath(); c.moveTo(x, y + 50); c.bezierCurveTo(x - 90, y - 10, x - 50, y - 90, x, y - 40); c.bezierCurveTo(x + 50, y - 90, x + 90, y - 10, x, y + 50); c.fillStyle = C.berry; c.fill(); c.lineWidth = 5; c.strokeStyle = C.ink; c.stroke(); }, "Mom's phone");
    // Dotted path, drawn as the letter travels.
    const k = smooth(span(t, 1, 3.4));
    const path = (u) => [640 + u * 640, 460 - Math.sin(Math.PI * u) * 230];
    ctx.setLineDash([2, 22]); ctx.lineCap = "round"; ctx.lineWidth = 9; ctx.strokeStyle = C.pine;
    ctx.beginPath(); for (let u = 0; u <= k; u += 0.01) { const [x, y] = path(u); u === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y); } ctx.stroke(); ctx.setLineDash([]);
    const [ex, ey] = path(k);
    const arrived = t > 3.4;
    envelope(ctx, ex, ey - 20, arrived ? 1 - smooth(span(t, 3.4, 3.8)) * 0.6 : 1, -0.08 + Math.sin(t * 3) * 0.04);
    // The key on Mom's phone turns once the letter lands.
    const turn = smooth(span(t, 3.8, 4.6));
    ctx.save(); ctx.translate(1640, 820); ctx.rotate(-0.5 + turn * 0.9);
    ctx.beginPath(); ctx.arc(0, 0, 40, 0, Math.PI * 2); ctx.fillStyle = C.amber; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = C.ink; ctx.stroke();
    ctx.beginPath(); ctx.arc(0, 0, 14, 0, Math.PI * 2); ctx.fillStyle = C.cream; ctx.fill();
    ctx.beginPath(); ctx.moveTo(40, 0); ctx.lineTo(130, 0); ctx.moveTo(100, 0); ctx.lineTo(100, 26); ctx.moveTo(122, 0); ctx.lineTo(122, 20); ctx.lineWidth = 12; ctx.lineCap = "round"; ctx.stroke();
    ctx.restore();
    text(ctx, "Only your family. No one else.", W / 2, 120, { size: 76, weight: 900, color: C.pine });
    ["Not us", "Not Apple", "No server"].forEach((s, i) => {
      const p = backOut(span(t, 6 + i * 1.6, 6.5 + i * 1.6));
      if (p <= 0) return;
      ctx.save(); ctx.translate(960, 330 + i * 120); ctx.scale(p, p);
      rr(ctx, -150, -42, 300, 84, 42, "#ffffff", C.ink, 4); text(ctx, s, 0, 2, { size: 40, weight: 900, color: C.berry });
      ctx.restore();
    });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 7 · Earn it: a quiz on the phone, then "skill learned" and Maya cheers.
export const earn = {
  duration: 18,
  line: "Kids earn independence by learning. Each skill unlocks something, and when they're ready, a grown-up approves the move up.",
  render(ctx, t) {
    const split = smooth(span(t, 6, 7));
    if (split > 0) cheer.render(ctx, t - 6); else { ctx.fillStyle = C.sage; ctx.fillRect(0, 0, W, H); }
    const px = 750 - split * 560, s = 1 - split * 0.3;
    ctx.save(); ctx.translate(px + 210, 540); ctx.scale(s, s); ctx.translate(-210, -450);
    flatPhone(ctx, 0, 0, 420, 900, (c, w) => {
      text(c, "Treat a Low", w / 2, 120, { size: 40, weight: 900 });
      text(c, "Question 3 of 3", w / 2, 172, { size: 26, weight: 800, color: "#6f8277" });
      text(c, "Feeling shaky. First?", w / 2, 260, { size: 32, weight: 900 });
      const answers = ["Take a nap", "Have 15 g fast sugar", "Wait and see"];
      const pick = span(t, 2.2, 2.6) > 0;
      answers.forEach((a, i) => {
        const right = i === 1 && pick;
        rr(c, 40, 320 + i * 120, w - 80, 96, 30, right ? C.leaf : "#ffffff", C.ink, 3);
        text(c, a, w / 2, 368 + i * 120, { size: 30, weight: 900, color: right ? "#ffffff" : C.ink });
      });
      const won = backOut(span(t, 3.4, 4));
      if (won > 0) { c.save(); c.translate(w / 2, 760); c.scale(won, won); rr(c, -170, -50, 340, 100, 50, C.pine, null); text(c, "Skill learned", 0, 2, { size: 36, weight: 900, color: "#ffffff" }); c.restore(); }
    });
    ctx.restore();
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
