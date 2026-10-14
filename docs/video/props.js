// Props for Maya's scenes, in the same outline style. Each draws with its floor contact at (x, y).
import { C } from "./maya.js";

function shape(ctx, fill, build, width = 4) {
  ctx.beginPath();
  build();
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.lineWidth = width;
  ctx.strokeStyle = C.ink;
  ctx.lineJoin = "round";
  ctx.stroke();
}

export function chair(ctx, x, y, s = 1) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  for (const lx of [-40, 34]) shape(ctx, C.amber, () => ctx.roundRect(lx, -96, 8, 96, 4));
  shape(ctx, C.amber, () => ctx.roundRect(-46, -110, 92, 16, 8));
  shape(ctx, C.amber, () => ctx.roundRect(-48, -214, 12, 112, 6));
  shape(ctx, C.amber, () => ctx.roundRect(-52, -222, 20, 54, 8));
  ctx.restore();
}

export function table(ctx, x, y, s = 1, w = 260) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  for (const lx of [-w / 2 + 14, w / 2 - 24]) shape(ctx, C.cream, () => ctx.roundRect(lx, -150, 10, 150, 4));
  shape(ctx, C.cream, () => ctx.roundRect(-w / 2, -162, w, 18, 9));
  ctx.restore();
}

export function bed(ctx, x, y, s = 1) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  shape(ctx, C.mint, () => ctx.roundRect(-250, -70, 500, 60, 22));
  shape(ctx, C.amber, () => ctx.roundRect(-262, -150, 22, 150, 10));
  shape(ctx, C.amber, () => ctx.roundRect(240, -100, 22, 100, 10));
  shape(ctx, C.sage, () => ctx.roundRect(-150, -84, 390, 30, 15));
  ctx.restore();
}
