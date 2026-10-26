// Scrapbook: a journal page on kraft paper. Real app screens are printed as polaroids and taped
// down with washi tape, the kit pieces are die-cut stickers, and notes are handwritten (Caveat)
// with doodled arrows. Still stop-motion on twos, so it sits with the Paper look.
import { C } from "../maya.js";
import { W, H, smooth, backOut, span, rr, caption, FONT } from "./common.js";
import { cut, blob, hop, onTwos, hash, pose, P } from "./paper.js";
import { realPhone, IMG } from "./app.js";
import { SRC } from "./source.js";
export const HAND = (size) => `700 ${size}px Caveat, "Bradley Hand", cursive`;

// The spread: kraft cover at the edges, a cream dotted journal page, a stitched spine shadow.
export function scrapPage(ctx, { seed = 1, spine = false } = {}) {
  ctx.fillStyle = "#c8a274"; ctx.fillRect(0, 0, W, H);
  for (let i = 0; i < 900; i++) {
    ctx.fillStyle = hash(seed + i * 3) > 0.5 ? "rgba(255,240,210,.18)" : "rgba(90,60,30,.12)";
    ctx.fillRect(hash(seed + i) * W, hash(seed * 7 + i * 1.7) * H, 1 + hash(i) * 3, 1);
  }
  ctx.save();
  ctx.shadowColor = "rgba(60,40,20,.35)"; ctx.shadowBlur = 24; ctx.shadowOffsetY = 8;
  ctx.fillStyle = "#fbf6ea"; ctx.beginPath(); ctx.roundRect(46, 34, W - 92, H - 68, 10); ctx.fill();
  ctx.restore();
  ctx.fillStyle = "rgba(47,74,59,.13)";
  for (let y = 70; y < H - 50; y += 40) for (let x = 80; x < W - 60; x += 40) ctx.fillRect(x, y, 3, 3);
  if (spine) {
    const g = ctx.createLinearGradient(W / 2 - 60, 0, W / 2 + 60, 0);
    g.addColorStop(0, "rgba(60,40,20,0)"); g.addColorStop(0.5, "rgba(60,40,20,.14)"); g.addColorStop(1, "rgba(60,40,20,0)");
    ctx.fillStyle = g; ctx.fillRect(W / 2 - 60, 34, 120, H - 68);
  }
}

// A washi tape strip with torn ends and stripes. Centered at (x, y).
export function tape(ctx, x, y, w, rot, color, id, k = 1) {
  if (k <= 0) return;
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot); ctx.globalAlpha = 0.86 * Math.min(1, k * 1.5);
  const h = 46, n = 7;
  ctx.beginPath();
  ctx.moveTo(-w / 2, -h / 2);
  for (let i = 1; i <= n; i++) ctx.lineTo(-w / 2 + (i % 2 ? 6 : 0) + (hash(id + i) - 0.5) * 3, -h / 2 + (i * h) / n);
  ctx.lineTo(w / 2, h / 2);
  for (let i = n - 1; i >= 0; i--) ctx.lineTo(w / 2 - (i % 2 ? 6 : 0) + (hash(id * 3 + i) - 0.5) * 3, -h / 2 + (i * h) / n);
  ctx.closePath();
  ctx.fillStyle = color; ctx.fill();
  ctx.clip();
  ctx.fillStyle = "rgba(255,255,255,.35)";
  for (let s = -w; s < w; s += 26) { ctx.beginPath(); ctx.moveTo(s, -h); ctx.lineTo(s + 12, -h); ctx.lineTo(s + 12 + h * 2, h); ctx.lineTo(s + h * 2, h); ctx.fill(); }
  ctx.restore();
}

// Handwriting, with an optional scribbled underline.
export function hand(ctx, s, x, y, { size = 54, color = C.ink, rot = 0, align = "center", under = 0 } = {}) {
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
  ctx.font = HAND(size); ctx.fillStyle = color; ctx.textAlign = align; ctx.textBaseline = "middle";
  ctx.fillText(s, 0, 0);
  if (under > 0) {
    const w = ctx.measureText(s).width, x0 = align === "center" ? -w / 2 : align === "right" ? -w : 0;
    ctx.beginPath();
    for (let i = 0; i <= 20 * under; i++) { const px = x0 + (i / 20) * w, py = size * 0.55 + Math.sin(i * 1.7) * 3; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); }
    ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.strokeStyle = C.berry; ctx.stroke();
  }
  ctx.restore();
}

// A doodled arrow drawn on over [a, a + 0.5]: a wobbly curve with a hooked head.
export function doodleArrow(ctx, t, a, [x0, y0], [x1, y1], { bend = 0.25, color = C.ink, id = 1 } = {}) {
  const k = smooth(span(onTwos(t), a, a + 0.5));
  if (k <= 0) return;
  const mx = (x0 + x1) / 2 - (y1 - y0) * bend, my = (y0 + y1) / 2 + (x1 - x0) * bend;
  const pt = (u) => [(1 - u) ** 2 * x0 + 2 * (1 - u) * u * mx + u * u * x1, (1 - u) ** 2 * y0 + 2 * (1 - u) * u * my + u * u * y1];
  const j = (i) => (hash(id * 31 + i + pose(t)) - 0.5) * 2.5;
  ctx.save(); ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = color;
  ctx.beginPath();
  const n = 24;
  for (let i = 0; i <= n * k; i++) { const [px, py] = pt(i / n); i ? ctx.lineTo(px + j(i), py + j(i + 50)) : ctx.moveTo(px, py); }
  ctx.stroke();
  if (k > 0.98) {
    const [ex, ey] = pt(1), [bx, by] = pt(0.9), ang = Math.atan2(ey - by, ex - bx);
    ctx.beginPath();
    ctx.moveTo(ex + Math.cos(ang + 2.6) * 26, ey + Math.sin(ang + 2.6) * 26); ctx.lineTo(ex, ey); ctx.lineTo(ex + Math.cos(ang - 2.6) * 26, ey + Math.sin(ang - 2.6) * 26);
    ctx.stroke();
  }
  ctx.restore();
}

// Little doodles: a star, a heart, a scribble that crosses something out.
export function doodle(ctx, kind, x, y, s, t, a, color = C.berry) {
  const k = smooth(span(onTwos(t), a, a + 0.35));
  if (k <= 0) return;
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s); ctx.lineWidth = 5 / s; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = color;
  ctx.beginPath();
  if (kind === "star") for (let i = 0; i <= 10 * k; i++) { const r = i % 2 ? 14 : 34, an = -Math.PI / 2 + (i * Math.PI) / 5; i ? ctx.lineTo(Math.cos(an) * r, Math.sin(an) * r) : ctx.moveTo(Math.cos(an) * r, Math.sin(an) * r); }
  if (kind === "heart") { ctx.moveTo(0, 26); ctx.bezierCurveTo(-46, -6, -30, -44, 0, -18); if (k > 0.5) ctx.bezierCurveTo(30, -44, 46, -6, 0, 26); }
  if (kind === "spark") for (let i = 0; i < 3; i++) { const an = -1.2 + i * 0.6; ctx.moveTo(Math.cos(an) * 20, Math.sin(an) * 20); ctx.lineTo(Math.cos(an) * (20 + 26 * k), Math.sin(an) * (20 + 26 * k)); }
  ctx.stroke(); ctx.restore();
}

// Crosses out a box [x, y, w, h] with a zig-zag scribble, drawn on over [a, a + 0.6].
export function scribbleOut(ctx, t, a, x, y, w, h, color = C.berry) {
  const k = span(onTwos(t), a, a + 0.6);
  if (k <= 0) return;
  ctx.save(); ctx.beginPath(); ctx.lineWidth = 6; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = color;
  const n = 9;
  for (let i = 0; i <= n * k; i++) { const px = x + (i / n) * w, py = y + (i % 2 ? h : 0) + (hash(i) - 0.5) * 8; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); }
  ctx.stroke(); ctx.restore();
}

// A polaroid of a real screen. `crop` is [sy, sh] as fractions of the source height (full width).
export function polaroid(ctx, t, { img, crop = [0, 1], x, y, w, ph, rot = 0, id = 1, label, a = 0, tapeColor = C.mint }) {
  const k = backOut(span(onTwos(t), a, a + 0.4));
  if (k <= 0) return;
  // Drops from a little above, larger, like it's being placed by hand.
  const s = 1 + (1 - k) * 0.35, oy = (1 - Math.min(1, k)) * -60;
  const h = ph + 120;
  cut(ctx, x, y + oy, rot, id, t, (c) => {
    c.scale(s, s);
    blob(c, () => c.rect(-w / 2, -h / 2, w, h), "#ffffff");
    c.shadowColor = "transparent";
    const pw = w - 36, px = -pw / 2, py = -h / 2 + 18;
    c.fillStyle = "#e8e3d8"; c.fillRect(px, py, pw, ph);
    if (img) {
      // Cover the frame: full width from `crop[0]` down, or, for a wide photo, the middle of it.
      let sw = img.width, sh = img.width * (ph / pw);
      if (sh > img.height) { sh = img.height; sw = img.height * (pw / ph); }
      const sx = (img.width - sw) / 2, sy = Math.max(0, Math.min(img.height - sh, crop[0] * img.height));
      c.drawImage(img, sx, sy, sw, sh, px, py, pw, ph);
    }
    if (label) { c.font = HAND(46); c.fillStyle = C.ink; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText(label, 0, h / 2 - 52); }
  }, { lift: 1 + (1 - Math.min(1, k)) * 2.5 });
  tape(ctx, x + Math.sin(rot) * (h / 2), y + oy - Math.cos(rot) * (h / 2) + 4, w * 0.45, rot + (hash(id) - 0.5) * 0.3, tapeColor, id, span(t, a + 0.3, a + 0.5));
}

// A kit piece as a die-cut sticker: the piece drawn with a thick white border around its outline.
const STICKERS = {};
function stickerCanvas(name) {
  if (STICKERS[name]) return STICKERS[name];
  const c = document.createElement("canvas"); c.width = c.height = 640;
  const g = c.getContext("2d"); g.translate(320, 320);
  P[name](g);
  const out = document.createElement("canvas"); out.width = out.height = 640;
  const o = out.getContext("2d");
  for (let i = 0; i < 16; i++) { const an = (i / 16) * Math.PI * 2; o.drawImage(c, Math.cos(an) * 12, Math.sin(an) * 12); }
  o.globalCompositeOperation = "source-in"; o.fillStyle = "#ffffff"; o.fillRect(0, 0, 640, 640);
  o.globalCompositeOperation = "source-over"; o.drawImage(c, 0, 0);
  return (STICKERS[name] = out);
}
export function sticker(ctx, t, name, id, x, y, rot, s = 1) {
  cut(ctx, x, y, rot, id, t, (c) => { c.scale(s, s); c.drawImage(stickerCanvas(name), -320, -320); });
}

// A sticky note with handwriting.
export function stickyNote(ctx, t, s, x, y, rot, id, color = "#fff1a8", { w = 340, size = 50 } = {}) {
  cut(ctx, x, y, rot, id, t, (c) => {
    blob(c, () => c.rect(-w / 2, -70, w, 140), color);
    c.shadowColor = "transparent";
    c.fillStyle = "rgba(0,0,0,.06)"; c.fillRect(-w / 2, -70, w, 22);
    c.font = HAND(size); c.fillStyle = C.ink; c.textAlign = "center"; c.textBaseline = "middle"; c.fillText(s, 0, 10);
  });
}

// ---- Shots ------------------------------------------------------------------------------------

// 1 · Mom's every day: her kit, stuck into the scrapbook as stickers, with handwritten notes.
export const scrapKit = {
  duration: 10,
  line: "My mom has type 1 diabetes. I've watched her manage it every day, and I kept thinking about kids who get it young.",
  render(ctx, t) {
    scrapPage(ctx, { seed: 4, spine: true });
    hand(ctx, "Mom, every day", 140, 120, { size: 84, color: C.pine, align: "left", rot: -0.03, under: smooth(span(t, 0.4, 1)) });
    doodle(ctx, "heart", 680, 112, 1, t, 1, C.berry);
    // [piece, lands at, where, rotation, size, note, note position]
    const items = [
      ["notebook", 0.5, [330, 500], -0.08, 1.25, "her log, every meal", [330, 820]],
      ["meter", 1.6, [780, 430], 0.1, 1.6, "112 before breakfast", [800, 680]],
      ["pen", 2.7, [1280, 320], -0.25, 1.35, "in every bag", [1420, 470]],
      ["sensor", 3.8, [1180, 640], 0, 1.7, "on her arm, always", [1200, 820]],
      ["juice", 4.9, [1650, 600], 0.12, 1.45, "for lows", [1660, 840]],
    ];
    items.forEach(([name, a, [x, y], rot, s, note, [nx, ny]], i) => {
      const k = backOut(span(onTwos(t), a, a + 0.35));
      if (k <= 0) return;
      sticker(ctx, t, name, 10 + i, x, y - (1 - Math.min(1, k)) * 50, rot, s * (1 + (1 - k) * 0.4));
      if (t > a + 0.5) hand(ctx, note, nx, ny, { size: 58, rot: (hash(i) - 0.5) * 0.08 });
    });
    tape(ctx, 330, 255, 180, -0.3, "#f2b8a8", 21, span(t, 0.8, 1));
    tape(ctx, 1640, 460, 160, 0.4, C.mint, 22, span(t, 5.3, 5.5));
    doodle(ctx, "star", 1700, 180, 1, t, 6.2, C.amber);
    doodle(ctx, "spark", 1580, 210, 1, t, 6.4, C.amber);
    caption(ctx, this.line, smooth(span(t, 0.3, 0.7)));
  },
};

// 7 · Real-life tools: each one printed as a polaroid and taped in as it's named.
export const scrapTools = {
  duration: 9.5,
  line: "Logging feels like real life: a kitchen scale for carbs, an insulin pen you dial, and a body map for sites.",
  render(ctx, t) {
    scrapPage(ctx, { seed: 7 });
    hand(ctx, "Feels like real life", W / 2, 100, { size: 72, color: C.pine, rot: -0.02, under: smooth(span(t, 0.3, 0.9)) });
    // [still, crop top, label, lands at, x, y, rot, tape, code: [snippet, line, ...]]
    const shots = [
      ["carbsFilled", 0.05, "kitchen scale", 1.4, 300, 410, -0.05, C.mint, [["scale", 4], ["scale", 14]]],
      ["insulinPen", 0.13, "insulin pen", 3.4, 740, 430, 0.04, "#f2b8a8", [["pen", 1], ["penDraw", 0]]],
      ["bodyMap", 0.17, "body map", 5.4, 1180, 410, -0.04, "#f3d58a", [["bodyMap", 1], ["bodyMap", 3]]],
      ["trendsTubes", 0.1, "time in range", 7, 1620, 430, 0.05, C.mint, [["tubes", 0], ["tubes", 3]]],
    ];
    shots.forEach(([name, sy, label, a, x, y, rot, tc, code], i) => {
      polaroid(ctx, t, { img: IMG(name), crop: [sy, 0], x, y, w: 380, ph: 330, rot, id: 40 + i, label, a, tapeColor: tc });
      printout(ctx, t, a + 0.35, x + 10, 770, -rot * 0.6, 60 + i, SRC[code[0][0]].file, code.map(([k, l]) => SRC[k].lines[l].trim()));
    });
    doodle(ctx, "star", 1840, 230, 0.9, t, 8.2, C.amber);
    doodle(ctx, "spark", 980, 210, 1, t, 4.2, C.berry);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// A torn strip of printed code, taped in under a photo; a highlighter swipes its first line.
function printout(ctx, t, a, x, y, rot, id, file, lines) {
  const k = backOut(span(onTwos(t), a, a + 0.3));
  if (k <= 0) return;
  const w = 400, h = 118;
  cut(ctx, x, y - (1 - Math.min(1, k)) * 30, rot, id, t, (c) => {
    c.beginPath(); c.moveTo(-w / 2, -h / 2); c.lineTo(w / 2, -h / 2);
    for (let i = 0; i <= 16; i++) c.lineTo(w / 2 - (i * w) / 16, h / 2 + (i % 2 ? 7 : 0) + (hash(id + i) - 0.5) * 4);
    c.closePath(); c.fillStyle = "#ffffff"; c.fill();
    c.shadowColor = "transparent";
    c.font = '700 17px ui-monospace, "SF Mono", Menlo, monospace'; c.textAlign = "left"; c.textBaseline = "middle";
    c.fillStyle = "#8a9a90"; c.fillText(file, -w / 2 + 16, -h / 2 + 18);
    const hl = smooth(span(t, a + 0.4, a + 0.9));
    lines.forEach((l, i) => {
      let s = l; while (c.measureText(s).width > w - 32 && s.length > 4) s = s.slice(0, -2);
      if (s !== l) s = s.slice(0, -1) + "…";
      const ly = -h / 2 + 50 + i * 30;
      if (i === 0 && hl > 0) { c.fillStyle = "rgba(242,201,76,.65)"; c.fillRect(-w / 2 + 12, ly - 13, (Math.min(w - 24, c.measureText(s).width + 8)) * hl, 26); }
      c.fillStyle = C.ink; c.fillText(s, -w / 2 + 16, ly);
    });
  });
  tape(ctx, x - 150, y - h / 2 + 4, 90, -0.5, "#f3d58a", id + 7, span(t, a + 0.2, a + 0.35));
}

// 9a · Mom's phone, taped into the book: Maya asked for help, Mom answers in one tap; the four
// lunch texts from 2b get scribbled out.
export const scrapFamily = {
  duration: 10,
  line: "When Maya needs help, Mom sees it right away and answers with one tap. Maya doesn't get four texts at lunch anymore.",
  render(ctx, t) {
    scrapPage(ctx, { seed: 11, spine: true });
    hand(ctx, "Mom's phone", 1300, 112, { size: 70, color: C.pine, rot: 0.02 });
    const p = realPhone(ctx, t, { x: 1110, y: 170, h: 760, screens: [["parentHelp", 0], ["parentReplied", 5.2]], taps: [[4.7, 0.3, 0.31]], tag: "sample data" });
    tape(ctx, 1110 + p.w / 2, 170, 200, 0.06, "#f3d58a", 61, 1);
    polaroid(ctx, t, { img: IMG("scene3"), crop: [0.05, 0], x: 520, y: 330, w: 520, ph: 330, rot: -0.05, id: 62, label: "Maya at school", a: 0.3, tapeColor: "#f2b8a8" });
    doodleArrow(ctx, t, 1.4, [790, 270], [1090, 330], { bend: -0.2, id: 3 });
    hand(ctx, "help request", 940, 230, { size: 42, color: C.berry, rot: -0.05 });
    // The four texts from lunch, as sticky notes, crossed out as the line says it.
    const notes = ["What's your number?", "What's your number??", "Number?", "Maya??"];
    notes.forEach((s, i) => {
      const a = 2 + i * 0.25, k = backOut(span(onTwos(t), a, a + 0.3));
      if (k <= 0) return;
      const nx = 250 + (i % 2) * 400, ny = 690 + Math.floor(i / 2) * 150;
      stickyNote(ctx, t, s, nx, ny, (hash(i * 5) - 0.5) * 0.12, 70 + i, i % 2 ? "#fff1a8" : "#ffe0d6", { w: 360, size: 40 });
      scribbleOut(ctx, t, 7 + i * 0.25, nx - 170, ny - 34, 340, 70);
    });
    if (t > 6) stickyNote(ctx, t, "On my way!", 1640, 820, 0.06, 80, C.mint, { w: 300, size: 52 });
    doodle(ctx, "heart", 1800, 740, 0.9, t, 6.3, C.berry);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};

// 12b · The last page: the plant sticker, the plans on sticky notes, then the closing line.
export const scrapEnd = {
  duration: 12,
  line: "Next: the App Store, with family sharing on. Then other languages, school nurses, and clinics that hand it to families the day a kid is diagnosed.",
  render(ctx, t) {
    scrapPage(ctx, { seed: 33, spine: true });
    cut(ctx, 440, 700, 0, 200, t, (c) => {
      blob(c, () => c.roundRect(-9, -330, 18, 290, 9), C.pine);
      blob(c, () => c.ellipse(-70, -150, 74, 30, -0.5, 0, Math.PI * 2), C.leaf);
      blob(c, () => c.ellipse(70, -220, 74, 30, 0.5, 0, Math.PI * 2), C.leaf);
      for (let i = 0; i < 6; i++) blob(c, () => c.ellipse(Math.cos(i) * 34, -340 + Math.sin(i) * 34, 30, 18, i, 0, Math.PI * 2), C.berry);
      blob(c, () => c.arc(0, -340, 20, 0, Math.PI * 2), "#f2c94c");
      blob(c, () => { c.moveTo(-130, -40); c.lineTo(130, -40); c.lineTo(104, 140); c.lineTo(-104, 140); c.closePath(); }, C.amber);
    });
    const out = smooth(span(onTwos(t), 9, 9.5));
    ctx.save(); ctx.globalAlpha = 1 - out;
    hand(ctx, "What's next", 1260, 110, { size: 80, color: C.pine, under: smooth(span(t, 0.3, 0.8)) });
    const notes = [["App Store", "#fff1a8"], ["Family sharing on", C.mint], ["More languages", "#ffe0d6"], ["School nurses", "#fff1a8"], ["Clinics", C.mint]];
    notes.forEach(([s, col], i) => {
      const a = [0.9, 2, 3.2, 4.1, 5][i], k = backOut(span(onTwos(t), a, a + 0.3));
      if (k <= 0) return;
      const x = [1040, 1500, 1040, 1500, 1270][i], y = [270, 300, 480, 510, 700][i] - (1 - Math.min(1, k)) * 40;
      stickyNote(ctx, t, s, x, y, (hash(i + 5) - 0.5) * 0.14, 210 + i, col, { w: 400, size: 52 });
      // A ticked box on each, drawn just after it lands.
      const tk = smooth(span(t, a + 0.4, a + 0.7));
      if (tk > 0) { ctx.save(); ctx.translate(x - 160, y - 40); ctx.beginPath(); ctx.moveTo(-10, 0); ctx.lineTo(-10 + 10 * Math.min(1, tk * 2), 10 * Math.min(1, tk * 2)); if (tk > 0.5) ctx.lineTo(20 * tk, -20 * tk); ctx.lineWidth = 6; ctx.lineCap = "round"; ctx.strokeStyle = C.pine; ctx.stroke(); ctx.restore(); }
    });
    ctx.restore();
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)) * (1 - smooth(span(t, 9, 9.4))));
    // The closing line, taped onto the page.
    const e = backOut(span(onTwos(t), 9.5, 10));
    if (e > 0) {
      cut(ctx, 1230, 540, -0.02, 230, t, (c) => {
        c.scale(e, e);
        blob(c, () => c.rect(-560, -190, 1120, 380), "#ffffff");
        c.shadowColor = "transparent"; c.textAlign = "center"; c.textBaseline = "middle";
        c.font = FONT(900, 62); c.fillStyle = C.ink; c.fillText("Every kid with diabetes grows up.", 0, -50);
        c.fillStyle = C.pine; c.fillText("Now their app can too.", 0, 50);
      }, { lift: 1.4 });
      tape(ctx, 720, 370, 200, -0.5, C.mint, 231, span(t, 9.9, 10.1));
      tape(ctx, 1740, 710, 200, -0.5, "#f2b8a8", 232, span(t, 10, 10.2));
      doodle(ctx, "heart", 1700, 340, 1.1, t, 10.4, C.berry);
      hand(ctx, "DiabetesCare", 1230, 840, { size: 60, color: C.pine, rot: -0.02 });
    }
  },
};

// 13 · Sign-off: the last page of the book is Angad's. Two real photos taped in (drop them at
// assets/personal/me.jpg and mom.jpg; until then a dashed slot says what goes there), the app icon
// as a sticker, and a handwritten note.
function photoSlot(ctx, t, name, label, x, y, rot, id, a) {
  const img = IMG(name);
  if (img) return polaroid(ctx, t, { img, crop: [0.1, 0], x, y, w: 420, ph: 420, rot, id, label, a, tapeColor: id % 2 ? "#f2b8a8" : C.mint });
  const k = backOut(span(onTwos(t), a, a + 0.4));
  if (k <= 0) return;
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot); ctx.scale(k, k);
  ctx.setLineDash([14, 12]); rr(ctx, -210, -270, 420, 540, 10, "rgba(255,255,255,.6)", C.berry, 4); ctx.setLineDash([]);
  ctx.font = HAND(48); ctx.fillStyle = C.berry; ctx.textAlign = "center"; ctx.textBaseline = "middle";
  ctx.fillText(`photo: ${label}`, 0, -20); ctx.font = HAND(34); ctx.fillText(`assets/personal/${name === "photoMe" ? "me" : "mom"}.jpg`, 0, 40);
  ctx.restore();
}

export const scrapSignOff = {
  duration: 8,
  line: "I'm Angad. I built DiabetesCare for my mom, and for every kid who'll grow up with it.",
  render(ctx, t) {
    scrapPage(ctx, { seed: 77, spine: true });
    // One photo (Angad) unless Mom's is there too.
    if (IMG("photoMom")) {
      photoSlot(ctx, t, "photoMe", "me", 400, 440, -0.06, 301, 0.3);
      photoSlot(ctx, t, "photoMom", "Mom", 860, 470, 0.05, 302, 1.6);
      doodle(ctx, "heart", 640, 170, 1.4, t, 2.6, C.berry);
    } else {
      polaroid(ctx, t, { img: IMG("photoMe"), crop: [0.12, 0], x: 600, y: 430, w: 500, ph: 560, rot: -0.04, id: 301, label: "me", a: 0.3, tapeColor: C.mint });
      doodle(ctx, "heart", 930, 150, 1.3, t, 2.6, C.berry);
    }
    const icon = IMG("appIcon");
    const ik = backOut(span(onTwos(t), 3, 3.4));
    if (icon && ik > 0) cut(ctx, 1400, 300, 0.06, 303, t, (c) => {
      c.scale(ik, ik);
      blob(c, () => c.roundRect(-130, -130, 260, 260, 60), "#ffffff");
      c.shadowColor = "transparent"; c.save(); c.beginPath(); c.roundRect(-118, -118, 236, 236, 52); c.clip(); c.drawImage(icon, -118, -118, 236, 236); c.restore();
    });
    if (t > 3.6) hand(ctx, "DiabetesCare", 1400, 480, { size: 58, color: C.pine, rot: -0.02 });
    if (t > 4.4) hand(ctx, "for Mom, and for every kid like Maya", 1430, 580, { size: 46, rot: -0.02 });
    if (t > 5.2) hand(ctx, "Angad", 1560, 680, { size: 76, color: C.berry, rot: -0.04, under: smooth(span(t, 5.4, 6)) });
    doodle(ctx, "star", 1760, 210, 1, t, 5.8, C.amber);
    caption(ctx, this.line, smooth(span(t, 0.2, 0.6)));
  },
};
