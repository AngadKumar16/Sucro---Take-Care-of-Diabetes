// Maya's clips. Each is { duration, line, render(ctx, t) }: frame-deterministic, 1920 × 1080.
// Lines match docs/demo-video.md; the caption is drawn here so drafts read on their own.
import { C, drawMaya, thought } from "../maya.js";
import { chair, table, bed } from "../props.js";
import { W, H, FLOOR, smooth, backOut, span, pushIn, rr, text, caption, cornerCard, room, windowFrame, wallClock, classmate, textBubble } from "./common.js";

// 2a · 6:40 a.m., kitchen table, meter and a paper log.
export const kitchen = {
  duration: 8,
  line: "Meet Maya. She's fourteen. Every day starts with numbers.",
  render(ctx, t) {
    ctx.save();
    pushIn(ctx, t, 9, 0.05, 900, 600);
    room(ctx, "#e7efe4", "#e6cfa6");
    windowFrame(ctx, 170, 170, 400, 330, [[0, "#f7c98a"], [0.6, "#f6dfb4"], [1, "#eef0dc"]]);
    // Sun just over the sill.
    ctx.beginPath(); ctx.arc(300, 470, 46, Math.PI, 0); ctx.fillStyle = "#f2a94e"; ctx.fill();
    wallClock(ctx, 1540, 250, 86, 6 * 60 + 40 + t / 60, t + 12);
    chair(ctx, 760, FLOOR, 1.4);
    table(ctx, 1000, FLOOR, 1.4, 420);
    const top = FLOOR - 162 * 1.4;
    // On the table: the meter, the paper log with handwritten numbers, a mug.
    rr(ctx, 1080, top - 96, 64, 96, 16, C.cream);
    rr(ctx, 1090, top - 84, 44, 30, 6, C.mint, C.ink, 3);
    text(ctx, "112", 1112, top - 69, { size: 22, weight: 900, color: C.pine });
    ctx.save(); ctx.translate(1240, top - 6); ctx.rotate(-0.06);
    rr(ctx, -70, -16, 140, 16, 4, "#ffffff", C.ink, 3);
    ctx.restore();
    rr(ctx, 1150, top - 64, 52, 64, 12, C.amber);
    drawMaya(ctx, { x: 778, y: FLOOR, scale: 1.4, facing: "side", expression: "tired", pose: "slump", t });
    // The log's numbers, written down one by one as the clip runs.
    const nums = ["148", "152", "141", "128", "112"];
    nums.forEach((n, i) => { const a = span(t, 1 + i * 1.2, 1.4 + i * 1.2); if (a > 0) text(ctx, n, 1196 + i * 26, top - 30 - i * 2, { size: 16, weight: 800, color: `rgba(47,74,59,${a})` }); });
    ctx.restore();
    cornerCard(ctx, "Maya is made up. Her days aren't.", smooth(span(t, 0.3, 0.9)));
    caption(ctx, this.line, smooth(span(t, 0.4, 0.8)));
  },
};

// 2b · School lunch: Mom texts "What's your number?" again and again.
export const lunch = {
  duration: 8,
  line: "Her mom checks in all day, because she has no other way to know.",
  render(ctx, t) {
    ctx.save();
    pushIn(ctx, t, 9, 0.04, 760, 560);
    room(ctx, "#dcefe2", "#cfe0d2");
    // Cafeteria wall: a long window strip and a menu board.
    rr(ctx, 120, 150, 980, 200, 22, "#eaf6fb");
    for (let i = 1; i < 5; i++) { ctx.beginPath(); ctx.moveTo(120 + i * 196, 150); ctx.lineTo(120 + i * 196, 350); ctx.lineWidth = 8; ctx.strokeStyle = C.cream; ctx.stroke(); }
    // The bench.
    rr(ctx, 380, FLOOR - 100 * 1.3 - 4, 1300, 30, 14, C.amber);
    for (const lx of [460, 1560]) rr(ctx, lx, FLOOR - 100 * 1.3 + 22, 22, 100 * 1.3 - 22, 8, C.amber);
    // Classmates further down the bench lean in once the phone keeps buzzing.
    const lean = smooth(span(t, 3.2, 4.2)) * 0.12;
    ctx.save(); ctx.translate(1300, FLOOR - 132); ctx.rotate(-lean); classmate(ctx, 0, 0, 1.15, C.mint, "#6b4a32"); ctx.restore();
    ctx.save(); ctx.translate(1520, FLOOR - 132); ctx.rotate(-lean * 0.7); classmate(ctx, 0, 0, 1.1, "#f3d6a8", "#2f2522"); ctx.restore();
    const expression = t < 4.6 ? "embarrassed" : "annoyed";
    const out = drawMaya(ctx, { x: 780, y: FLOOR, scale: 1.3, facing: "three-quarter", expression, pose: "sitPhone", t });
    // Buzz marks beside the phone each time a text lands.
    const hits = [0.8, 2.2, 3.6, 5.0];
    const hand = out.hands[1], hx = 780 + hand[0] * 1.3, hy = FLOOR + hand[1] * 1.3;
    for (const h of hits) {
      const k = span(t, h, h + 0.5);
      if (k > 0 && k < 1) for (const s of [-1, 1]) {
        ctx.beginPath(); ctx.arc(hx + 6, hy - 18, 44 + k * 16, s > 0 ? -0.6 : Math.PI - 0.6, s > 0 ? 0.6 : Math.PI + 0.6);
        ctx.lineWidth = 5; ctx.strokeStyle = `rgba(224,100,74,${1 - k})`; ctx.stroke();
      }
    }
    ctx.restore();
    const msgs = ["What's your number?", "What's your number??", "Maya? Number?", "Maya?? Answer please"];
    hits.forEach((h, i) => { const k = span(t, h, h + 0.45); if (k > 0) textBubble(ctx, 1480, 150 + i * 140, "Mom", msgs[i], 0.2 + 0.8 * backOut(k)); });
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 2c · 2 a.m.: an alarm, the pillow, then she sits up: "I can do this. Just let me."
export const night = {
  duration: 9,
  line: "Most apps treat her like an adult, or like a little kid. Nothing grows up with her.",
  render(ctx, t) {
    ctx.save();
    pushIn(ctx, t, 10, 0.05, 1000, 640);
    room(ctx, "#2b4339", "#22352d");
    windowFrame(ctx, 200, 170, 360, 300, [[0, "#1d2f3f"], [1, "#2f4a5a"]]);
    ctx.beginPath(); ctx.arc(470, 250, 34, 0, Math.PI * 2); ctx.fillStyle = "#f3ecd2"; ctx.fill();
    bed(ctx, 1000, FLOOR, 1.85);
    // Nightstand with the phone that beeps.
    rr(ctx, 1560, FLOOR - 170, 180, 170, 18, "#3d5a4c");
    const beeping = t < 5.2;
    const glow = beeping ? 0.5 + 0.5 * Math.sin(t * 9) : 0.15;
    ctx.save(); ctx.translate(1650, FLOOR - 182); ctx.rotate(-0.08);
    rr(ctx, -42, -14, 84, 22, 8, C.ink, C.ink, 3);
    rr(ctx, -36, -11, 72, 14, 5, `rgba(240,140,110,${0.4 + glow * 0.6})`, null);
    ctx.restore();
    if (beeping) for (let i = 0; i < 3; i++) {
      const k = ((t * 1.3) + i / 3) % 1;
      ctx.beginPath(); ctx.arc(1650, FLOOR - 190, 30 + k * 90, Math.PI * 1.1, Math.PI * 1.9);
      ctx.lineWidth = 5; ctx.strokeStyle = `rgba(240,140,110,${(1 - k) * 0.8})`; ctx.stroke();
    }
    if (t < 5.6) {
      drawMaya(ctx, { x: 1060, y: FLOOR - 150, scale: 1.25, facing: "side", expression: "tired", pose: "pillow", t });
    } else {
      drawMaya(ctx, { x: 820, y: FLOOR, scale: 1.3, facing: "three-quarter", expression: t < 6.6 ? "annoyed" : "neutral", pose: "sit", t });
    }
    // Night light: everything dims except what glows.
    ctx.fillStyle = "rgba(16,30,24,.28)";
    ctx.fillRect(0, 0, W, H);
    ctx.restore();
    const k = span(t, 6.8, 7.3);
    if (k > 0) { ctx.save(); ctx.translate(1100, 300); ctx.scale(backOut(k), backOut(k)); thought(ctx, 0, 0, "I can do this. Just let me.", { tx: -220, ty: 230, size: 50 }); ctx.restore(); }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 3 · Title: the sprout grows and wipes the screen into "DiabetesCare · grows with you".
export const title = {
  duration: 8,
  line: "So we built DiabetesCare. It grows with you.",
  render(ctx, t) {
    ctx.fillStyle = C.sage;
    ctx.fillRect(0, 0, W, H);
    const px = 960, py = 780;
    const stem = 300 * smooth(span(t, 0.4, 3.2));
    const tip = [px, py - 40 - stem];
    const drawSprout = () => {
      ctx.beginPath(); ctx.moveTo(px, py - 40); ctx.quadraticCurveTo(px + 16, py - 40 - stem * 0.5, tip[0], tip[1]);
      ctx.lineWidth = 14; ctx.lineCap = "round"; ctx.strokeStyle = C.pine; ctx.stroke();
      const leaf = (k, side, at) => {
        if (k <= 0) return;
        const y = py - 40 - stem * at, s = backOut(k);
        ctx.save(); ctx.translate(px + 6, y); ctx.scale(side * s, s);
        ctx.beginPath(); ctx.moveTo(0, 0); ctx.bezierCurveTo(30, -70, 110, -70, 130, -40); ctx.bezierCurveTo(100, 0, 40, 10, 0, 0);
        ctx.fillStyle = C.leaf; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = C.pine; ctx.stroke(); ctx.restore();
      };
      leaf(span(t, 1.6, 2.2), -1, 0.45);
      leaf(span(t, 2.2, 2.8), 1, 0.7);
      const bud = backOut(span(t, 3.0, 3.6));
      if (bud > 0) { ctx.beginPath(); ctx.arc(tip[0], tip[1], 26 * bud, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = C.pine; ctx.stroke(); }
    };
    drawSprout();
    // Pot.
    ctx.beginPath(); ctx.moveTo(px - 120, py - 40); ctx.lineTo(px + 120, py - 40); ctx.lineTo(px + 96, py + 120); ctx.lineTo(px - 96, py + 120); ctx.closePath();
    ctx.fillStyle = C.amber; ctx.fill(); ctx.lineWidth = 6; ctx.strokeStyle = C.ink; ctx.stroke();
    rr(ctx, px - 136, py - 66, 272, 40, 16, C.amber, C.ink, 6);
    // The wipe grows out of the bud.
    const r = Math.hypot(W, H) * smooth(span(t, 4.2, 5.4));
    if (r > 0) { ctx.beginPath(); ctx.arc(tip[0], tip[1], r, 0, Math.PI * 2); ctx.fillStyle = C.pine; ctx.fill(); }
    const a = smooth(span(t, 5.0, 5.8));
    if (a > 0) {
      ctx.save(); ctx.globalAlpha = a;
      text(ctx, "DiabetesCare", W / 2, 470 - 20 * (1 - a), { size: 150, weight: 900, color: C.cream });
      text(ctx, "grows with you", W / 2, 600 - 20 * (1 - a), { size: 70, weight: 800, color: C.mint });
      ctx.restore();
    }
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)) * (1 - smooth(span(t, 7.4, 8))));
  },
};

// 7 · Skill earned: Maya cheers, the sprout grows a leaf, leaves fall like confetti.
export const cheer = {
  duration: 3,
  line: "",
  render(ctx, t) {
    ctx.fillStyle = C.sage;
    ctx.fillRect(0, 0, W, H);
    ctx.beginPath(); ctx.ellipse(W / 2, FLOOR + 10, 360, 34, 0, 0, Math.PI * 2); ctx.fillStyle = "#cfe5d3"; ctx.fill();
    drawMaya(ctx, { x: 860, y: FLOOR, scale: 1.55, facing: "three-quarter", expression: "proud", pose: "cheer", t });
    for (let i = 0; i < 26; i++) {
      const seed = Math.sin(i * 91.7) * 0.5 + 0.5, x = 300 + ((i * 137) % 1320), fall = ((t * (140 + seed * 120)) + i * 53) % 1100 - 100;
      ctx.save(); ctx.translate(x + Math.sin(t * 2 + i) * 24, fall); ctx.rotate(t * (1 + seed) + i);
      ctx.beginPath(); ctx.ellipse(0, 0, 18, 8, 0, 0, Math.PI * 2); ctx.fillStyle = i % 3 ? C.leaf : C.mint; ctx.fill();
      ctx.lineWidth = 3; ctx.strokeStyle = C.pine; ctx.stroke(); ctx.restore();
    }
    const k = backOut(span(t, 0.1, 0.6));
    ctx.save(); ctx.translate(1480, 230); ctx.scale(k, k);
    rr(ctx, -230, -60, 460, 120, 60, "#ffffff", C.ink, 4);
    text(ctx, "Skill learned: Treat a Low", 0, 2, { size: 38, weight: 900, color: C.pine });
    ctx.restore();
  },
};

// 11 · Maya at her desk, phone in hand, proud.
export const proud = {
  duration: 3,
  line: "It's free. Family sharing goes live once we have a developer account. Next, we're testing with real families.",
  render(ctx, t) {
    ctx.save();
    pushIn(ctx, t, 3, 0.03, 900, 600);
    room(ctx, "#f1f4e9", "#e6cfa6");
    windowFrame(ctx, 1240, 160, 420, 340, [[0, "#cfe9f3"], [1, "#eef7ee"]]);
    chair(ctx, 760, FLOOR, 1.4);
    table(ctx, 1080, FLOOR, 1.4, 360);
    // A small potted sprout on the desk, in bloom.
    const top = FLOOR - 162 * 1.4;
    rr(ctx, 1170, top - 60, 70, 60, 10, C.amber);
    ctx.beginPath(); ctx.moveTo(1205, top - 60); ctx.lineTo(1205, top - 130); ctx.lineWidth = 8; ctx.strokeStyle = C.pine; ctx.stroke();
    ctx.beginPath(); ctx.arc(1205, top - 136, 14, 0, Math.PI * 2); ctx.fillStyle = C.berry; ctx.fill(); ctx.lineWidth = 5; ctx.stroke();
    drawMaya(ctx, { x: 778, y: FLOOR, scale: 1.4, facing: "three-quarter", expression: "proud", pose: "sitPhone", t });
    ctx.restore();
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
