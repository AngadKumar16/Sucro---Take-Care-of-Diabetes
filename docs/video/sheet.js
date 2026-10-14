// Gate 1: Maya's character sheet. render(ctx) draws a 2400 × 1500 sheet.
import { C, drawMaya, drawHead, EXPRESSIONS, thought } from "./maya.js";
import { chair, table, bed } from "./props.js";

export const SIZE = [2400, 1500];
const F = (w, s) => `${w} ${s}px Nunito, ui-rounded, system-ui, sans-serif`;

function label(ctx, text, x, y, size = 30, color = C.ink, weight = 800, align = "center") {
  ctx.font = F(weight, size);
  ctx.fillStyle = color;
  ctx.textAlign = align;
  ctx.textBaseline = "alphabetic";
  ctx.fillText(text, x, y);
}

function panel(ctx, x, y, w, h, title) {
  ctx.fillStyle = "#ffffff";
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, 36);
  ctx.fill();
  label(ctx, title, x + 36, y + 56, 30, C.pine, 900, "left");
}

function floor(ctx, x0, x1, y) {
  ctx.fillStyle = C.sage;
  ctx.beginPath();
  ctx.ellipse((x0 + x1) / 2, y + 4, (x1 - x0) / 2, 16, 0, 0, Math.PI * 2);
  ctx.fill();
}

export function render(ctx, t = 0) {
  ctx.fillStyle = C.sage;
  ctx.fillRect(0, 0, ...SIZE);
  label(ctx, "Maya", 70, 112, 84, C.pine, 900, "left");
  label(ctx, "Character sheet · DiabetesCare demo video · she's made up, her days aren't", 300, 106, 32, C.ink, 700, "left");

  // Turnaround.
  panel(ctx, 50, 150, 1330, 640, "Turnaround");
  const views = [["front", "Front"], ["three-quarter", "Three-quarter"], ["side", "Side"], ["back", "Back"]];
  views.forEach(([facing, name], i) => {
    const x = 220 + i * 320, y = 700;
    floor(ctx, x - 110, x + 110, y);
    drawMaya(ctx, { x, y, scale: 1.12, facing, expression: "neutral", pose: "stand", t });
    label(ctx, name, x, y + 64, 28);
  });

  // Expressions.
  panel(ctx, 1410, 150, 940, 640, "Five expressions");
  EXPRESSIONS.forEach((e, i) => {
    const col = i % 3, row = Math.floor(i / 3);
    const x = 1570 + col * 300, y = 330 + row * 260;
    ctx.save(); ctx.translate(x, y); ctx.scale(1.5, 1.5); drawHead(ctx, "three-quarter", e); ctx.restore();
    label(ctx, e[0].toUpperCase() + e.slice(1), x + 12, y + 116, 26);
  });

  // Poses with their props.
  panel(ctx, 50, 820, 1700, 630, "Poses");
  const y = 1330;
  floor(ctx, 110, 1690, y);
  drawMaya(ctx, { x: 190, y, scale: 0.9, facing: "three-quarter", expression: "neutral", pose: "stand", t });
  label(ctx, "Stand", 190, y + 60, 26);
  chair(ctx, 420, y, 0.9);
  drawMaya(ctx, { x: 432, y, scale: 0.9, facing: "three-quarter", expression: "neutral", pose: "sit", t });
  label(ctx, "Sit", 430, y + 60, 26);
  chair(ctx, 690, y, 0.9);
  table(ctx, 820, y, 0.9, 200);
  drawMaya(ctx, { x: 702, y, scale: 0.9, facing: "side", expression: "tired", pose: "slump", t });
  label(ctx, "Slump", 740, y + 60, 26);
  drawMaya(ctx, { x: 1010, y, scale: 0.9, facing: "three-quarter", expression: "annoyed", pose: "phone", t });
  label(ctx, "Phone", 1010, y + 60, 26);
  drawMaya(ctx, { x: 1570, y, scale: 0.9, facing: "three-quarter", expression: "proud", pose: "cheer", t });
  label(ctx, "Cheer", 1570, y + 60, 26);
  // Pillow: lying on a bed, so it gets its own little stage.
  bed(ctx, 1290, y - 4, 0.6);
  drawMaya(ctx, { x: 1300, y: y - 62, scale: 0.6, facing: "side", expression: "tired", pose: "pillow", t });
  label(ctx, "Pillow", 1290, y + 60, 26);
  thought(ctx, 1250, 980, "I can do this.", { tx: 1200, ty: 1130, size: 30 });

  // Palette and rules.
  panel(ctx, 1780, 820, 570, 630, "Palette and rules");
  const sw = [["Berry", C.berry], ["Cream", C.cream], ["Leaf", C.leaf], ["Pine", C.pine], ["Skin", C.skin], ["Hair", C.hair], ["Denim", C.denim], ["Ink", C.ink]];
  sw.forEach(([n, c], i) => {
    const x = 1820 + (i % 4) * 130, yy = 910 + Math.floor(i / 4) * 110;
    ctx.fillStyle = c; ctx.beginPath(); ctx.roundRect(x, yy, 96, 56, 16); ctx.fill();
    ctx.lineWidth = 3; ctx.strokeStyle = C.ink; ctx.stroke();
    label(ctx, n, x + 48, yy + 86, 20, C.ink, 800);
  });
  const rules = [
    "Head is 1/4.5 of her height, every shot.",
    "Sensor: back of her left upper arm, always.",
    "Leaf clip on her right side.",
    "Eyes stay round; brows and mouth act.",
    "Fed up, never pitiful. No needles.",
    "Thoughts go in a bubble. No dosing talk.",
  ];
  rules.forEach((r, i) => label(ctx, `${i + 1}. ${r}`, 1820, 1160 + i * 44, 24, C.ink, 700, "left"));
}
